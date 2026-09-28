# 《从零构建推理模型》中文版 —— LaTeX 工程（按 Cpp23-Best-Practices 模板重排）

由 `D:/Ego/trans/latex_source`（旧版单层 `chapters/*.tex`）重排而来，**不影响旧目录**，可直接对照编译结果。

## 目录结构

结构照搬 `Cpp23-Best-Practices-20251127` 模板：

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

对应关系：`book.tex → main.tex`，`book/ccs.tex → book/ccs.tex`，
`book/index.tex → book/index.tex`，`book/content/partN/n.tex → book/content/<类别>/<编号>.tex`。

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

> 若在 WorkBuddy 之类的沙箱里编译，需先清空 `PYTHONPATH`（`set PYTHONPATH=`），
> 否则 minted 的临时文件清理会被沙箱的删除钩子拦截，导致代码块无法生成。

**耗时**：单遍约 30–35 分钟（本机）。瓶颈是 minted：465 个代码块包在 `tcolorbox` 里，
只能逐块走 `highlight` 单次调用，每块都要启动一次 Python，无法用 minted 的批量高亮模式。
第二遍开始 `_minted/` 缓存命中，会明显快一些。产物：482 页 / 204 条书签 / 字体全部内嵌。

## 编译问题修复记录（TeX Live 2026）

`tlmgr update --self --all` 把 minted 升到 **3.8.0**、tcolorbox 升到 **6.10.0** 之后，
全书 465 个代码块全部编译失败，报：

```
! Package minted Error: Cannot locate file "book/content/main/main.listing" (kpsewhich failed).
! FancyVerb Error: No verbatim file book/content/main/main.listing
```

### 原因

三件事叠加：

1. 代码块用的是 `tcolorbox` 的 `tcblisting`（`codebox` / `codeboxt`）。它的做法是先把代码正文
   写到输出目录下的临时文件 —— 默认文件名 `\kvtcb@listingfile = \jobname.listing`，即 `./main.listing` ——
   再调用 `\inputminted[...]{python}{main.listing}`。
2. minted v3 的 `\minted@define@inputfilepath` 会**无条件**给传进来的文件名加上
   `\import@path` 前缀，本意是让 `\inputminted` 的路径按「当前文件所在目录」解析。
3. 章节文件是用 `subfiles` 挂进来的，`subfiles` 依赖 `import`，于是 `\import@path` 被设成
   当前子文件所在目录 `book/content/main/`。

于是文件名被拼成 `book/content/main/main.listing` —— 这个位置根本没有文件，Python 侧
（`latexminted`）用 `kpsewhich` 找不到就退出，minted 报错。

### 修法

在 `book/ccs.tex` 里对 `\minted@define@inputfilepath` 打了一个 6 行补丁（就在两个
`codebox` 定义之后）：**保留「优先按当前子文件目录解析」的原意，只在该路径确实不存在时，
退回按输出目录（当前目录）解析。** 对 `\inputminted` 的常规用法没有影响。

> 本工程没有直接用 `\inputminted`，唯一调用方就是 `tcolorbox`，所以这个回退是安全的。
> 若以后 minted 改名了这个内部宏，补丁会静默失效、问题复现 —— 届时把补丁同步过去即可。

### 顺带修掉的两个小问题

- `book/content/main/03.tex`：7 处 `\textbackslashboxed`。`\textbackslash` 后面直接跟字母，
  TeX 会把它整体当成一个控制字 `\textbackslashboxed`（未定义）。已改成 `\textbackslash{}boxed`，
  渲染为字面量 `\boxed`。
- 文档口径：正文实际是 `fontsize=10pt`（与原书实测一致），但注释和本 README 原写作 13pt，已改正。

### 排查这类问题的手法（可复用）

1. 先看 `main.log` 里第一条 `! Package minted Error` 及其**完整文件名**，路径拼接错误通常一眼可见。
2. 同目录下 `_<md5>.data.minted` 是 minted 传给 Python 的 JSON 参数，里面有
   `inputfilepath` / `currentfilepath` / `currentfile` —— 直接就能看出路径是在哪一步被拼错的。
3. 用**最小样例**隔离：`book` + `subfiles` + `tcolorbox tcblisting` 三个要素缺一不可，
   少任何一个都不会复现（minted 会改用批量高亮模式，问题被掩盖）。
4. 想单独手工跑 Python 侧时注意：脱离 TeX 直接执行 `latexminted.py` 会因为
   `SELFAUTOLOC` 未设置而报 `LatexConfigError`，这是**另一个**失败路径，别被它带偏；
   经 TeX 的 `runscript` 包装器调用时该变量是齐的。

## 这次重排版改了什么

| 项目 | 旧版 latex_source | 新版 latex_source_v2 |
| --- | --- | --- |
| 文件组织 | 单层 `chapters/*.tex`，`main.tex` 里逐个 `\input` | 模板式：`主文件 + 导言区 + 索引 + 分片内容`，`index.tex` 里用 `\myChapter` 挂载 |
| 代码高亮 | `listings` 伪高亮（正则很脆弱，含 `_`、`^` 的块被降级成 verbatim） | `minted` + Pygments 真正语法高亮（行号 + 左侧灰槽），中英文混排正常 |
| 代码标题 | 全部显示占位标题「代码」 | 有原标题的显示「代码清单 x.y 标题」（129 处），没有标题的不再显示占位标题 |
| 插图 | `figure` 浮动体 | `\myGraphic{宽度}{路径}{图注}`（模板做法，图文不分离）；PDF 书签、页眉页码照旧 |
| 侧栏 / 注意框 | 藏青 + 深蓝标题栏 | 模板的 `mySidebar`（中性灰）/ `myWarning`（红）/ `myNotic`（蓝）/ `myTip`（绿） |
| 表格 | `\hline` 全框线 | `booktabs` 三线表 |
| 标题 | `titlesec` 固定 pt 字号 | `ctex` 的 `\zihao{}` 字号体系（二号/三号/四号），与模板一致 |
| 段落 | 首行不缩进 + 段间距 | 中文书籍惯例：首行缩进 2 字 |
| 章节命令 | 裸 `\chapter` + `\appendix` | `\myChapter` / `\myAppendix` / `\myFront` / `\myFrontNoToc`（对应模板 `\myChapter` 系列） |
| 目录 | 章条目没有引导点 | `\l@chapter` 改为带引导点（与节条目一致） |
| 页眉 | `2.5. 加载预训练模型`（book.cls 自带句点） | `2.5  加载预训练模型`，与目录、正文统一 |
| 长代码行 | 溢出到页边 | `breakanywhere=true`，超长行按 ↪ 续行 |
| 表格长文件名 | 撑破相邻栏目 | 表内 `\_` 处允许断行；行号列自动收窄为 `@{}c@{}` |

## 想改样式，主要看这几处

1. **字体 / 字号** —— `book/ccs.tex` 里的「★★★ 字体设置」区块，集中在一个地方：

   ```latex
   \setCJKmainfont[AutoFakeBold=true,AutoFakeSlant=true]{STSong}   % 中文正文
   \setCJKsansfont[...]{Microsoft YaHei}                          % 中文标题
   \setCJKmonofont[...]{Microsoft YaHei}                          % 代码里的中文
   \setmainfont{Georgia}                                          % 拉丁正文（模板默认 Hack）
   \setmonofont{Consolas}                                         % 代码
   \usepackage[fontsize=10pt]{fontsize}                           % 正文字号
   ```

   > 正文字号 10pt 是照原书来的：用 PyMuPDF 量原书 PDF 的正文 span，主字号就是 10pt
   > （原书页面 7.380×8.734in，本项目页面 7.375×9.25in，见下条）。

   本机没有模板默认的思源宋体（`SourceHanSerifSC-SemiBold`），因此用华文宋体代替——
   两者都是 TrueType，嵌入 PDF 后是 Type0 字体（可选可复制），不会出现位图化。
   装好思源宋体后，把名字换成 `SourceHanSerifSC-SemiBold` 即可。

2. **页面尺寸** —— 目前是 7.375in × 9.25in（旧版 `latex_source` 的取值，沿用至今）。
   注意：原书英文版的实际开本是 **7.380in × 8.734in**，也就是说现在比原书高 0.516in、
   版心多出约 6%。要完全对齐原书，把 `geometry` 那行改成
   `paperwidth=7.38in, paperheight=8.734in`；想换成模板默认的 A4，改成
   `\usepackage[a4paper,left=2.5cm,right=2cm,top=2.54cm,bottom=2.54cm]{geometry}`（文件中已给出注释行）。
   ⚠️ 改页面尺寸会整体改变分页，目录/书签页码需要重新编译两遍才会稳定。

3. **代码块样式** —— `ccs.tex` 中的 `codebox`（无标题）与 `codeboxt`（带标题）两个 `tcolorbox` 定义。

4. **提示框配色** —— `myNotic`（蓝）/ `myTip`（绿）/ `myWarning`（红）/ `mySidebar`（灰）。

5. **插图版式** —— `\myGraphic` 定义（宽度上限为 `\textwidth`，高度上限为 `0.86\textheight`，自动等比缩放）。

## 章节顺序 / 增删章节

编辑 `book/index.tex` 末尾的条目即可，一行一个 `\myChapter{章号}{标题}{文件路径}`，
前言类用 `\myFront{标题}{文件}`，扉页类用 `\myFrontNoToc{文件}`，附录用 `\myAppendix{序号}{标题}{文件}`。

## 源数据如何重新生成

`<项目>/work/tools/build_v2.py` 是本次重排版的转换脚本，负责把旧 `latex_source/chapters/*.tex`
转换成这套结构（图片自动拷贝）。修改 `ccs.tex` 之外的东西时一般不需要重跑它；
若旧 `chapters/` 内容有更新，重跑即可覆盖 `content/` 下的文件（`index.tex`/`main.tex` 会一并重建）。
