@echo off
REM =============================================================
REM  《从零构建推理模型》中文版 LaTeX 工程 —— 一键编译（Windows）
REM  需要：TeX Live 2026（自带 latexminted 0.7+）+ Python 3
REM  用法：双击本文件，或在命令行执行  build.bat
REM =============================================================
setlocal EnableExtensions

REM ---- 按需要修改这两行 ----
REM  TEXBIN ：TeX Live 的 bin 目录（含 xelatex.exe）
REM  PYTHON ：Python 3 所在目录（含 python.exe）。必须放在 PATH 上：
REM            minted v3 的高亮程序 latexminted 是 TeX Live 里的一个
REM            Python 脚本，由 latexminted.exe 包装器用 python.exe 启动；
REM            找不到 python.exe 会报
REM              program not found (not part of TeX Live): python.exe
REM            注意是 Python 的【安装根目录】，不是 Scripts 子目录。
set TEXBIN=D:\ProgramData\texlive\2026\bin\windows
set PYTHON=D:\anaconda3

REM Python 放在 TeX bin 之前，避免命中 Python 里另装的 latexminted 副本；
REM 两个位置都保留，谁先谁后不影响 xelatex 本身。
set PATH=%PYTHON%;%TEXBIN%;%PATH%

REM 清空 PYTHONPATH：残留值会让 latexminted 加载到错误的 Python 模块，
REM 导致代码块静默退化
set PYTHONPATH=

REM =============================================================
REM  【关键】代码高亮（minted v3 / latexminted）的缓存目录
REM
REM  latexminted 写入前会校验目标路径，【相对路径一律被拒】，
REM  而 minted 默认 cachedir="_minted" 正是相对路径，
REM  结果 465 处代码块全部报
REM      Cannot write file "_xxx.index.minted" outside working directory
REM
REM  book/ccs.tex 会把 \minted@cachedir 改写成「项目根目录的绝对路径」，
REM  其值取自下面这两个环境变量（优先 TEXMF_OUTPUT_DIRECTORY）。
REM  所以这里【必须把它们设成项目根的绝对路径】——%~dp0 就是本脚本所在
REM  目录（末尾自带反斜杠），即工程根。
REM  注意：不要依赖 PWD —— 那是 bash 专有变量，cmd 下不存在；
REM        也不要留空 —— 空值会让 cachedir 变成空串，照样全灭。
REM =============================================================
REM  ~dp0 末尾自带反斜杠；用 for 的 %%~f 取"去尾斜杠的绝对路径"，
REM  既干净又避开 `if "x:~-1%"=="\"` 这个经典的引号解析坑。
REM  两个变量都强制设成工程根，不要沿用外部可能存在的旧值。
for %%A in ("%~dp0.") do set "TEXMF_OUTPUT_DIRECTORY=%%~fA"
set "TEXMFOUTPUT=%TEXMF_OUTPUT_DIRECTORY%"
echo [build] project root = %TEXMF_OUTPUT_DIRECTORY%

REM minted 需要 shell escape；目录与书签需要连跑三遍才完全稳定
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
if errorlevel 1 goto :err
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
if errorlevel 1 goto :err
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
if errorlevel 1 goto :err

REM 代码块高亮失败【不会】让 xelatex 返回非零退出码，所以单独扫一遍日志
findstr /C:"Cannot write file" /C:"Cannot highlight code" main.log >nul 2>&1
if not errorlevel 1 (
  echo.
  echo [警告] main.log 中仍有 minted 高亮失败信息，请检查：
  echo        - python.exe 是否在 PATH 上
  echo        - book/ccs.tex 里 \minted@cachedir 是否正确求值为绝对路径
  goto :err
)

echo.
echo 编译完成，输出文件：main.pdf
goto :eof

:err
echo.
echo 编译出错，请查看同目录下的 main.log
pause
