# 项目长期记忆 —— 《从零构建推理模型》中文版 LaTeX 工程

## 版式基准（已按原书对齐，勿随意改动）

- 参考 PDF：`tmp/Build a Reasoning Model (From Scratch) (Sebastian Raschka, true pdf).pdf`（440 页）
- 页面 531.36×628.83bp，版心 375bp，正文 10bp/13bp #231F20
- 几何长度一律用 **bp**（1/72in，与 PDF 同单位），不要用 pt（差 0.37%）
- 关键基线：正文首/末行 60.6/603.0；页眉 33.30（居中于整页 x=265.68）；
  章首页页码 605.94（中心 x=276.18）；章名末行 181.55；横线 193.80；巨型章号 217.88
- 全部指标与核对方法见 `README.md` 的「按 Manning 原书 PDF 对齐版式」一节

## 字体

- 中文：STSong（正文）/ Microsoft YaHei（标题、代码注释）——本机没装思源宋体
- 拉丁：**Cambria**（不是 Georgia！原书是等高数字，Georgia 是旧式数字会降到基线以下）
- 代码：JetBrainsMonoNL（TTF 在 `fonts/`，NL = 无连字版）

## 编译

- `build.bat`；手工：`xelatex -shell-escape -interaction=nonstopmode main.tex` **连跑三遍**
- WorkBuddy 沙箱里必须先 `unset PYTHONPATH`（build.bat 已处理）
- TeX Live 2026：`D:\ProgramData\texlive\2026\bin\windows`，minted 3.8.0 / tcolorbox 6.10.0
- 单遍约 2 分钟；不要在编译途中改源文件（会留损坏的 .aux）

## 跨段共享的宏名不要带 `@`

`\ExplSyntaxOn` 与 `\makeatletter` 段之间 `@` 的 catcode 不同，带 `@` 的宏名会裂成两个宏
且 `\gdef\my@x{#1}` 把 `#` 当普通字符而**不报错**。本项目用 `\mychaptergiant`（无 @）。

## 风险

- `work/tools/build_v2.py` 重跑会覆盖 `content/`、`index.tex`（含米色盒与章名断行）
- 未被正文引用的图片：26.jpg、Prompt-Icon.png、Response-Chatgpt.png、chatGpt.png
