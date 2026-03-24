package com.fapauto.app

import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager.LayoutParams

class MainActivity: FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        window.addFlags(LayoutParams.FLAG_SECURE)
    }
}
