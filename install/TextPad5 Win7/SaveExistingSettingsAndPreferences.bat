@echo off

copy "C:\Users\%USERNAME%\AppData\Roaming\Helios\TextPad\5.0\CUSTOM.BND" "%CD%\..\..\temp\CUSTOM.BND"
copy "C:\Users\%USERNAME%\AppData\Roaming\Helios\TextPad\5.0\config.xml" "%CD%\..\..\temp\config.xml"
echo "TextPad bindings saved"


set PREFS=HKEY_CURRENT_USER\Software\Helios\TextPad 5\Preferences
set SAVE= %CD%\..\..\temp\fortyninerPrefsTextPad5.reg

REG EXPORT "%PREFS%" "%SAVE%"
echo PREFS saved up to "%SAVE%"


set TOOLS=HKEY_CURRENT_USER\Software\Helios\TextPad 5\Tools
set SAVE=%CD%\..\..\temp\fortyninerToolsTextPad5.reg


REG EXPORT "%TOOLS%" "%SAVE%"
echo Tools saved up to "%SAVE%"

PAUSE
EXIT
