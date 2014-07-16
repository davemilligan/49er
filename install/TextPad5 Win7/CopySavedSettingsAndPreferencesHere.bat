@echo off

copy "%CD%\..\..\temp\CUSTOM.BND" "%CD%\..\..\install\TextPad5 Win7\CUSTOM.BND"
copy "%CD%\..\..\temp\config.xml" "%CD%\..\..\install\TextPad5 Win7\config.xml"
copy "%CD%\..\..\temp\fortyninerPrefsTextPad5.reg" "%CD%\..\..\install\TextPad5 Win7\fortyninerPrefsTextPad5.reg"
copy "%CD%\..\..\temp\fortyninerToolsTextPad5.reg" "%CD%\..\..\install\TextPad5 Win7\fortyninerToolsTextPad5.reg"
echo "TextPad bindings copied to current directory"

PAUSE
EXIT
