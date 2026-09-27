# 仓库管理与编码规范

本文件补充 `AGENTS.md`；如有冲突，以 `AGENTS.md` 为准。此目录同时是 macOS 鼠须管的用户配置目录，Git 操作可能直接影响输入法。

## 分支与同步

- `upstream` 指向 `iDvel/rime-ice`，`origin` 指向 `rowan-fan/rime-ice`。
- `main` 保持与上游一致，不在其上提交个人功能；个人定制使用长期分支 `personal/translation-annotation`，并推送到 `origin`。
- 在 GitHub 使用 Sync fork 更新 `origin/main`。本机保持个人分支为当前分支，先确认工作区干净，再执行 `git fetch origin`、`git merge origin/main`；解决冲突、校验并确认输入法可用后，执行 `git push`。
- 不在使用中的 `~/Library/Rime` 为同步而切换到 `main`；确需检查其他分支时，使用独立 worktree。禁止强制推送或重写已共享的个人分支历史。
- 合并前备份用户目录。发生冲突时优先保留上游文件的更新，将个人功能留在独立配置和脚本中；不要为解决冲突删除文件或覆盖用户数据。

## 定制边界

- 语言学习功能只在实际使用方案的 `<schema_id>.custom.yaml`、独立的 `lua/translation_annotation.lua` 和 `glossary/` 中实现；不修改上游 `*.schema.yaml` 或现有 Lua 文件。
- 用 `.custom.yaml` 的增量 patch 添加开关和 filter，不复制上游完整配置；已有 `patch:` 时合并节点，不重复创建顶层键。
- Lua filter 只追加候选 `comment`，不改 `text`、排序或原有注释；词表在初始化时本地加载，按键处理路径不得访问磁盘或网络。缺失词表时仍须正常输入。
- `.gitignore` 默认忽略 `*.custom.yaml`：确认内容后，用 `git add -f <schema_id>.custom.yaml` 显式纳入个人分支。第三方 glossary 入库前核对许可；不宜再分发时仅保留本地数据，不强制提交。
- 不提交 `installation.yaml`、`user.yaml`、`*.userdb/`、`build/`、`sync/` 等本机状态和生成缓存。不修改 `README.md`，不删除任何文件。

## 编码、验证与提交

- 遵循 `AGENTS.md` 的文件归属、词频和禁改文件规则；改动聚焦，沿用现有 YAML、Lua 风格，避免无关格式化。
- 修改词库或映射源后运行 `make -C others/script/ build`；修改配置或 Lua 后运行 `make -C others/script/ lint`。构建警告和错误须先处理。个人 `.custom.yaml` 还须检查 YAML 合并结果并在鼠须管重新部署后实测。
- 至少验证候选文字和顺序不变、原注释保留、开关生效、未命中词可输入，及常用输入无明显延迟。记录无法运行的检查及原因。
- 提交前检查 `git status --short` 和暂存差异，只提交本次相关文件。提交信息使用 Conventional Commits，描述用中文；破坏性变更按 `AGENTS.md` 更新变更日志。
