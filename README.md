# qce-companion

[qq-chat-exporter](https://github.com/shuakami/qq-chat-exporter)（以下简称 QCE）的一个**非官方、社区自建**增强工具包。

不是 fork，不改动 QCE 的核心导出逻辑，只是在它之上补几个日常用得到的小功能，
并且尽量做成"随时能拆下来"的样子——哪怕以后不维护了，或者官方项目大改版，
这里的东西也不会把你的正式安装搞坏。

> 这个仓库和 QCE 官方项目没有从属关系，用之前自己判断是否适合你的使用场景。

## 这里面有什么

| 内容 | 说明 | 是否修改了 QCE 源码 |
| --- | --- | --- |
| `chat-viewer.html` | 单文件、纯离线的聊天记录查看器，把 QCE 导出的 `.json` 渲染成类似 QQ/微信的聊天气泡界面，支持图片、商城表情/贴纸、引用消息、合并转发消息（可展开）。 | 否，完全独立 |
| `patches/incremental-update-button.patch` | 给 QCE 的 Web UI（`qce-v4-tool`）打的一个小补丁：已经导出过的好友/群，列表里的"导出"按钮变成"更新"，点一下只拉取上次导出之后的新消息。 | 是，两个前端文件的小改动，见下文 |
| `scripts/一键启动.bat` | 假设你本机是 `NapCatQQ` 源码 + `qq-chat-exporter` 源码 + 本仓库三个目录平级放置，双击就能关闭现有 QQ、以注入模式启动 NapCat（自动带上 QCE 插件）。 | 否 |
| `scripts/重新构建前端.bat` | 打完补丁或者 `git pull` 官方更新之后，重新构建 `qce-v4-tool` 前端并部署到 NapCat 插件目录。 | 否 |

## 快速开始

### 1. 只想要"聊天气泡查看器"

不需要装任何东西。直接双击 `chat-viewer.html` 用浏览器打开，把 QCE 导出的 `.json`
文件拖进网页窗口，或者点右上角"选择 JSON 文件"。全程本地渲染，不联网，可以脱离
QCE 单独使用——只要你手上有一份 QCE 导出的 JSON 文件即可。

### 2. 想要"更新"按钮功能

前提：你已经有一份能正常运行的 QCE 源码（`qq-chat-exporter`）+ NapCat（`NapCatQQ`），
并且按 QCE 仓库 `AGENTS.md` 里的步骤构建、部署过。

```bash
cd qq-chat-exporter   # 你自己的 QCE 源码目录
git apply /path/to/qce-companion/patches/incremental-update-button.patch
```

打完补丁后照常重新构建前端并部署（或者直接用 `scripts/重新构建前端.bat`，需要把
里面路径变量改成你自己的目录布局）：

```bash
cd qce-v4-tool
pnpm install --frozen-lockfile
pnpm build
# 把 out/ 目录的内容复制到 NapCat 插件的 webui/ 目录
```

打完之后效果：会话列表里，已经成功导出过的会话，"导出"按钮会变成"更新"；
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

## 已知限制

- **不支持导出/渲染 QQ 消息的"表情回应"**（消息下面那一排点赞表情）。
  经确认，NapCat/NTQQ 只能通过实时事件监听到表情回应的发生，没有能查询
  历史消息表情回应的官方接口，没法对着老聊天记录"补录"。如果以后需要这个
  功能，只能另外做一个从现在开始实时监听、持续记录的后台插件，且没法覆盖
  监听开始之前发生的回应。

- `chat-viewer.html` 里的图片/表情走的是导出 JSON 里记录的原始 CDN 链接，
  部分链接（尤其是很旧的图片消息）可能已经过期打不开，这是 QQ 服务端的
  链接有效期限制，不是查看器本身的问题。

## 目录结构

```
qce-companion/
├── README.md
├── LICENSE                          # GPL-3.0，与 QCE 官方项目一致
├── chat-viewer.html                 # 独立聊天气泡查看器
├── patches/
│   └── incremental-update-button.patch
└── scripts/
    ├── 一键启动.bat
    └── 重新构建前端.bat
```

## 许可证

沿用 QCE 官方项目的 [GPL-3.0](LICENSE)——`patches/` 里的内容本身就是对
GPL-3.0 代码的修改，`chat-viewer.html` 虽然是完全独立编写的新文件，为了避免
许可证混用的麻烦，一并按 GPL-3.0 发布。
