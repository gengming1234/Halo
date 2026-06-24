# 直播间弹幕系统 设计文档

**日期：** 2026-06-23  
**项目：** XhsDemo（小红书 iOS Demo）  
**作者：** Codewiz + 耿明

---

## 一、背景与目标

在现有 MVVM + Combine 架构的笔记 Feed 基础上，新增直播模块：

- **直播列表**：首页 Feed 顶部横向滚动栏，展示模拟直播间卡片
- **直播间**：全屏沉浸式页面，核心功能为弹幕系统

**面试价值目标：** 每个技术选型都有明确的理由，可以支撑 30 分钟技术对话。

---

## 二、功能范围（YAGNI）

**包含：**
- 首页 Feed 顶部横向直播列表（5 个模拟直播间）
- 全屏直播间页面（背景 + 主播信息 + 弹幕层 + 底部工具栏）
- 弹幕系统：CADisplayLink 驱动 + View 复用池 + 多轨道碰撞检测
- Combine Timer 模拟实时弹幕流（每 0.8s 随机一条）
- 观看人数实时跳动（Combine Timer 驱动）

**不包含：**
- 真实视频流播放（AVPlayer）
- 礼物动画
- 用户发弹幕输入框
- 网络层（MockWebSocket）

---

## 三、架构设计

### 分层结构

```
Model 层
  LiveRoom       — 直播间数据（id, title, host, viewerCount, coverColor）
  Danmaku        — 单条弹幕（id, text, color, speed）

ViewModel 层
  LiveRoomViewModel
    @Published danmakuStream: Danmaku   ← Combine Timer 每 0.8s 发一条
    @Published viewerCount: Int         ← Combine Timer 每 3s 随机波动
    func startStream() / stopStream()

View 层
  DanmakuLabel       — 可复用的弹幕单元（UILabel 子类）
  DanmakuView        — 弹幕渲染层（CADisplayLink + 轨道 + 复用池）
  LiveRoomBottomBar  — 底部工具栏（点赞、评论占位按钮）
  LiveRoomHeaderView — 顶部主播信息 + 在线人数

Controller 层
  LiveListViewController   — 直播列表（UICollectionView 横向）
  LiveRoomViewController   — 直播间页面（持有 ViewModel，bindViewModel）
```

### 数据流

```
Combine Timer
    ↓ @Published danmakuStream
LiveRoomViewController.sink
    ↓
DanmakuView.addDanmaku(_:)
    ↓
轨道分配器：选择尾部弹幕已离开起点的轨道
    ↓
复用池取出 DanmakuLabel（没有则新建）
    ↓
设置 text/color，frame.origin = (屏幕右边缘, 轨道Y)
    ↓
CADisplayLink 每帧：frame.origin.x -= danmaku.speed
    ↓
x + width < 0 → 回收进复用池
```

---

## 四、弹幕核心设计

### 轨道系统

- 固定 6 条轨道，每条高度 36pt，垂直分布在屏幕中部（避开顶部信息和底部工具栏）
- 每条轨道维护「上一条弹幕的尾部 x 坐标」
- 新弹幕进来时，选 `tailX < screenWidth - 30` 的轨道（即尾部已离开右边缘 30pt 以上），保证不重叠

### 复用池

```swift
class DanmakuView {
    private var reusePool: [DanmakuLabel] = []  // 回收池
    private var activeDanmakus: [DanmakuLabel] = []  // 屏幕上的弹幕

    func dequeue() -> DanmakuLabel {
        return reusePool.popLast() ?? DanmakuLabel()
    }
    func recycle(_ label: DanmakuLabel) {
        label.removeFromSuperview()
        reusePool.append(label)
    }
}
```

### CADisplayLink vs UIView.animate 选型理由

| 对比维度 | UIView.animate | CADisplayLink |
|---|---|---|
| 每帧控制 | ❌ 无法中途修改速度 | ✅ 每帧可调整 |
| 暂停弹幕 | ❌ 需要复杂的 layer 操作 | ✅ 暂停 displayLink 即可 |
| 百条同屏 | ❌ 动画组内存压力大 | ✅ 只更新 x 坐标，极轻量 |
| 面试可讲 | 一般 | ⭐ 技术深度高 |

---

## 五、MVVM 绑定设计

```swift
// ViewModel 暴露两个 Publisher
@Published private(set) var danmakuStream: Danmaku?   // 新弹幕到达
@Published private(set) var viewerCount: Int           // 观看人数

// VC 绑定
viewModel.$danmakuStream
    .compactMap { $0 }
    .receive(on: RunLoop.main)
    .sink { [weak self] danmaku in
        self?.danmakuView.addDanmaku(danmaku)
    }
    .store(in: &cancellables)

viewModel.$viewerCount
    .receive(on: RunLoop.main)
    .sink { [weak self] count in
        self?.headerView.updateViewerCount(count)
    }
    .store(in: &cancellables)
```

---

## 六、文件清单

| 路径 | 操作 |
|---|---|
| `XhsDemo/Models/LiveRoom.swift` | 新建 |
| `XhsDemo/Models/Danmaku.swift` | 新建 |
| `XhsDemo/ViewModels/LiveRoomViewModel.swift` | 新建 |
| `XhsDemo/Views/DanmakuLabel.swift` | 新建 |
| `XhsDemo/Views/DanmakuView.swift` | 新建 |
| `XhsDemo/Views/LiveRoomBottomBar.swift` | 新建 |
| `XhsDemo/Controllers/LiveListViewController.swift` | 新建 |
| `XhsDemo/Controllers/LiveRoomViewController.swift` | 新建 |
| `XhsDemo/Controllers/DiscoverFeedViewController.swift` | 修改（加直播列表入口） |
| `LIVE_ROOM_TECH.md` | 新建（技术文档） |

---

## 七、自查（Spec Self-Review）

- [x] 无 TBD / TODO 占位
- [x] 架构与功能描述一致
- [x] 范围聚焦，无过度设计
- [x] 所有类型/方法名一致
