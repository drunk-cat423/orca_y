# 恢复 Codex、Claude Chat 和可选渠道

## 官方 Codex

按 [Codex 官方文档](https://developers.openai.com/codex/cli/) 安装 CLI，使用 `codex login` 启动 ChatGPT 登录，用户在官方授权页面完成。用 `codex login status` 和 `orca agent installed --environment local --json` 验收。新开 **Codex Chat** 使用官方配置。

## 四条 Claude Code 渠道

按 [Claude Code 官方安装说明](https://code.claude.com/docs/en/setup) 装好 CLI。恢复渠道有两种来源：

- **有 T3 Code**：先按 [T3 恢复指南](https://github.com/drunk-cat423/y3code/blob/main/docs/bootstrap-codex.md) 恢复需要的 Provider 和目标主机凭证。此处复用各 Provider 的 `settings.json`。
- **只用 Orca**：在本机的 `%LOCALAPPDATA%\Orca\provider-settings\<目录名>\settings.json` 建配置。把供应商提供的令牌直接填入本机文件，避免粘贴到聊天、剪贴板记录或命令行参数。

| 快捷命令 | 脚本参数 `-Provider` | 目录名 | 2026-11-25 的默认模型 |
| --- | --- | --- | --- |
| Claude Code · 阿里云百炼 | `bailian` | `bailian` | `deepseek-v4.1-flash-1017` |
| Claude Code · DeepSeek 官方 | `deepseek_official` | `deepseek-official` | `deepseek-flash[1m]` |
| Claude Code · RedRomance | `redromance_claude` | `redromance-claude` | `claude-opus-5-5` |
| Claude Code · Codex 订阅桥接 | `codex_subscription_claude` | `codex-subscription-claude` | `gpt-6.2-sol` |

对于没有现成配置的渠道，最小的 Claude Code 文件结构如下。按供应商文档填实际端点、模型和凭证：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "<供应商的 Anthropic 兼容端点>",
    "ANTHROPIC_AUTH_TOKEN": "<在本机私下填写>",
    "ANTHROPIC_MODEL": "<账号可用的模型 ID>"
  }
}
```

本机只需新建所用渠道。已有配置可能还包含 `ANTHROPIC_DEFAULT_OPUS_MODEL`、`ANTHROPIC_DEFAULT_SONNET_MODEL`、`ANTHROPIC_DEFAULT_HAIKU_MODEL` 和 `CLAUDE_CODE_SUBAGENT_MODEL`，它们控制别名和子 Agent 模型。复用原渠道配置可保留这些映射。单独新建时按当前套餐确定别名。百炼与 RedRomance 的端点以目标账户原有配置或供应商指引为准，DeepSeek 官方 Claude Code 入口可查 [官方接入指南](https://api-docs.deepseek.com/guides/anthropic_api)。

### 将百炼设为原生 Claude Chat 默认

1. 在 Orca「设置 → 智能体」展开 **Claude**。先读取已有的启动参数和环境变量，保留其他配置。
2. 在「参数」加入 `--settings "百炼 settings.json 的绝对路径"`。使用刚恢复的 T3 百炼配置或独立本机配置。
3. 在「环境变量」设 `CLAUDE_CONFIG_DIR` 为独立的本机目录，例如 `%LOCALAPPDATA%\Orca\provider-sessions\bailian` 展开后的绝对路径。若选中了单独的 Claude 托管账号，先确认账号配置目录的优先级。密钥继续由 Claude 从设置文件读取。
4. 新开「＋ → Claude Chat」，检查模型目录的默认项。基线识别到 **DeepSeek V4.1 Flash 1017**。模型目录与 API 实际调用分别验收。

Orca v1.4.274 的 Claude 按 Agent 使用同一套启动配置。要在新 Claude Chat 中切换供应商，需要修改这套配置。现有聊天可能带有原账号和上下文。

### 添加可任选的四条快捷命令

将此仓库留在目标机稳定路径。在 Orca **设置 → 快捷命令** 中逐条添加，类型选「终端命令」，范围选「全局」，启用附加 Enter。以百炼为例，替换脚本绝对路径和上表的 Provider 值：

```powershell
powershell.exe -NoProfile -File "D:\dev\orca_y\scripts\Start-ClaudeProvider.ps1" -Provider bailian
```

脚本先找独立本机目录，然后查 `%USERPROFILE%\.t3\userdata\provider-homes` 中同名目录。也可传 `-ConfigRoot` 指定另一个根目录。每条渠道新开的会话存在自己的本机目录。从项目标签栏的「快捷命令」启动时，Claude Code 在项目当前目录里开终端会话。

在启动真实会话前可以检查本机配置和认证入口：

```powershell
powershell.exe -NoProfile -File .\scripts\Start-ClaudeProvider.ps1 -Provider bailian -Check
```

`-Check` 不发送模型消息。CLI 识别到本机凭证并不能证明上游接受请求。实际回复和费用需要另外验证。

## 可选的 Codex 订阅桥接

这条渠道用于在 **Claude Code** 里接 Codex 订阅。上游是第三方 [raine/claude-code-proxy v0.1.49](https://github.com/raine/claude-code-proxy/releases/tag/v0.1.49)，由用户确认是否恢复。基线桥接仅监听 `127.0.0.1:18787`，和官方 Codex CLI 采用各自的 OAuth 登录。

1. 从对应版本 Release 下载 Windows 架构的归档及其 SHA-256 文件，先比对哈希，再解压到独立本机目录。如果旧 T3 环境已经恢复了该桥接及其启动脚本，可继续使用经过核对的本机脚本。
2. 按供应商说明在隔离的 `CCP_CONFIG_DIR` 授权。基线用 `claude-code-proxy.exe codex auth login` 启动登录流程。用户自己完成授权。启动服务时配置 `CCP_BIND_ADDRESS=127.0.0.1` 和 `serve --no-monitor --port 18787`，将桥接别名的后端配置为 Codex。按上游说明核对当前选项。
3. 用 `Invoke-WebRequest -UseBasicParsing http://127.0.0.1:18787/healthz` 核对服务就绪。重启后检查进程和端口，按需启动自己的桥接。
4. 让 `codex-subscription-claude/settings.json` 指向该本机地址，用脚本的 `-Check` 检查。保留独立令牌和模型设置。Astra 只用于只读顾问，最高 Medium。在该渠道的 Claude `settings.json` 中保留顶层 `"modelSettings": {"gpt-6.2-astra": {"maxEffortLevel": "medium"}}`，便于在 Claude 会话内切换模型时遵守同一规则。桥接不要固定全局模型或强度，才能按会话选择。

打开官方 Codex Chat 继续使用官方登录。桥接的 `/healthz` 表示本机可达，后端授权和模型回复需要分别验证。
