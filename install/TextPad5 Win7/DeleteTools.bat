@echo off

set TOOLS=HKEY_CURRENT_USER\Software\Helios\TextPad 5\Tools



REG DELETE "%TOOLS%" /F
echo TextPad tools deleted.


PAUSE
EXIT