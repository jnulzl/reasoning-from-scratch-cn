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

需要 **TeX Live 2026**（`xelatex`）与 **Pygments**（`pip install Pygments`，代码块用 minted 做语法高亮）：

```bat
build.bat                          REM Windows 双击即可
```

或手工执行（**必须加 `-shell-escape`，且连跑两遍**才生成目录与书签）：

```bash
set PATH=D:\ProgramData\texlive\2026\bin\windows;D:\anaconda3\Scripts;%PATH%
xelatex -shell-escape -interaction=nonstopmode main.tex
xelatex -shell-escape -interaction=nonstopmode main.tex
```

## 官方代码

[reasoning-from-scratch](https://github.com/rasbt/reasoning-from-scratch)