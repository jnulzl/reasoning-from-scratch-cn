# 《从零构建推理模型》(Build A Reasoning Model (From Scratch)) —— LaTeX 工程(AI翻译)

## 目录结构

```
latex_source_v2/
├── main.tex                 根文件（对应模板的 book.tex）
├── build.bat                一键编译脚本
├── book/
│   ├── ccs.tex              导言区：字体、版式、全部自定义命令与环境  ← 改版式改这里
│   ├── index.tex            封面、目录、全书章节索引  ← 调章节顺序改这里
│   └── content/
│       ├── front/           扉页、版权、献词、前言、致谢、关于本书…
│       ├── main/            01–08 正文八章
│       ├── appendix/        01–07 附录 A–G
│       └── back/            索引
└── images/                  全书插图（180 张）
```

## 编译

需要 **TeX Live 2026**（自带 `latexminted` 0.7+）与 **Python 3**（`latexminted` 是一个被
`xelatex` 调起的 Python 脚本，代码块用它与 Pygments 做语法高亮）：

```bat
build.bat                          REM Windows 双击即可
```

> 如果环境配置遇到问题或者编译失败可以直接到[releases](https://github.com/jnulzl/reasoning-from-scratch-cn/releases)下载最新的pdf文件

或手工执行（**必须加 `-shell-escape`**；目录与书签需连跑三遍才完全稳定）。
**注意 `TEXMF_OUTPUT_DIRECTORY` 必须设成项目根的绝对路径**，否则代码块会全部高亮失败

```bat
set TEXBIN=D:\ProgramData\texlive\2026\bin\windows
set PYTHON=D:\anaconda3
set PATH=%PYTHON%;%TEXBIN%;%PATH%
set PYTHONPATH=
set SELFAUTOLOC=%TEXBIN%

REM 【关键】必须设成【项目根的绝对路径】（这里按你的实际路径改）
set TEXMF_OUTPUT_DIRECTORY=$ABS_ROOT_PATH\reasoning-from-scratch-cn
set TEXMFOUTPUT=%TEXMF_OUTPUT_DIRECTORY%

xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
```

> 用 `build.bat` 时这些都不用手动设——脚本里用 `%~dp0` 自动填好了。

> ⚠ **`build.bat` 是纯 ASCII 文件，请勿在其中加入中文注释。**
> 批处理由 `cmd.exe` 逐行解析，而 cmd 按「当前代码页」（简体中文 Windows 默认
> GBK/936）读取文件。若文件是 UTF-8，中文注释会变成乱码，且乱码行会被当作
> 命令执行，报出一堆
> `'锛歍eX' 不是内部或外部命令，也不是可运行的程序或批处理文件`。
> 所以该脚本的注释一律用英文，中文说明放在本 README 里。


## 官方代码

[reasoning-from-scratch](https://github.com/rasbt/reasoning-from-scratch)