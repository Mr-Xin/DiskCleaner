# 贡献指南

感谢你愿意为 DiskCleaner 出一份力。

## 开发环境

- macOS + Xcode（建议使用最新正式版）
- 核心逻辑包 `DiskCleanerCore` 也可单独用命令行开发：`cd DiskCleanerCore && swift test`

## 提交流程

1. Fork 仓库并新建分支（如 `feature/treemap`、`fix/scan-crash`）。
2. 保持改动聚焦，一个 PR 只做一件事。
3. 为 `DiskCleanerCore` 中的新逻辑补充单元测试。
4. 确保 `swift test`（在 `DiskCleanerCore` 目录下）通过。
5. 提交 PR，并在描述中说明动机与做法。

## 代码约定

- 业务逻辑尽量放进 `DiskCleanerCore`，保持 UI 与逻辑解耦。
- 任何"删除文件"的代码都必须先经过 `ProtectedPaths` 校验。
- 默认走"移到废纸篓"，不要默认永久删除。
- 涉及破坏性操作的功能，务必给用户明确的确认与可解释信息。

## 安全相关

DiskCleaner 会删除用户文件，安全性高于一切。涉及删除、权限、系统路径的改动会被重点审查，请在 PR 中详细说明。
