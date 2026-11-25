# Windows 安装、项目注册和调试

## 1. 安装官方桌面版

在 Windows 10/11 x64 上，从 [Orca 官方 Release](https://github.com/stablyai/orca/releases) 下载当前需要的版本。复现 2026-11-25 环境时用 [v1.4.274 Windows 安装包](https://github.com/stablyai/orca/releases/download/v1.4.274/orca-windows-setup.exe)。在下载文件所在目录检查：

```powershell
Get-AuthenticodeSignature .\orca-windows-setup.exe | Select-Object Status, SignerCertificate
Get-FileHash .\orca-windows-setup.exe -Algorithm SHA256
```

基线包签名为 `Valid`，签名人 **SignPath Foundation**，SHA-256 为 `a568616184c78618448c12a678675f209ee7b2631bc8d20a3b9b567b6b962aaa`。换版本时以对应 Release 发布的校验值为准。由用户运行安装器并完成首次启动。

本机验证过的默认 CLI 位置：

```powershell
$orcaExe = Join-Path $env:LOCALAPPDATA 'Programs/orca/resources/bin/orca.exe'
& $orcaExe --version
& $orcaExe status --environment local --json
& $orcaExe agent installed --environment local --json
```

Runtime 应报告 `app.running: true`、`runtime.reachable: true` 和 `runtime.state: ready`。可把 `resources\bin` 加入 **用户 PATH**，再开一个 PowerShell 用 `Get-Command orca` 确认命中刚装的版本。如果当前 Orca 会话提供 `ORCA_CLI_COMMAND`，用它检索与当前二进制匹配的 Skill。

分别安装并登录需要的 Agent。Orca 发现到 CLI 只说明可尝试启动，登录和模型权限需要单独验证。首次启动可能引入 Orca 的 Codex 状态上报 hooks。若目标机已维护 Codex hooks，先保留原 `config.toml`，比较 `hooks` 差异。首次安装基线只观察到 Orca 加入 hooks，官方 Codex 登录与渠道保留。

## 2. 注册现有项目

先用目标机已有的 Git 仓库或把要用的项目克隆到合适的目录。先查看 `orca repo list --environment local --json`，只注册缺少的路径。以下变量换成真实绝对路径：

```powershell
orca repo add --environment local --path $videoClientFolder --kind folder --json
orca repo add --environment local --path $paRepo --kind git --json
orca repo add --environment local --path $toolUseRepo --kind git --json
orca repo add --environment local --path $rebirthRepo --kind git --json
orca repo list --environment local --json
```

2026-11-25 的四项是 **视频客户端**、**pa**、**tool-use**、**rebirth**。视频客户端是父目录，在 Orca 里按普通 Folder 注册。目录内的独立仓库继续留在原处，按该次迁移要求不作为单独项目添加。Git 项目需要能通过 `git -C $path rev-parse --show-toplevel`。在左侧「项目」栏复核四个项目。如果列表少了其中某项，先确认查的是同一个本机 Profile、项目路径是否注册、项目是否被隐藏。已隐藏的项目可用 `orca repo unhide` 恢复；先核对目标项目。

迁移项目是登记目录。T3 对话、运行历史和临时区保留在 T3，未导入 Orca。不要把任一应用的 SQLite 或整个 AppData 目录作为跨机导入方式。

## 3. 需要开发 Orca 时再拉源码

```powershell
git clone https://github.com/stablyai/orca.git
Set-Location .\orca
git switch -c orca-v1.4.274 v1.4.274
git rev-parse HEAD
```

基线提交为 `48fcb4dfa59a0b145779a98f6d92c2890ef58262`。如果已有同名分支或 checkout，先核对 HEAD 和工作区，避免覆盖。可把这份源码也作为单独的 Git 项目注册到 Orca。

按 checkout 的 [开发环境文档](https://github.com/stablyai/orca/blob/v1.4.274/docs/development.md) 安装 **Node 24、Python 3、Visual Studio Build Tools 的 Desktop development with C++**，再按 `package.json` 的 `packageManager` 和 `config/.bun-version` 安装 pnpm、Bun。基线分别是 pnpm `12.18.0`、Bun `1.4.4`。在仓库根目录核对 `pnpm --version`。若 Windows 上 Corepack 无法写入 Node 安装目录，按上游文档使用同版本 pnpm，或修正现用版本管理器的 shim。

```powershell
pnpm install --frozen-lockfile
pnpm build:cli
$env:ORCA_BACKGROUND_LAUNCH = '1'
pnpm dev --worktree-profile
```

这是上游开发路径，本次只验证了官方安装版。按 checkout 的 `AGENTS.md` 运行后台开发实例和对应检查。开发实例有独立数据目录。通过启动日志的 `ORCA_DEV_INSTANCE` 或 `out/dev-instance.json` 确认实际 Profile、渲染端口与 CDP 端口；开发 CLI 按仓库文档使用 `orca-dev`。在调试前确认命令操作的是 dev 实例还是已安装的 Orca。

### 常见定位顺序

- **CLI 找不到或连错实例**：先查 `Get-Command orca`、`orca --version`、`orca status --environment local --json` 和当前 `ORCA_CLI_COMMAND`。暂时连不上时，先检查 Runtime 与 app 状态。
- **应用状态与界面不同**：先确认活动 Profile 和当前账号。安装版日志目录通常是 `%APPDATA%\orca\logs`，开发版从 `ORCA_DEV_INSTANCE` 找数据目录。只取关联日志和时间段。
- **Codex 周额度看起来不对**：在 Orca 底部「使用量」切换「已用 / 剩余」。这是全局显示口径。需要查数值来源时，对照本机官方 Codex app-server 的 `account/rateLimits/read` 与 Orca 的周窗口；`usedPercent` 表示已用，周窗口是 10080 分钟。安装版曾实测仅有周额度的 Pro Lite 能正确显示，切换口径后应显示互补的百分比。排查期间只读额度，保留用户余额。
- **验证界面**：网页和 Electron 页面使用 Ego Lite，原生 Orca 窗口或文件选择器使用 Cua Driver 的后台操作，遵守 [skill-tool 验收](https://github.com/drunk-cat423/skill-tool/blob/main/docs/verification.md)。当前机器切勿为调试切换代理或重启用户正在使用的实例。
