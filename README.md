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

或手工执行（**必须加 `-shell-escape`**；目录与书签需连跑三遍才完全稳定）：

```bat
set PATH=D:\ProgramData\texlive\2026\bin\windows;D:\anaconda3;%PATH%
set PYTHONPATH=
set SELFAUTOLOC=D:\ProgramData\texlive\2026\bin\windows

xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
xelatex -shell-escape -interaction=nonstopmode -synctex=1 main.tex
```

> 只要 `ccs.tex` 里那段 `\minted@cachedir` 修复在位，**无需设置任何
> `TEXMF_OUTPUT_DIRECTORY` / `TEXMFOUTPUT` 环境变量**（反而应当清空，
> 避免其空值/残留值干扰导言区的求值）。

### 疑难排查：代码块全部编译失败

TeX Live 2026 把 minted 升到了 v3（底层可执行文件由 `pygmentize` 换成了
`latexminted`）。本工程 465 处代码块全部依赖它，因此下面两件事**缺一不可**：

1. **`python.exe` 必须在 `PATH` 上。**
   `latexminted` 本体是 TeX Live 里的一个 Python 脚本，由 `runscript.exe` 包装器
   用 `python.exe` 启动。若 `PATH` 里没有 `D:\anaconda3`（含 `python.exe` 的那层），
   会报 `program not found (not part of TeX Live): python.exe`。
   注意：`PATH` 里要放的是 **Python 安装根目录**，不是 `Scripts` 子目录。

2. **`\minted@cachedir` 必须是绝对路径**（已在 `book/ccs.tex` 中修好，
   见该文件「【关键】minted v3 在 Windows 下的缓存目录必须是绝对路径」一节）。

   `latexminted` 写入任何文件前都要过 `latexrestricted` 的安全校验，
   源码见 `_restricted_pathlib.py` 的 `writable_dir()`：

   ```python
   elif self.is_absolute() and not any(self.is_relative_to(p)
                                       for p in self.tex_texmfoutput_roots()):
       return (False, 'security settings do not permit access to this location')
   ```

   也就是说：
   - **绝对路径** → 必须落在 `tex_texmfoutput_roots()` 内；
   - **相对路径** → `is_absolute()` 为假，**直接短路进拒绝分支**，
     根本到不了任何放行判断。

   而 minted 默认 `\minted@cachedir = "_minted"`，生成的文件名形如
   `_minted/<md5>.highlight.minted`，**全是相对路径**——于是 465 处代码块
   全部写入失败。

   更麻烦的是 `latexminted` 会把真正原因**吞掉**（塞进
   `_<md5>.message.minted`），只在 LaTeX 侧留下一句极具误导性的话：

   ```
   ! Package minted Error: Cannot write file "_xxx.index.minted" outside
     working directory, TEXMFOUTPUT, and TEXMF_OUTPUT_DIRECTORY.
   ```

   看到这句时，**不要**去怀疑工作目录或路径拼写，也**不要**急着去设那两个
   环境变量——它几乎总是「相对路径被拒」的伪装。

   实测（`latexminted` 0.7.0 + `latexrestricted` 0.6.2）：

   | `\minted@cachedir` | 结果 |
   | --- | --- |
   | `"_minted"`（默认） | ✗ 写入被拒（相对路径） |
   | `""` | ✗ 写入被拒（仍是相对路径） |
   | 项目根目录**绝对路径** | ✓ 正常 |

   修法（`ccs.tex` 导言区，`minted` 加载之后、`\minted@detectconfig` 之前）：

   ```latex
   \makeatletter
   \CatchFileDef{\mintedProjectRoot}{|"kpsewhich --var-value PWD"}%
     {\minted@standardcatcodes\endlinechar=-1}%
   \def\minted@stripcr#1\r{#1}%
   \edef\mintedProjectRoot{\expandafter\minted@stripcr\mintedProjectRoot\r}%
   \edef\minted@cachedir{\mintedProjectRoot}%
   \makeatother
   ```

   连带效果是 `\minted@cachepath` 变成 `<绝对路径>/`，`latexminted` 拿到的
   所有待写路径都是绝对路径，全部落在项目根目录内、校验通过。

   > **为什么读 `PWD` 而不是 `TEXMFOUTPUT`？**
   > 第一版曾用 `kpsewhich --var-value TEXMFOUTPUT`，但该变量**默认为空**，
   > 空值会让 `\minted@cachedir` 变成空串 → 仍是相对路径 → 465 处代码块照样
   > 全灭，还会连带炸出 `\pydatawritekeyedefvalue` 一类莫名错误。
   > `PWD` 恒等于运行 `xelatex` 的目录，**不依赖任何环境变量**，所以最稳。
   > 实测：清空 `TEXMFOUTPUT` / `TEXMF_OUTPUT_DIRECTORY` 后编译仍然
   > `exit=0 / errors=0`，463 个高亮缓存正常落到项目根目录。

   > 注意：必须直接改 `\minted@cachedir` 宏本身，**不能**用
   > `\setminted{cachedir=...}`——minted 只为它注册了带 `.estore` 的描述子，
   > 空值会被 pgfkeys 以 `I do not know the key '/minted/global/cachedir'` 拒绝。

3. **清空 `PYTHONPATH`。**
   残留的 `PYTHONPATH` 会让 `latexminted` 加载到错误的 Python 模块，
   导致代码块静默退化。`build.bat` 已包含 `set PYTHONPATH=`。

> 备注：这类失败**不会**让 `xelatex` 返回非零退出码，只看退出码会漏掉。
> 因此 `build.bat` 末尾会用 `findstr` 扫一遍 `main.log`，若仍存在
> `Cannot write file` / `Cannot highlight code` 就明确报警。

## 官方代码

[reasoning-from-scratch](https://github.com/rasbt/reasoning-from-scratch)