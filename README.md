# 《从零构建推理模型》中文版 —— LaTeX 工程

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

**耗时**：单遍约 2 分钟（本机）。瓶颈是 minted：465 个代码块包在 `tcolorbox` 里，
只能逐块走 `highlight` 单次调用，每块都要启动一次 Python，无法用 minted 的批量高亮模式。
第二遍开始 `_minted/` 缓存命中，会明显快一些。**连跑三遍**最稳（目录/书签/`remember picture` 定位）。
产物：404 页 / 字体全部内嵌。

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

## 按 Manning 原书 PDF 对齐版式

用 PyMuPDF 逐 span 量测 `tmp/Build a Reasoning Model (From Scratch) (Sebastian Raschka, true pdf).pdf`
（440 页），把下列指标逐一抄进 `book/ccs.tex`，编译后**再量自己的 PDF 回代校验**，循环到逐项吻合。
几何长度一律用 `bp`（1/72in，与 PDF 坐标同单位），不要用 `pt`（1/72.27in，会差 0.37%）。

| 指标 | 原书实测 | 本项目实测 |
| --- | --- | --- |
| 页面尺寸 | 531.36 × 628.83 bp | 531.36 × 628.83 bp ✓ |
| 版心宽 / 左右边距 | 375 bp（奇偶页有 ±4.5 bp 偏移，取平均） | 375 bp ✓ |
| 正文首行 / 末行基线 y | 60.6 / 603.0 | 60.6 / 603.0 ✓ |
| 正文字号 / 行距 / 字色 | 10 bp / 13.0 bp / #231F20 | 10 bp / 13 bp / #231F20 ✓ |
| 页眉基线 y / 水平中心 x | 33.30 / 265.68（居中于**整页**） | 33.30 / 265.68 ✓ |
| 页眉内容 | 偶页 `Chapter n 斜体章名`、奇页节名，9 bp | 单面，居中显示 `第 n 章 章名`（9 bp 无衬线） |
| 章首页页码基线 y / 中心 x | 605.94 / 276.18 | 605.94 / 276.18 ✓ |
| 章名（`\chapter*`） | 30 bp 斜体 #476B85，右对齐，末行基线 181.55 | 181.55 ✓（1 行 / 2 行标题都恒定） |
| 章名下横线 | 0.5 bp #476B85，y=193.80，右缘 474.18，长 300 bp | 完全一致 ✓ |
| 巨型章号 | 225 bp 斜体 #D1D3D4，基线 y=217.88 | 217.88 ✓ |
| 「本章内容」米色盒 | #F7F4E9，x 77.57→329.00（宽 251.43 bp），顶 y=291.75 | 77.5→328.5，顶 291.5 ✓ |
| 节 / 小节标题 | 12.5 bp / 10.5 bp #476B85，节号悬挂在版心左 | 一致 ✓ |
| 代码 | JetBrains Mono NL 8 bp / 10.11 bp，无框无底色，标题条 #679CC3 白字 | 一致 ✓ |
| 代码配色 | 关键字 #1155CC、字符串 #960000、数字 #2FB41D、注释 #636466 | 一致（`book/manning-pygments-style.tex`） |
| 图注 | 8 bp 无衬线，左缘悬挂 36 bp 到页边距，通栏两端对齐 | 一致 ✓ |

### 几个关键实现点（改版式前先看）

1. **`titlesec` 必须同时定义带编号的章格式**，`name=\chapter,numberless` 才会生效；
   只定义 numberless 时 `\chapter*` 仍走 `book.cls` 默认的 24.88pt 黑体章头。
2. **章名块用 `\vbox to 64bp\bgroup\vfil … [\egroup]` 固定高 2 行且底部对齐**：
   这样标题占 1 行还是 2 行，末行基线都恒定在 181.55，下面的横线位置也就恒定。
3. **`\chapter*` 不触发 `\chaptermark`**，页眉标记必须在 `\myChapter` 里自己 `\markboth`。
4. **章号变量不能带 `@`**：它在 `\ExplSyntaxOn` 段赋值、在 `\makeatletter` 段读取，
   两处 `@` 的 catcode 不同会变成两个不相干的宏（曾导致巨型章号一直画不出来）。
5. **`\ifx` 不展开宏**：判断 `\mychaptergiant` 是否为空要写 `\ifx\mychaptergiant\empty`
   （比较「含义」），写成 `\ifx\\#1\\` 永远判非空。
6. **页眉居中于整页而不是版心**：`\makebox[0bp][c]{…\hspace*{38.64bp}}` 把居中点左移 19.32bp
   （版心中心 285bp → 页面中心 265.68bp）。
7. **章首页页码用绝对 overlay 定位**（`\fancyfoot` 里放 `remember picture,overlay` 的
   tikzpicture）：`\raisebox` 会被页脚盒的高度变化抵消，调不动基线。
8. **长章名折出「孤字」**：标题里用 `\\` 手工断行，`\myChapter` 会把断行符替换成空格
   再写进目录与页眉，两边互不影响。
9. **minted 自定义配色不装 Python 包**：把 Pygments 生成的样式文件头尾原样抄下来，
   中间 token 换成原书颜色，在导言区用 `\CatchFileDef` 读进 `\minted@styledef@manning`
   再 `\minted@detectconfig`，见 `book/manning-pygments-style.tex`。

### 与原书仍存在的差异

- 原书是双面排版（奇偶页版心差 9 bp、页眉页码在外侧），本项目按用户选择用**单面**，
  边距取奇偶平均，页眉统一为居中章名。
- 原书代码清单里的标注是**带箭头的图注式标注**（指向某一行），译文版改为行内 `#N` 标记
  + 清单下方逐条解释，属于内容组织差异，非版式问题。
- 拉丁正文用 Cambria 代替商用字体 New Baskerville，中文用 STSong（原书无中文）。
- 页码在版心右缘 472.5 bp，原书 474.18 bp（差 1.68 bp，源于两边距取平均）。

## 想改样式，主要看这几处

1. **字体 / 字号** —— `book/ccs.tex` 里的「★★★ 字体设置」区块，集中在一个地方：

   ```latex
   \setCJKmainfont[AutoFakeBold=true,AutoFakeSlant=true]{STSong}   % 中文正文
   \setCJKsansfont[...]{Microsoft YaHei}                          % 中文标题
   \setCJKmonofont[...]{Microsoft YaHei}                          % 代码里的中文
   \setmainfont{Cambria}[BoldFont=*-Bold, ItalicFont=*-Italic,
                         BoldItalicFont=*-BoldItalic]             % 拉丁正文
   \setmonofont{JetBrainsMonoNL}[Path=fonts/, Extension=.ttf, ...] % 代码
   \usepackage[fontsize=10bp]{fontsize}                           % 正文字号
   ```

   > 正文字号 10bp 是照原书来的：用 PyMuPDF 量原书 PDF 的正文 span，主字号就是 10bp。
   > 拉丁正文用 Cambria 而不是 Georgia，**关键在于原书数字是「等高数字」**（lining figures），
   > Georgia 是旧式数字（数字会降到基线以下）；实测 Cambria 的数字宽高比与原书最接近
   > （0.496 / 0.671 em，原书 0.484 / 0.667 em）。
   > 代码字体 `JetBrainsMonoNL` 的 TTF 已随项目放在 `fonts/` 目录（NL = 无连字版）。

   本机没有模板默认的思源宋体（`SourceHanSerifSC-SemiBold`），因此用华文宋体代替——
   两者都是 TrueType，嵌入 PDF 后是 Type0 字体（可选可复制），不会出现位图化。
   装好思源宋体后，把名字换成 `SourceHanSerifSC-SemiBold` 即可。

2. **页面尺寸 / 边距** —— 已按原书实测对齐：531.36bp × 628.83bp（= 7.380in × 8.734in），
   版心宽 375bp，左右边距取原书奇偶页实测平均（原书有 ±4.5bp 的奇偶偏移）。
   `top/bottom/headsep` 三个值是按「正文首行基线 60.6、末行基线 603.0、页眉基线 33.30」反推的。
   想换成模板默认的 A4，改成
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
