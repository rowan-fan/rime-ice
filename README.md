# 雾凇拼音 · 语言学习分支

本分支 `personal/translation-annotation` 基于 [雾凇拼音](https://github.com/iDvel/rime-ice)，为 macOS 鼠须管的全拼方案 `rime_ice` 增加中文候选的英文释义。雾凇仍负责候选、排序、词频及其他输入功能；释义仅作为候选注释显示，不会提交到输入文本。

## 安装与使用

1. 安装[鼠须管](https://rime.im/)，备份现有 `~/Library/Rime`，将本分支的文件放入该用户目录，然后重新部署。已有 Rime 目录时不要直接覆盖用户词库或清空目录。
2. 选择「雾凇拼音」全拼方案，输入 `kaifa` 等拼音。词表命中的「开发」等候选会在原注释后显示英文。
3. 按 <kbd>F4</kbd> 打开方案选单，切换「译关 / EN」。默认开启；未命中词条仍正常输入。

目前只给 `rime_ice` 加了 patch。若使用双拼，应在实际使用的 `<schema_id>.custom.yaml` 中加入同样的开关和 filter，再重新部署；不要直接修改上游 `*.schema.yaml`。雾凇的其他安装方式和原版功能见[上游说明](https://github.com/iDvel/rime-ice#readme)。

## 方案始末

最初目标是模仿[青简](https://github.com/qingjian-team/qingjian)的候选词辅助语言释义，而不是在输入时调用在线翻译。第一阶段只实现「中文候选 → 英文释义」；整句翻译、日语及其他语言尚未实现。设计选择如下：

- `rime_ice.custom.yaml` 通过 `switches/+` 增加 `translation_annotation` 开关，通过 `engine/filters/+` 追加独立 Lua filter，不复制上游完整 filter 列表。
- `lua/translation_annotation.lua` 在初始化时一次加载本地 TSV；输入时按候选 `text` 精确查表，只追加 `get_genuine().comment`，保留原注释，不改变文字或顺序。不命中或缺少词表时照常输出候选，不访问网络。
- filter 位于现有列表末尾（`uniquifier` 之后）。简繁转换后的繁体候选可能因词表使用简体键而不命中；当前不做归一化。
- 词表较大，Lua 测试环境加载约 0.24 秒、使用约 26.8 MiB；这些数字不是鼠须管实际内存占用，增加语言前应重新测量。

## 词表来源与格式

当前文件 `glossary/glossary-en.tsv` 来自青简仓库的 `assets/glossary/glossary-en.tsv`，固定来源提交为 `40e3e550425466e6ba9c0a14de3a77ed04862799`，共 232,213 条数据。青简在[词表说明](https://github.com/qingjian-team/qingjian/blob/main/assets/glossary/README.md)中注明英、日释义由其 `tools/gloss-gen` 使用 LLM 离线生成；词表按 GPL-3.0-or-later 发布。仓库内的 `glossary/SOURCE.txt` 记录了来源、版本与许可。机器生成的释义可能有错译，不应当作权威词典。

当前 Lua 读取 UTF-8、LF 换行的 TSV：`中文词<TAB>释义1[<TAB>释义2...]`。例如：

```text
开发	v. develop	v. exploit
```

第一列是与候选文本完全一致的键；后续列显示时用 ` / ` 连接。空行、以 `#` 开头的注释行跳过；同一词重复出现时保留首条。更新词表时应核对编码、列格式、重复词、来源提交与再分发许可，并同步更新 `SOURCE.txt`。

## 增加辅助语言

不要仅把新 TSV 放入 `glossary/`：当前 Lua 路径和 `译关 / EN` 开关都写死为英文。后续 Agent 应按顺序处理：

1. 选定可再分发的本地词表。青简当前提供 `glossary-ja.tsv` 和 `glossary-es.tsv`；意大利语不在当前青简词表目录中，需另找合法来源或自行生成。保留原始许可与来源提交，分别记录到 `glossary/SOURCE.txt`。
2. 校验并放置为 `glossary/glossary-<语言码>.tsv`，至少保证中文键和一列非空释义。若来源格式不同，先离线转换为本项目的 TSV，不在按键处理路径解析复杂格式。
3. 将 Lua 从固定 `glossary-en.tsv` 改为按目标语言选择词表；设计互斥的「关闭 / 一种辅助语言」状态，避免候选同时显示多门语言。优先只加载当前语言，切换时再加载或缓存，并测量切换时间和内存。
4. 更新实际使用方案的 `*.custom.yaml`、`others/script/tests/translation_annotation.lua` 和本文件。验证开关切换、各语言命中与未命中、原注释保留、候选顺序、缺表降级及输入延迟。不要同步请求翻译 API。

修改配置或 Lua 后运行 `make -C others/script lint` 和 `lua5.4 others/script/tests/translation_annotation.lua "$PWD"`；修改雾凇词库或生成源时另运行 `make -C others/script build`。重新部署鼠须管后还需实际检查候选窗。关于文件归属和仓库规则，见 `AGENTS.md` 与 `AGENT.md`。

## 上游同步

本 fork 的 `main` 保存上游内容及同步工作流；个人功能留在 `personal/translation-annotation`。GitHub Actions 每月 1 日或手动触发时，将上游合并到 `main`，再合并到个人分支；无变更时跳过构建，有冲突或检查失败时停止推送。本分支重写了 README，上游也修改它时可能需要人工解决冲突，勿覆盖此分支的来源与扩展说明。远端更新不会自动部署到本机：在当前个人分支确认工作区干净后运行 `git pull --ff-only`，再重新部署鼠须管。详见 `AGENT.md`。
