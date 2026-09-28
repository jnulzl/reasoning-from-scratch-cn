@echo off
REM =============================================================
REM  《从零构建推理模型》中文版 LaTeX 工程 —— 一键编译（Windows）
REM  需要：TeX Live 2026 + Python(Pygments)
REM  用法：双击本文件，或在命令行执行  build.bat
REM =============================================================
setlocal

REM ---- 按需要修改这两行 ----
set TEXBIN=D:\ProgramData\texlive\2026\bin\windows
set PYGMENTIZE=D:\anaconda3\Scripts

set PATH=%TEXBIN%;%PYGMENTIZE%;%PATH%

REM 清空 PYTHONPATH：在 WorkBuddy 等沙箱里，残留的 PYTHONPATH 会让 minted 的
REM 临时文件清理被删除钩子拦截，导致代码块无法生成
set PYTHONPATH=

REM minted 需要 shell escape；目录与书签需要连跑三遍才完全稳定
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
if errorlevel 1 goto :err
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
if errorlevel 1 goto :err
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
if errorlevel 1 goto :err

echo.
echo 编译完成，输出文件：main.pdf
goto :eof

:err
echo.
echo 编译出错，请查看同目录下的 main.log
pause
