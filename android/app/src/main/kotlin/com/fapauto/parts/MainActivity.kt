package com.fapauto.parts

import android.app.Activity.ScreenCaptureCallback
import android.database.Cursor
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import android.view.WindowManager
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    private val tag = "ScreenshotTracking"
    private val screenshotChannelName = "com.fapauto.parts/screenshot_events"
    private var eventSink: EventChannel.EventSink? = null
    private var screenshotObserver: ContentObserver? = null
    private var lastScreenshotKey: String? = null
    private var lastScreenshotEventAt: Long = 0L
    private var screenCaptureCallback: Any? = null

    override fun onStart() {
        super.onStart()
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        Log.d(tag, "FLAG_SECURE applied — screenshots are blocked.")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            registerApi34ScreenCaptureCallback()
        }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun registerApi34ScreenCaptureCallback() {
        try {
            val cb = object : ScreenCaptureCallback {
                override fun onScreenCaptured() {
                    Log.d(tag, "ScreenCaptureCallback fired (API 34+) — screenshot ATTEMPTED while FLAG_SECURE is ON.")
                    sendScreenshotEvent(
                        mapOf(
                            "source" to "android_api34_attempt",
                            "timestamp" to System.currentTimeMillis()
                        )
                    )
                }
            }
            screenCaptureCallback = cb
            registerScreenCaptureCallback(mainExecutor, cb)
            Log.d(tag, "ScreenCaptureCallback registered (API 34+).")
        } catch (e: SecurityException) {
            Log.w(tag, "ScreenCaptureCallback not supported on this device: ${e.message}. FLAG_SECURE is still active.")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            screenshotChannelName
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(tag, "Flutter EventChannel listening — starting MediaStore observer.")
                startScreenshotObserver()
            }

            override fun onCancel(arguments: Any?) {
                Log.d(tag, "Flutter EventChannel cancelled.")
                stopScreenshotObserver()
                eventSink = null
            }
        })
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            @Suppress("UNCHECKED_CAST")
            (screenCaptureCallback as? ScreenCaptureCallback)?.let {
                unregisterScreenCaptureCallback(it)
            }
            screenCaptureCallback = null
        }
        stopScreenshotObserver()
        super.onDestroy()
    }

    private fun startScreenshotObserver() {
        if (screenshotObserver != null) return

        screenshotObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                super.onChange(selfChange)
                Log.d(tag, "MediaStore onChange — checking for screenshot.")
                handleMediaStoreChange(null)
            }

            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                Log.d(tag, "MediaStore onChange(uri=$uri) — checking for screenshot.")
                handleMediaStoreChange(uri)
            }
        }

        contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            screenshotObserver!!
        )
        Log.d(tag, "ContentObserver registered on MediaStore.")
    }

    private fun stopScreenshotObserver() {
        screenshotObserver?.let { contentResolver.unregisterContentObserver(it) }
        screenshotObserver = null
        Log.d(tag, "ContentObserver unregistered.")
    }

    private fun handleMediaStoreChange(uri: Uri?) {
        val event = findRecentScreenshot(uri)
        if (event == null) {
            Log.d(tag, "MediaStore change — no recent screenshot found, skipped.")
            return
        }
        Log.d(tag, "Screenshot found in MediaStore: $event")
        sendScreenshotEvent(event)
    }

    private fun sendScreenshotEvent(event: Map<String, Any?>) {
        Log.d(tag, "Sending event to Flutter: $event")
        eventSink?.success(event)
            ?: Log.w(tag, "eventSink is null — Flutter is not listening yet.")
    }

    private fun findRecentScreenshot(uri: Uri?): Map<String, Any?>? {
        val projection = buildProjection()
        val queryUri = uri ?: MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

        return try {
            contentResolver.query(queryUri, projection, null, null, sortOrder)?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    Log.d(tag, "MediaStore query returned no rows.")
                    return null
                }

                val displayName = cursor.getStringOrNull(MediaStore.Images.Media.DISPLAY_NAME)
                val absolutePath = cursor.getStringOrNull(MediaStore.Images.Media.DATA)
                val relativePath = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    cursor.getStringOrNull(MediaStore.Images.Media.RELATIVE_PATH)
                } else null
                val dateTaken = cursor.getLongOrNull(MediaStore.Images.Media.DATE_TAKEN) ?: 0L
                val dateAddedSeconds = cursor.getLongOrNull(MediaStore.Images.Media.DATE_ADDED) ?: 0L
                val timestamp = if (dateTaken > 0L) dateTaken else dateAddedSeconds * 1000L

                Log.d(tag, "Latest image — name=$displayName, relativePath=$relativePath, timestamp=$timestamp")

                if (!isScreenshot(displayName, absolutePath, relativePath)) {
                    Log.d(tag, "Not a screenshot — skipped.")
                    return null
                }
                if (!isRecent(timestamp)) {
                    Log.d(tag, "Image not recent (timestamp=$timestamp) — skipped.")
                    return null
                }

                val key = absolutePath ?: relativePath ?: displayName ?: timestamp.toString()
                val now = System.currentTimeMillis()
                if (key == lastScreenshotKey && now - lastScreenshotEventAt < 2000L) {
                    Log.d(tag, "Duplicate event skipped (key=$key).")
                    return null
                }

                lastScreenshotKey = key
                lastScreenshotEventAt = now

                mapOf(
                    "source" to "android_media_store",
                    "displayName" to displayName,
                    "path" to absolutePath,
                    "relativePath" to relativePath,
                    "timestamp" to timestamp
                )
            }
        } catch (e: SecurityException) {
            Log.e(tag, "SecurityException querying MediaStore: ${e.message}")
            null
        } catch (e: Exception) {
            Log.e(tag, "Exception querying MediaStore: ${e.message}")
            null
        }
    }

    private fun buildProjection(): Array<String> {
        val columns = mutableListOf(
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.DATE_TAKEN,
            MediaStore.Images.Media.DATE_ADDED
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            columns.add(MediaStore.Images.Media.RELATIVE_PATH)
        }
        return columns.toTypedArray()
    }

    private fun isScreenshot(vararg values: String?): Boolean {
        return values.any { value ->
            val v = value?.lowercase() ?: return@any false
            v.contains("screenshot") || v.contains("screenshots")
        }
    }

    private fun isRecent(timestamp: Long): Boolean {
        if (timestamp <= 0L) return true
        return abs(System.currentTimeMillis() - timestamp) <= 10_000L
    }

    private fun Cursor.getStringOrNull(columnName: String): String? {
        val index = getColumnIndex(columnName)
        return if (index >= 0 && !isNull(index)) getString(index) else null
    }

    private fun Cursor.getLongOrNull(columnName: String): Long? {
        val index = getColumnIndex(columnName)
        return if (index >= 0 && !isNull(index)) getLong(index) else null
    }
}
