@echo off
chcp 65001 > nul
set PYTHONUTF8=1
set PYTHONIOENCODING=utf-8
cd /d "%~dp0"
echo Starting Hamsa Backend on port 8080...
python -m uvicorn main:app --host 0.0.0.0 --port 8080
pause
