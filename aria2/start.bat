@echo off

tasklist | findstr /i aria2c.exe
if errorlevel 1 (
    aria2c --conf-path path\to\config\file --input-file path\to\session\file --all-proxy="http://127.0.0.1:7890"
)
else (
    
)

