# 直播间弹幕系统 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 XhsDemo 首页新增直播列表入口，点击进入全屏直播间，核心为 CADisplayLink + View 复用池驱动的弹幕系统

**Architecture:** MVVM + Combine，完全沿用现有架构风格

**Tech Stack:** UIKit, SnapKit, Combine, CADisplayLink

---

### Task 1: Model 层
**Files:** Create `XhsDemo/Models/LiveRoom.swift`, `XhsDemo/Models/Danmaku.swift`

- [ ] 创建 LiveRoom 和 Danmaku 数据模型

### Task 2: ViewModel 层
**Files:** Create `XhsDemo/ViewModels/LiveRoomViewModel.swift`

- [ ] 创建 LiveRoomViewModel，包含 Combine Timer 弹幕流

### Task 3: View 层 - DanmakuLabel
**Files:** Create `XhsDemo/Views/DanmakuLabel.swift`

- [ ] 创建可复用弹幕标签

### Task 4: View 层 - DanmakuView（核心）
**Files:** Create `XhsDemo/Views/DanmakuView.swift`

- [ ] 创建弹幕渲染层（CADisplayLink + 轨道 + 复用池）

### Task 5: View 层 - LiveRoomBottomBar
**Files:** Create `XhsDemo/Views/LiveRoomBottomBar.swift`

- [ ] 创建直播间底部工具栏

### Task 6: Controller - LiveRoomViewController
**Files:** Create `XhsDemo/Controllers/LiveRoomViewController.swift`

- [ ] 创建直播间页面，绑定 ViewModel

### Task 7: Controller - LiveListViewController
**Files:** Create `XhsDemo/Controllers/LiveListViewController.swift`

- [ ] 创建直播列表横向滚动组件

### Task 8: 接入首页 Feed
**Files:** Modify `XhsDemo/Controllers/DiscoverFeedViewController.swift`

- [ ] 在首页顶部加入直播列表入口

### Task 9: 技术文档
**Files:** Create `LIVE_ROOM_TECH.md`

- [ ] 写面试级别的技术文档
