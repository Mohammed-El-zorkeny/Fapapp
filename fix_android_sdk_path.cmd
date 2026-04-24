@echo off
chcp 65001 >nul
echo ===================================================
echo     Fixing Android SDK Environment Variables...
echo     جاري إعداد متغيرات البيئة الخاصة بـ Android SDK
echo ===================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "$sdkPath = 'C:\Users\Asus\AppData\Local\Android\sdk'; Write-Host 'Setting ANDROID_HOME to' $sdkPath; [Environment]::SetEnvironmentVariable('ANDROID_HOME', $sdkPath, 'User'); $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($currentPath -eq $null) { $currentPath = '' }; $pathsToAdd = @($sdkPath + '\platform-tools', $sdkPath + '\emulator', $sdkPath + '\cmdline-tools\latest\bin'); $modified = $false; foreach ($p in $pathsToAdd) { if ($currentPath -notmatch [regex]::Escape($p)) { $currentPath = $currentPath.TrimEnd(';') + ';' + $p; Write-Host 'Adding to PATH:' $p; $modified = $true; } else { Write-Host 'Already in PATH:' $p; } }; if ($modified) { [Environment]::SetEnvironmentVariable('Path', $currentPath, 'User'); Write-Host 'PATH updated successfully.'; } else { Write-Host 'PATH is already up to date.'; }"

echo.
echo ===================================================
echo تمت العملية بنجاح!
echo يرجى إغلاق وإعادة فتح (VS Code / Android Studio)
echo أو الطرفية (Terminal) لتطبيق التغييرات.
echo ===================================================
pause
