# 文档与代码同步维护流程

目标：确保“我改你就更新”，全工作区随时可查最新信息。

## 角色与职责
- 开发：提交功能/接口/结构变更后，同步更新对应 docs/* 文档
- Reviewer：CR 时检查对应文档是否同时更新

## 变更后更新清单（Checklist）
- 新增/修改接口：BACKEND.md（控制器）、API_MAP.md（映射）、FRONTEND.md（调用说明）
- 数据库表结构：DB_SCHEMA.md（结构）、相关 SQL 文件
- 新页面/路由：FRONTEND.md（路由）、API_MAP.md（映射）
- 架构或运行方式：ARCHITECTURE.md、DEV_ENV.md

## 约定
- 所有 docs/ 以仓库为准，不分支外扩散
- 文档精简为主，细节以代码为源，文档给“如何找到”与“联调要点”

## 自动化（建议）
- CI 检查：若检测到 controller/mapper/xml 变化而未触发 docs/API_MAP.md 变更，给予提示
- Pre-commit 钩子：提示填写变更摘要

