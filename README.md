# Orca 开发环境恢复手册

换 Windows 主机或换 Agent 时，从这里恢复 Orca 桌面端、项目入口、模型渠道和多 Agent 编排。恢复基线是 2026-11-25 验证过的 Orca **v1.4.274**。本仓库提供说明和 PowerShell 工具，安装器从 Orca 官方 Release 获取。

## 换机时先做什么

| 顺序 | 要恢复的能力 | 操作 |
| --- | --- | --- |
| 1 | Agent 的浏览器、桌面操作和个人规则 | 按 [skill-tool](https://github.com/drunk-cat423/skill-tool) 恢复目标 Agent。先预览，核对旧配置差异后再应用。 |
| 2 | Orca 桌面端和 CLI | [安装、项目注册和调试](docs/windows.md)。只使用 Orca 时做到安装和项目注册即可。 |
| 3 | 官方 Codex 与 Claude Chat | [恢复 Provider](docs/providers.md)。官方 Codex 登录 ChatGPT，Claude Chat 默认接百炼。其他渠道按需要恢复。 |
| 4 | 多 Agent 编排 | [编排操作与验收](docs/orchestration.md)。先检查 CLI 和技能，再按需执行只读演练。 |

需要恢复 T3 Code 本身时，使用 [y3code 的新机指南](https://github.com/drunk-cat423/y3code/blob/main/docs/bootstrap-codex.md)。只装 Orca 也可以按 Provider 文档创建独立本机配置。

### 给新 Agent 的启动提示

> 从 https://github.com/drunk-cat423/orca_y.git 恢复这台 Windows 主机上的 Orca 开发环境。先读 README.md 和 AGENTS.md，检查 Git、PowerShell、Orca、Codex、Claude Code、Ego Lite 和 Cua Driver 的现状，继续完成缺失步骤。优先恢复官方安装版、现有项目入口、官方 Codex 和百炼 Claude Chat，再按需恢复其他渠道和编排。保留现有项目、配置和任务历史。登录时启动官方授权流程让我完成。最终运行 scripts/Test-OrcaSetup.ps1，报告哪些是命令检查、哪些在实际界面或模型调用中验证过。有凭证、覆盖现有配置或计费步骤时，保留已完成的工作并说明需要我处理的那一步。

### 快速检查

从仓库根目录运行：

```powershell
powershell.exe -NoProfile -File .\scripts\Test-OrcaSetup.ps1
```

检查器只读检查本机 Orca Runtime、已发现的 Agent 和项目清单。OAuth 登录、Provider 能否实际回复、编排 Worker 是否回报，分别按对应文档验收。

## 这份基线的验证范围

- 签名有效的 Windows 安装包、CLI 和 Runtime 可用，Codex、Claude 和 Goose 可被发现。
- T3 的四个正式项目按原路径注册，三个独立子仓库没有单列，历史会话仍由 T3 管理。迁移时核对了侧栏，换机后可在检查器输出中复核 `hiddenAt`。
- 四条自定义 Claude Code 快捷命令做过本机凭证检查。百炼在 Orca 原生 Claude 模型目录中显示 `deepseek-v4.1-flash-1017` 为默认模型。原生聊天没有发送付费探测。
- 通过已安装的 Orca 验证过编排 Run、任务及依赖持久化。这次恢复整理未做源码构建、全新主机安装或 Orca Worker 端到端派工演练。

日期、版本和模型仅用于复现。换机时以目标主机真实路径、权限和工具返回为准。
