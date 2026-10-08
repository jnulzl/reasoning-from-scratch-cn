@echo off
REM =============================================================
REM  Build A Reasoning Model (From Scratch) - Chinese edition
REM  One-click build script (Windows)
REM
REM  Requires: TeX Live 2026 (bundles latexminted 0.7+) + Python 3
REM  Usage    : double-click this file, or run  build.bat
REM
REM  NOTE: this file is deliberately ASCII-only. Chinese comments in a
REM  .bat file break under cmd.exe unless the file encoding matches the
REM  active code page (GBK/936 on zh-CN Windows) -- the mojibake lines
REM  then get executed as bogus commands. Keeping it ASCII means it runs
REM  correctly under any code page. Chinese docs live in README.md.
REM =============================================================
setlocal EnableExtensions

REM ---- Edit these two paths if your install location differs ----
REM  TEXBIN : TeX Live bin directory (contains xelatex.exe)
REM  PYTHON : Python 3 install root (contains python.exe).
REM           Must be on PATH: latexminted (the minted v3 highlighter) is
REM           a Python script invoked by the latexminted.exe wrapper, so a
REM           valid python.exe must be findable. Put the Python ROOT dir on
REM           PATH, NOT the Scripts subdirectory.
REM           Python must come BEFORE the TeX bin dir, otherwise an
REM           independently installed latexminted copy (e.g. in
REM           Python\Scripts) would shadow TeX Live's own.
set TEXBIN=D:\ProgramData\texlive\2026\bin\windows
set PYTHON=D:\anaconda3

set "PATH=%PYTHON%;%TEXBIN%;%PATH%"

REM Clear PYTHONPATH: a leftover value makes latexminted load the wrong
REM Python modules, silently degrading code highlighting.
set "PYTHONPATH="

REM =============================================================
REM  [CRITICAL] minted v3 cache directory
REM
REM  latexminted validates every write target and REJECTS RELATIVE PATHS
REM  outright (see latexrestricted/_restricted_pathlib.py, writable_dir()).
REM  minted's default cachedir is the relative "_minted", so all 465 code
REM  blocks fail with:
REM      Cannot write file "_xxx.index.minted" outside working directory
REM
REM  book/ccs.tex rewrites \minted@cachedir to the ABSOLUTE project root,
REM  reading its value from the two env vars below (TEXMF_OUTPUT_DIRECTORY
REM  takes priority). So they MUST be set here to the absolute project root.
REM
REM  Do NOT rely on PWD -- it is a bash-only variable, absent under cmd.exe,
REM  where kpsewhich would return an empty string and everything breaks.
REM  Do NOT leave them empty either -- an empty cachedir breaks just as hard.
REM
REM  %%~fA gives the fully-qualified path WITHOUT a trailing backslash, and
REM  avoids the classic `if "x:~-1%"=="\"` quote-parsing pitfall.
REM =============================================================
for %%A in ("%~dp0.") do set "TEXMF_OUTPUT_DIRECTORY=%%~fA"
set "TEXMFOUTPUT=%TEXMF_OUTPUT_DIRECTORY%"
echo [build] project root = %TEXMF_OUTPUT_DIRECTORY%

REM minted needs shell escape; TOC/bookmarks need three passes to settle.
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
if errorlevel 1 goto :err
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
if errorlevel 1 goto :err
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
if errorlevel 1 goto :err

REM Highlighting failures do NOT make xelatex return a non-zero exit code,
REM so scan the log explicitly instead of trusting the exit code alone.
findstr /C:"Cannot write file" /C:"Cannot highlight code" main.log >nul 2>&1
if not errorlevel 1 (
  echo.
  echo [WARN] minted highlight failures still present in main.log. Check:
  echo        - is python.exe on PATH?
  echo        - does book/ccs.tex resolve \minted@cachedir to an absolute path?
  goto :err
)

echo.
echo Build finished. Output: main.pdf
goto :eof

:err
echo.
echo Build FAILED. See main.log in this directory.
pause
