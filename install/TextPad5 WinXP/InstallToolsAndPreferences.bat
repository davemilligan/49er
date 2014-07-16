@echo off

set TOOLS=HKEY_CURRENT_USER\Software\Helios\TextPad 5\Tools
set PREFERENCES=HKEY_CURRENT_USER\Software\Helios\TextPad 5\Preferences
set FORTYNINERTOOLS=fortyninerToolsTextPad5.reg
set FORTYNINERPREFS=fortyninerPrefsTextPad5.reg

echo 
set /p RUBY=[Enter Path to Ruby (maybe C:\ruby\bin)]...
REG ADD HKEY_CURRENT_USER\ENVIRONMENT /v PATH /t REG_SZ /d %RUBY% /f
echo Ruby Added to %USERNAME%'s path variable.

REG DELETE "%TOOLS%" /F
echo TextPad tools deleted.

REG DELETE "%PREFERENCES%" /F
echo TextPad preferences deleted.

REG IMPORT "%FORTYNINERTOOLS%"
echo 49er tools imported to TextPad.

REG IMPORT "%FORTYNINERPREFS%"
echo 49er preferences imported to TextPad.

copy CUSTOM.BND "C:\Documents and Settings\%USERNAME%\Application Data\Helios\TextPad\5.0"
copy config.xml "C:\Documents and Settings\%USERNAME%\Application Data\Helios\TextPad\5.0"
echo 49er custom keybindings imported to TextPad.
echo Deep Joy :-)
echo Now configure fortyninercfg.rb entries to get the 49er(c) up and running.

PAUSE
EXIT
