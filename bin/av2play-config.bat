@echo off
rem av2play-config.bat - configure av2play boot defaults (thin wrapper; all
rem options and the interactive menu live in av2play-config.ps1 - run with
rem no arguments to configure AVFPLAY / AV2PLAY.XEX found next to it).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0av2play-config.ps1" %*
