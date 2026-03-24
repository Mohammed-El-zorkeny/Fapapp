@echo off
echo ====================================
echo Clearing Flutter Pub Cache
echo ====================================
echo.

echo Step 1: Removing Syncfusion from cache...
rmdir /s /q "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\syncfusion_flutter_pdfviewer-24.2.9" 2>nul
rmdir /s /q "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\syncfusion_flutter_pdf-24.2.9" 2>nul
rmdir /s /q "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\syncfusion_flutter_core-24.2.9" 2>nul
rmdir /s /q "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\syncfusion_pdfviewer_macos-24.2.9" 2>nul
rmdir /s /q "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\syncfusion_pdfviewer_platform_interface-24.2.9" 2>nul
echo Done!
echo.

echo Step 2: Cleaning Flutter project...
flutter clean
echo.

echo Step 3: Getting dependencies (this will download v32.2.4)...
flutter pub get
echo.

echo Step 4: Running the app...
flutter run
