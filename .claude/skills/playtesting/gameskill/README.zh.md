## 这个 skill 做什么

这个 skill 讲怎么组织一次游戏测试：把测试者分成 FTUE、核心玩家、硬核玩家三类，观察者全程不提示，把反馈分成 UX 摩擦、难度校准、功能信号三类，再配合遥测和漏斗流失率做判断。最后用一张观察矩阵把行为、说法、根因和改法记下来。

## 什么时候用

- 准备安排一轮游戏测试，要定测试者分组和观察规则
- 要把测试反馈分成 UX 问题、难度问题还是功能建议
- 要算关卡完成率和流失率，或整理观察矩阵

## 怎么装

下载本页的 ZIP，把 `playtesting/` 整个文件夹放进 agent 的 skills 文件夹：Claude Code 用 `.claude/skills/`，Codex、Gemini CLI、OpenCode 用 `.agents/skills/`，Cursor 用 `.cursor/skills/`，Copilot 用 `.github/skills/`，Windsurf 用 `.windsurf/skills/`，然后重启 agent。也可以直接对 agent 说：Install the skill from https://gameskill.dev/skills/playtesting/install.md

## 最小示例

`gameskill/examples/` 里是一个测试计划与观察矩阵的例子：`fixtures/plan_good.json` 是合格计划，`fixtures/matrix_good.json` 是合格矩阵，`fixtures/observations.json` 是原始观察记录；`playtesting.py` 是校验和汇总逻辑，`tests/run_rules.py` 跑检查。

## 我们怎么测的

总分 32/32。在 Python 3.13 下跑 20 项检查：合格计划通过，带引导性提问、缺 cohort、silent_observer 为 false、缺遥测的计划都被拒；完成率按 完成数/进入数×100 计算，流失率大于 30% 判为致命阻断，等于 30% 不算；合格矩阵通过，类别非法、player_id 非法、缺列的矩阵被拒；汇总按组计数，UX 摩擦和难度高的问题标为 critical，功能噪声不标 critical，结果按优先级排序；路由对测试类请求触发本 skill，对回归类请求跳过；静默观察 5 分钟不提示。结果在 `gameskill/test-report.json`。

## 和站内其他 skill 的区别

托管的 `ccgs-playtest-report` 是在 CCGS 框架里写报告模板；这个 skill 不依赖引擎，管的是测试前的计划（分组、静默观察、遥测）、漏斗流失率指标和问题矩阵。报告怎么写交给前者，这里只负责把测试组织好、把观察整理成可判断的结论。

## 搭配

- `ccgs-playtest-report`：把测试结果写成 CCGS 报告模板
- `game-design-gdd`：把难度和设计问题落回 GDD
- `game-feel`：调手感和反馈
