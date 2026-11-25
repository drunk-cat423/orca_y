# 多 Agent 编排实操

## 恢复入口

在安装版 Orca 中查看「设置 → 智能体编排」。若目标 Agent 没识别到技能，按该页说明安装并在新聊天中检查。先读当前 Orca 自带的指南，版本不同可能有命令差异：

```powershell
orca skills get orca-cli
orca skills get orchestration
orca agent installed --environment local --json
orca orchestration worker-list --environment local --json
```

编排面板在 v1.4.274 仍有实验设置，命令可达、可视面板可用与 Worker 真能回报分别检查。基线用 CLI 验证了任务数据及依赖，不需要先开实验面板。

## 在主聊天里交代任务

打开项目的目标工作区，点「＋ → Codex Chat」。主聊天负责分工、收结果和验收。给一个只读试跑任务，例如：

> 用 Orca 的 /orchestration 在当前工作区并行派两个 Worker。Codex 查看上传页面的错误处理，Claude 跟踪上传接口失败时的返回。各给文件和行号、可复现路径及建议。两边只读。结果通过 Orca 发回主聊天，你负责核对两边结论。发现问题先报告，完成后保留聊天以便我检查。

只读任务可共用工作区。需要并行写代码时，给不同 Worker 各自的 Git 子工作区和文件范围。子工作区从指定 Git 基线创建，当前目录里的未提交修改需要另行交接。告诉主控收集分支、改动、验证和阻塞。主控核对并在用户授权范围内处理集成，不安排 Worker 再委派。

## 看进度与追问

Run 是一组任务及主控收件箱。Task 是具体待办，Dispatch 是一次实际派工。主控调用 `worker-start` 交付任务，Worker 用 `worker_done` 报结果。主聊天会收到回报或提问。使用 `--keep-open` 让 Worker 的聊天保留供继续查看。

```powershell
orca orchestration worker-list --environment local --json
orca orchestration worker-show --dispatch $dispatchId
orca orchestration worker-read --dispatch $dispatchId --limit 50
```

由主控发追问时，用 `orca orchestration send --to dispatch:<id>`。Orca 会投递给对应 Worker。无需回报的完整交接，可按 `orca skills get orca-cli` 的 handoff 方式新开 Agent。

## 调试与验收

- **`no_active_sender_terminal`**：执行写操作的普通外部 PowerShell 缺少 Orca 会话身份。回到目标项目的 Orca 聊天或 Orca 管理的终端执行。外部 shell 可做只读检查。
- **依赖没生效**：从有身份的 Orca 终端创建测试 Run 和 Task A，再用 `--deps '["<Task A ID>"]'` 创建 Task B。用 `orca orchestration task-list --run <Run ID> --full --json` 检查 B 确实记录依赖且为 `pending`。Windows PowerShell 传参可能丢失 JSON 内部引号，检查实际持久化结果；必要时按当前 CLI 的指引使用 PowerShell 7。
- **Worker 没回报**：从 dispatch 读取状态与输出，按启动回执中的 `next` 或恢复说明处理。保留失败状态。授权允许的真机试跑应能看到 Worker 启动、带 Task/Dispatch ID 的回报，以及主控汇总。

前两项属于 CLI 和元数据验收。派真的 Worker 会调用所选 Agent，只有在用户授权使用对应套餐时进行。 [Orca 上游编排文档](https://github.com/stablyai/orca/blob/v1.4.274/docs/site/content/docs/cli/orchestration.mdx)
