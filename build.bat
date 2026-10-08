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
REM  代码高亮（minted v3 / latexminted）在 Windows 上的路径限制：
REM  latexminted 写入前会校验目标路径，【相对路径一律被拒】，
REM  导致 465 处代码块全部报
REM      Cannot write file "_xxx.index.minted" outside working directory
REM
REM  本工程已在 book/ccs.tex 里把 \minted@cachedir 设成项目根目录的
REM  绝对路径（用 kpsewhich 读 PWD 求值，不依赖任何环境变量），
REM  因此这里【无需设置 TEXMFOUTPUT / TEXMF_OUTPUT_DIRECTORY】。
REM  下面把这两个变量清空，避免外部残留值干扰 latexminted 的判定。
REM =============================================================
set TEXMFOUTPUT=
set TEXMF_OUTPUT_DIRECTORY=

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
