@echo off

copy "C:\Documents and Settings\%USERNAME%\Application Data\Helios\TextPad\5.0\CUSTOM.BND" CUSTOM.BND
copy "C:\Documents and Settings\%USERNAME%\Application Data\Helios\TextPad\5.0\config.xml" config.xml
echo "TextPad bindings saved"


set PREFS=HKEY_CURRENT_USER\Software\Helios\TextPad 5\Preferences
set SAVE=C:\49er\install\TextPad5\fortyninerPrefsTextPad5.reg

REG EXPORT "%PREFS%" "%SAVE%"
echo PREFS saved up to "%SAVE%"


set TOOLS=HKEY_CURRENT_USER\Software\Helios\TextPad 5\Tools
set SAVE="C:\49er\install\TextPad5\fortyninerToolsTextPad5.reg"


REG EXPORT "%TOOLS%" "%SAVE%"
echo Tools saved up to "%SAVE%"

PAUSE
EXIT
