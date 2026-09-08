# qce-companion

[![原项目](https://img.shields.io/badge/原项目-shuakami%2Fqq--chat--exporter-317cfe?style=flat-square&logo=github)](https://github.com/shuakami/qq-chat-exporter)

**原项目地址：<https://github.com/shuakami/qq-chat-exporter>**

这是 [qq-chat-exporter](https://github.com/shuakami/qq-chat-exporter)（作者
[shuakami](https://github.com/shuakami)，以下简称 **QCE**）的一个**非官方、
社区自建**增强工具包/插件。QCE 本体是一个基于 [NapCatQQ](https://github.com/NapNeko/NapCatQQ)
（NTQQ 协议端框架）的 QQ 聊天记录导出工具，可以把好友/群聊天记录导出成
HTML、JSON、TXT、Excel 等格式，并支持定时导出、批量任务等功能。

本仓库**不是 fork**，不改动 QCE 的核心导出逻辑，只是在它之上补几个日常用得到
的小功能，并且尽量做成"随时能拆下来"的样子——哪怕以后不维护了，或者官方
项目大改版，这里的东西也不会把你的正式安装搞坏。

> 这个仓库和 QCE 官方项目没有从属关系（非官方衍生工具），使用前请先了解并
> 支持原项目：<https://github.com/shuakami/qq-chat-exporter>。如果你是从
> 原项目搜过来的，这里补充的是"好友会话增量更新"这块原项目暂时没有覆盖的
> 能力，外加两个本地部署用的启动脚本。

## 这里面有什么

| 内容 | 说明 | 是否修改了 QCE 源码 |
| --- | --- | --- |
| `patches/incremental-update-button.patch` | 给 QCE 的 Web UI（`qce-v4-tool`）打的补丁，见下方「更新按钮做了什么」。 | 是，4 个前端文件 + 1 个新增文件 |
| `patches/custom-export-filename.patch` | 给 Rust 服务端加一个可选的 `options.customFileNameStem`，允许调用方指定导出文件名主干。增量导出用它产出 `会话名_20260901.json` 这种短名字，和完整导出的长文件名区分开。不传该字段时完全走官方原命名逻辑。 | 是，`qq-chat-export-server` 一处约 15 行 |
| `patches/fix-fetch-time-filter-unit.patch` | **修官方 bug**：`POST /api/messages/fetch`（消息预览）把请求里的秒级时间戳直接塞进 `MessageFilter`，而该字段约定是毫秒，导致任何带时间范围的预览恒返回 0 条。导出路径本来就调了 `normalize_to_ms`，这里补齐。实测同一查询由 `0 条` 变为 `473 条`。**导出功能不受此 bug 影响**，历史导出数据无需重做。 | 是，`qq-chat-export-server` 一处 2 行 |
| `scripts/一键启动.bat` | 假设你本机是 `NapCatQQ` 源码 + `qq-chat-exporter` 源码 + 本仓库三个目录平级放置，双击就能关闭现有 QQ、以注入模式启动 NapCat（自动带上 QCE 插件）。 | 否 |
| `scripts/重新构建前端.bat` | 打完补丁或者 `git pull` 官方更新之后，重新构建 `qce-v4-tool` 前端并部署到 NapCat 插件目录。 | 否 |

> ⚠️ 打了两个 Rust 补丁（`custom-export-filename` / `fix-fetch-time-filter-unit`）
> 之后，除了重新构建前端，**还需要重新编译 Rust 服务端**
> （`cd qq-chat-export-server && cargo build --release`，约 2~7 分钟），
> 再把产出的 `qce-server.exe` 覆盖到插件的 `runtime/` 目录。
>
> Windows 上编译有两个坑：
> 1. 项目路径含中文时 `link.exe` 可能报错（实际是 Git Bash 的 `/usr/bin/link.exe`
>    抢占了 MSVC 链接器），把两个 crate 复制到**纯英文路径**下编译即可。
> 2. 不要把编译目录放在 `%TEMP%` 下——清理软件会删掉 `target/` 里的构建产物
>    （典型症状：`couldn't read .../out/bindgen.rs`），而且 `cargo clean -p` 救不回来，
>    只能全量重编。建议固定用类似 `C:\Users\<你>\qce-build` 的位置。
>
> **替换 `qce-server.exe` 前先确认没有正在运行的导出任务**，否则任务会被强杀，
> 既拿不到成品，还会在导出目录里留下 `.qce_spool_*.jsonl` 中间文件（大群可能上 GB）。
> 替换完在 NapCat 面板「插件管理」里把插件禁用再启用，就会拉起新的 exe。

> **曾经有个 `chat-viewer.html`（离线聊天气泡查看器），现已移除。**
> 官方导出时直接选 HTML 格式就能得到聊天气泡界面，并且勾上「生成自包含 HTML」
> 会把图片/语音/视频以 base64 内联进单个文件——这比我们那个查看器更好：
> 后者读的是导出 JSON 里记录的腾讯 CDN 链接，链接过期后图片就再也看不到了。
> 官方版本还带虚拟滚动，能扛住超大聊天记录。需要旧版本的话翻 git 历史即可。

## 快速开始

### 想要"更新"按钮功能

前提：你已经有一份能正常运行的 QCE 源码（`qq-chat-exporter`）+ NapCat（`NapCatQQ`），
并且按 QCE 仓库 `AGENTS.md` 里的步骤构建、部署过。

```bash
cd qq-chat-exporter   # 你自己的 QCE 源码目录
P=/path/to/qce-companion/patches

# 只要"更新"按钮的话，打这一个就够（纯前端，不用编译 Rust）
git apply $P/incremental-update-button.patch

# 想让增量导出产出「会话名_日期」这种短文件名，再加这个（需要重新编译 Rust）
git apply $P/custom-export-filename.patch

# 顺手修掉官方预览接口的时间过滤 bug（同样需要重新编译 Rust）
git apply $P/fix-fetch-time-filter-unit.patch
```

三个补丁互相独立，可以单独打，也可以一起打。

打完补丁后照常重新构建前端并部署（或者直接用 `scripts/重新构建前端.bat`，需要把
里面路径变量改成你自己的目录布局）：

```bash
cd qce-v4-tool
pnpm install --frozen-lockfile
pnpm build
# 把 out/ 目录的内容复制到 NapCat 插件的 webui/ 目录
```

打完之后效果：会话列表里，已经成功导出过的**好友**，"导出"按钮会变成"更新"；
点击"更新"只会拉取自上次成功导出以来的新消息（用的是 QCE 现成的
`POST /api/messages/export` 接口，只是把 `filter.startTime` 设成了"上次导出时间"，
`filter.endTime` 设成"现在"——**没有新增任何后端接口**，所以只要官方那一个导出
接口不变，这个补丁大概率能一直打得上）。

如果 `git apply` 因为官方代码变动太多而失败，打开
`patches/incremental-update-button.patch` 看 diff 内容，手动把改动对应贴到
`session-list.tsx`（按钮从"导出"变"更新"的逻辑）和 `page.tsx`
（新增的 `handleIncrementalUpdate` 函数 + `<SessionList>` 上的
`onIncrementalUpdate` 属性）里就行，改动量不大。

### 3. 一键启动 / 重新构建脚本

假设你的目录布局是：

```
你的工作目录/
├── NapCatQQ-main/           # NapCat 源码，已构建
├── qq-chat-exporter-master/ # QCE 源码，已构建，已打上面的补丁
└── qce-companion/           # 这个仓库
```

把 `scripts/` 里两个 `.bat` 复制到"你的工作目录"根目录下，双击
`一键启动.bat` 即可（会自动关闭现有 QQ 并以注入模式重新启动，
请确认这一点你能接受）。如果目录名不一样，改一下脚本开头的路径变量。

## 为什么要做成"补丁"而不是直接改一份代码扔这里

QCE 是一个持续在更新的活跃项目（光是 `qce-v4-tool` 一个模块就有几十个 feature
分支）。如果直接维护一份改过的完整源码副本，官方每次更新我们都要重新对比、
重新改一遍，成本很高而且容易出错。

用 `git apply` 这种"补丁"的方式有两个好处：

1. 补丁打不上的时候，Git 会明确告诉你冲突在哪一行，而不是让你自己去 diff
   两份几万行的代码。
2. 补丁本身很小（两个文件，起止范围都用 `QCE-CUSTOM-ADDON` 注释标出来了），
   看得懂在改什么，也就有能力在官方代码变动后手动调整。

## 「更新」按钮做了什么

已经导出过的**好友**，会话列表里的"导出"按钮会变成"更新"。点它不会直接开导，
而是先做两件事，再把官方的导出向导打开、把时间范围和文件名预填好——格式、
资源开关、过滤条件仍然由你自己在向导里选。

**① 定位续传起点**

取「上一次导出文件里最后一条消息的时间」，而不是「上次导出任务的完成时间」。
后者在上次导出设过截止日期时会漏掉中间那段（任务 7/20 跑完、但只导到 7/1，
按完成时间续传就会把 7/1~7/20 永久跳过）。

**② 检测"后同步"的历史消息**

QQ 的消息是懒同步的：你今天在电脑上打开某个会话往上翻，前几天的消息才被补
下来，而它们带的是**原始发送时间**，会插进历史里。只按"上次最后一条往后拉"
永远抓不到这些。

所以这里会把已导出文件里「每天多少条」和本机数据库里「每天实际多少条」做
对比，找出变多了的日期，并把导出起点往前扩到最早的那个缺口日——一个任务同时
覆盖补漏和新消息。重叠部分不用担心，官方合并按 `msgId` 去重。

比对基线**支持 JSON 和 HTML 两种导出**。官方 HTML 用的是 chunked 模式，消息以
`__QCE_CHUNK__({id:"c000001",messages:[{"id":..,"ts":..}]})` 的结构化数据内嵌在
页面里，逐条解析出来即可（实测 63 MB / 44780 条的大群文件解析耗时 1.4 秒，
条数与文件元数据声明完全一致）。

查询采用**两层策略**：先按月粗查，只有数量对不上的月份才展开到天。实测一个
跨 95 天、16499 条消息的会话，只发了 5 次查询、耗时 0.1 秒；逐天暴力查则需要
95 次。

核心逻辑在 `qce-v4-tool/lib/incremental-sync.ts`（补丁新增的独立文件），
不依赖官方内部实现，官方升级时基本不会冲突。

## 和官方功能的分工

QCE 官方在 v6.2 引入了「导出任务」模块（`/plans` 页面，Issue #641），提供
群聊集合 / 标签关联 / 自动拆分 / **增量导出** / 失败重跑 / 运行记录。它的数据
模型是围绕群组设计的（增量游标是 `groupCode -> 时间`），**不覆盖好友会话**。

所以这里的补丁只做官方没做的那一半：

| 场景 | 用什么 |
| --- | --- |
| 群组增量导出 | 官方 `/plans` 导出任务模块（更完整，支持批量和失败重跑） |
| 好友增量导出 | 本仓库的补丁（会话列表里直接点"更新"） |

至于"想把导出的聊天记录看成聊天气泡"这个需求，直接用官方的 HTML 导出格式
即可（建议同时勾上「生成自包含 HTML」，图片资源会 base64 内联进单个文件，
不依赖会过期的腾讯 CDN 链接）。本仓库不再另做查看器。

## 已知限制

- **不支持导出/渲染 QQ 消息的"表情回应"**（消息下面那一排点赞表情）。
  经确认，NapCat/NTQQ 只能通过实时事件监听到表情回应的发生，没有能查询
  历史消息表情回应的官方接口，没法对着老聊天记录"补录"。如果以后需要这个
  功能，只能另外做一个从现在开始实时监听、持续记录的后台插件，且没法覆盖
  监听开始之前发生的回应。

## 目录结构

```
qce-companion/
├── README.md
├── LICENSE                          # GPL-3.0，与 QCE 官方项目一致
├── patches/
│   ├── incremental-update-button.patch    # 前端：好友增量更新按钮
│   ├── custom-export-filename.patch       # Rust：自定义导出文件名
│   └── fix-fetch-time-filter-unit.patch   # Rust：修官方预览时间过滤 bug
└── scripts/
    ├── 一键启动.bat
    └── 重新构建前端.bat
```

## 相关项目

- **原项目 / QCE 本体**：[shuakami/qq-chat-exporter](https://github.com/shuakami/qq-chat-exporter) —
  QQ 聊天记录导出工具，支持 HTML / JSON / TXT / Excel 导出、定时导出、批量任务、
  资源（图片/视频/语音/表情）下载。**本仓库依赖它才能工作，请先去这个仓库了解
  安装和基础使用方法。**
- **底层框架**：[NapNeko/NapCatQQ](https://github.com/NapNeko/NapCatQQ) —
  QCE 依赖的 NTQQ 协议端框架（OneBot 11 实现）。
- **关键词**：QQ 聊天记录导出、QQ Chat Exporter、QCE、NapCat、NapCatQQ、OneBot、
  增量导出、增量更新、好友聊天记录备份。

## 许可证

沿用 QCE 官方项目的 [GPL-3.0](LICENSE)——`patches/` 里的内容本身就是对
GPL-3.0 代码的修改，为避免许可证混用的麻烦，本仓库其余内容一并按 GPL-3.0 发布。
