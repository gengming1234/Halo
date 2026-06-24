# 直播间 + 弹幕系统技术文档

> XhsDemo · 直播功能模块 · 面试级技术说明

---

## 目录

1. [功能概述](#1-功能概述)
2. [整体架构（MVVM 数据流）](#2-整体架构mvvm-数据流)
3. [文件结构](#3-文件结构)
4. [弹幕系统设计](#4-弹幕系统设计)
   - 4.1 [选型理由：CADisplayLink vs UIView.animate](#41-选型理由cadisplaylink-vs-uiviewanimate)
   - 4.2 [View 复用池](#42-view-复用池)
   - 4.3 [轨道碰撞检测算法](#43-轨道碰撞检测算法)
5. [Combine 数据绑定](#5-combine-数据绑定)
6. [接入首页 Feed](#6-接入首页-feed)
7. [生命周期管理](#7-生命周期管理)
8. [面试常见问题与回答](#8-面试常见问题与回答)

---

## 1. 功能概述

本模块实现一个**观众视角的直播间**，包含：

- 首页 Feed 顶部嵌入横向滚动的**直播列表**（LiveListViewController）
- 点击直播间卡片全屏进入**直播间**（LiveRoomViewController）
- 全屏页面展示主播信息、实时观看人数、**飞行弹幕**
- 底部工具栏：评论输入框 + 点赞动画

---

## 2. 整体架构（MVVM 数据流）

```
┌─────────────────────────────────────────────┐
│              LiveRoomViewController          │
│  viewDidAppear  ──────►  vm.startStream()   │
│  viewDidDisappear  ───►  vm.stopStream()    │
│                                             │
│  bindViewModel():                           │
│    $danmaku  ──►  danmakuView.addDanmaku()  │
│    $viewerCount  ──►  headerView.update()   │
└──────────────────┬──────────────────────────┘
                   │  @Published 属性
                   ▼
┌─────────────────────────────────────────────┐
│              LiveRoomViewModel               │
│                                             │
│  danmakuTimer（0.8s）── Danmaku.random() ──►│ @Published danmaku
│  viewerTimer（3.0s）─── viewerCount ±波动 ──►│ @Published viewerCount
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│                DanmakuView                   │
│                                             │
│  addDanmaku(danmaku)                        │
│    └─► availableTrack()  轨道碰撞检测        │
│    └─► dequeue()         从复用池取 Label    │
│    └─► addSubview + 记录 trackTailX         │
│                                             │
│  CADisplayLink.tick()  每帧执行             │
│    └─► label.frame.origin.x -= speed        │
│    └─► label.maxX < 0 → recycle()          │
│    └─► updateTrackTailX()                   │
└─────────────────────────────────────────────┘
```

**数据流方向（严格单向）：**

```
Model（LiveRoom / Danmaku）
    ↓ 初始化 / 工厂方法
ViewModel（LiveRoomViewModel）
    ↓ @Published 属性变更
ViewController（LiveRoomViewController）
    ↓ 调用 View 的方法
View（DanmakuView / LiveRoomHeaderView）
```

ViewController **不直接修改 Model**，Model 的变更全部由 ViewModel 发起，VC 只做"接收通知 → 调用 UI"的协调者。

---

## 3. 文件结构

```
XhsDemo/
├── Models/
│   ├── LiveRoom.swift          # 直播间数据模型 + mockData
│   └── Danmaku.swift           # 弹幕模型 + presetTexts + random() 工厂
├── ViewModels/
│   └── LiveRoomViewModel.swift # @Published 属性 + Timer 驱动
├── Views/
│   ├── DanmakuLabel.swift      # 可复用弹幕单元（UILabel 子类）
│   ├── DanmakuView.swift       # 核心弹幕渲染层（CADisplayLink + 复用池 + 轨道）
│   └── LiveRoomBottomBar.swift # 底部工具栏（点赞动画 + 评论框）
└── Controllers/
    ├── LiveRoomViewController.swift  # 全屏直播间 + LiveRoomHeaderView
    └── LiveListViewController.swift  # 横向直播列表 + LiveRoomCell
```

---

## 4. 弹幕系统设计

### 4.1 选型理由：CADisplayLink vs UIView.animate

| 维度 | `UIView.animate` | `CADisplayLink` |
|------|-----------------|-----------------|
| 暂停/恢复 | 需要记录剩余时间，重启动画，复杂 | `displayLink.isPaused = true` 一行搞定 |
| 动态变速 | 无法中途改变速度 | 每帧读取 `danmaku.speed`，随时可变 |
| 大量对象 | 每个 label 各自持有动画，CPU 波峰明显 | 单一 `displayLink` 驱动所有弹幕，调度均匀 |
| 内存 | 动画完成回调销毁 label，频繁 alloc/dealloc | 配合复用池，对象数量上限稳定 |
| 碰撞检测 | 动画中途读取 `layer.presentationLayer.frame` 有偏差 | `label.frame` 即实时位置，精确 |

**结论**：弹幕场景需要「精确位置 + 可暂停 + 大量对象」，CADisplayLink 是唯一合理选择。

### 4.2 View 复用池

类比 `UITableView` 的 cell 复用机制，弹幕飞出屏幕左边缘后不销毁，而是放入复用池等待下次使用：

```
屏幕右边缘                                屏幕左边缘
    │  弹幕 A ────────────────────────►  │  frame.maxX < 0
    │                                    │       │
    │                                    │    recycle(A)
    │                                    │    A.prepareForReuse()
    │                                    │    reusePool.append(A)
    │                                    │
    │  新弹幕 B 到来                      │
    │  dequeue() → 从 reusePool.popLast()│
    │  configure(with: newDanmaku)        │
    │  addSubview(B)                      │
```

**核心代码：**

```swift
// DanmakuView.swift

private func dequeue() -> DanmakuLabel {
    // 复用池有对象直接复用，否则新建
    if let recycled = reusePool.popLast() { return recycled }
    return DanmakuLabel()
}

private func recycle(_ label: DanmakuLabel) {
    activeDanmakus.removeAll { $0 === label }
    label.prepareForReuse()   // 清空 text / danmaku 引用
    label.removeFromSuperview()
    reusePool.append(label)
}
```

**效果**：系统稳定后，`reusePool` + `activeDanmakus` 的总数约等于屏幕上同时可见的弹幕数（约 10~20 个），不再随时间线性增长。

### 4.3 轨道碰撞检测算法

**问题**：如果弹幕随机分配 Y 坐标，快弹幕会追上慢弹幕造成重叠。

**解决方案**：轨道 + 尾部 x 坐标追踪。

```
轨道 0:  ░░░[弹幕B]──────────────────────░░░░  尾部 x = 280
轨道 1:  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  尾部 x = 0   ← 可用！
轨道 2:  ░░[弹幕A]───────────────────────░░░░  尾部 x = 320
轨道 3:  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  尾部 x = 0   ← 可用！
轨道 4:  ░░░░░[弹幕C]────────────────────░░░░  尾部 x = 260
轨道 5:  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  尾部 x = 0   ← 可用！
                                        │
                             屏幕宽度 375pt
```

**关键逻辑：**

```swift
// DanmakuView.swift

/// 找可用轨道：尾部 x < (屏幕宽 - 30pt 安全边距)
private func availableTrack() -> Int? {
    let threshold = bounds.width - 30
    let candidates = trackTailX.enumerated().filter { $0.element < threshold }
    // 优先选等待最久的轨道（尾部 x 最小的）
    return candidates.min(by: { $0.element < $1.element })?.offset
}

/// 每帧更新轨道尾部 x：遍历所有活跃弹幕，反推轨道索引，取最大 maxX
private func updateTrackTailX() {
    var newTailX = Array(repeating: CGFloat(0), count: trackCount)
    for label in activeDanmakus {
        let trackIndex = trackIndexFor(label: label)
        if trackIndex >= 0 && trackIndex < trackCount {
            newTailX[trackIndex] = max(newTailX[trackIndex], label.frame.maxX)
        }
    }
    trackTailX = newTailX
}
```

**当所有轨道都堵塞时（`availableTrack()` 返回 `nil`），直接丢弃当次弹幕**，保护 UI 不卡顿，同时保证轨道安全。

---

## 5. Combine 数据绑定

### ViewModel 侧（生产者）

```swift
// LiveRoomViewModel.swift

@Published private(set) var danmaku: Danmaku?
@Published private(set) var viewerCount: Int

func startStream() {
    danmakuTimer = Timer.publish(every: 0.8, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
            self?.danmaku = Danmaku.random()   // @Published 触发 send()
        }
}
```

`@Published` 的本质：编译器在属性的 `willSet` 中调用 `subject.send(newValue)`，每次赋值都会通知所有订阅者。

### ViewController 侧（消费者）

```swift
// LiveRoomViewController.swift

private func bindViewModel() {
    viewModel.$danmaku
        .compactMap { $0 }              // 过滤 nil（初始值）
        .receive(on: RunLoop.main)      // 切换到主线程
        .sink { [weak self] danmaku in
            self?.danmakuView.addDanmaku(danmaku)
        }
        .store(in: &cancellables)       // 绑定到 VC 生命周期

    viewModel.$viewerCount
        .receive(on: RunLoop.main)
        .sink { [weak self] count in
            self?.headerView.updateViewerCount(count)
        }
        .store(in: &cancellables)
}
```

**`cancellables` 的作用**：`AnyCancellable` 持有订阅令牌，`Set<AnyCancellable>` 随 VC 一起销毁，订阅自动取消，**防止内存泄漏和订阅悬挂**。

### 操作符链解析

| 操作符 | 作用 |
|--------|------|
| `.dropFirst()` | 跳过初始值（`@Published` 在初始化时就会 emit 一次） |
| `.compactMap { $0 }` | 过滤 `Optional` 中的 `nil`，等价于 `filter { $0 != nil }.map { $0! }` |
| `.receive(on: RunLoop.main)` | 将后续操作切换到主线程执行（UI 更新必须在主线程） |
| `.sink { }` | 订阅终端，执行副作用（更新 UI） |
| `.store(in: &cancellables)` | 将 `AnyCancellable` 存入集合，交由集合管理生命周期 |

---

## 6. 接入首页 Feed

`LiveListViewController` 通过 **Child ViewController** 模式嵌入 `DiscoverFeedViewController` 顶部。

**正确的 Child VC 三步走：**

```swift
// DiscoverFeedViewController.swift

private func setupLiveList() {
    // 1. 建立父子关系（影响生命周期回调传递）
    addChild(liveListVC)

    // 2. 把子 VC 的 view 加入视图层级
    view.addSubview(liveListVC.view)
    liveListVC.view.snp.makeConstraints { make in
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        make.leading.trailing.equalToSuperview()
        make.height.equalTo(liveListHeight)   // 固定 136pt
    }

    // 3. 通知子 VC 已完成迁移（触发 didMove 回调）
    liveListVC.didMove(toParent: self)
}
```

**为什么不直接 `addSubview` 直播列表的 `collectionView`？**

Child ViewController 模式确保子 VC 能正确接收 `viewWillAppear`、`viewDidAppear`、`viewWillDisappear` 等生命周期回调，从而正确管理自己的资源（如 timer、displayLink）。直接 `addSubview` 会让这些回调断链。

**布局层级（从上到下）：**

```
safeAreaLayoutGuide.top
    ↓
LiveListVC.view（height: 136pt）── 直播列表
    ↓
secondaryScrollView（height: 44pt）── 分类 Tab
    ↓ offset: 1pt（分割线）
collectionView（fill remaining）── 笔记瀑布流
```

---

## 7. 生命周期管理

### CADisplayLink 的启停

```swift
// LiveRoomViewController.swift

override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.startStream()       // 启动 Timer
    danmakuView.startDisplayLink() // 启动每帧回调
}

override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    viewModel.stopStream()        // 取消 Timer（释放 AnyCancellable）
    danmakuView.stopDisplayLink() // invalidate DisplayLink，防止 retain cycle
}
```

**为什么不在 `viewWillAppear/viewWillDisappear`？**

- `viewDidAppear`：确保视图已完成布局（`bounds` 正确），CADisplayLink 首帧计算轨道坐标准确。
- `viewDidDisappear`：确保 dismiss 动画已完成，动画过程中弹幕继续播放，用户体验更流畅。

### CADisplayLink retain cycle 风险

`CADisplayLink(target: self, ...)` 会强引用 `target`，如果不 `invalidate()`，则 `DanmakuView` 永远不会被释放。

本项目在 `stopDisplayLink()` 中调用 `displayLink?.invalidate()`，并置为 `nil`，断开强引用链。

---

## 8. 面试常见问题与回答

**Q1：为什么用 CADisplayLink 而不是 UIView.animate？**

> CADisplayLink 与屏幕刷新率同步（60fps 或 120fps），每帧精确控制每个弹幕的位置偏移。相比之下，UIView.animate 的动画一旦开始就无法精确暂停或动态变速；大量并发动画也难以统一调度。此外，配合复用池，CADisplayLink 方案下屏幕上的 UILabel 总数是固定上限，内存非常稳定。

---

**Q2：弹幕的复用池和 UITableView 的 cell 复用有什么区别？**

> 思路相同，但触发时机不同。UITableView 的复用在 cell 滚出屏幕时由框架自动触发，开发者通过 `dequeueReusableCell` 取用。弹幕复用池由我们自己实现：在 CADisplayLink 的每帧回调中检测 `label.frame.maxX < 0`（飞出左边缘），主动调用 `recycle()` 将 label 从 `activeDanmakus` 移除并加入 `reusePool`。下次 `addDanmaku()` 时优先从池中取，避免频繁 `alloc/dealloc`。

---

**Q3：轨道碰撞检测算法的时间复杂度是多少？**

> - `availableTrack()`：遍历 6 条轨道的 `trackTailX` 数组，O(k)，k = 轨道数（常数 6），即 O(1)。
> - `updateTrackTailX()`：遍历屏幕上所有活跃弹幕，O(n)，n 为当前飞行弹幕数（约 10~20）。
> - 每帧总开销：O(n)，n 很小，对 60fps 帧预算（16.7ms）几乎无感知。

---

**Q4：Combine 中 `cancellables` 如果忘记 `store` 会怎样？**

> `.sink` 返回一个 `AnyCancellable`，如果不持有它，它会在当前作用域结束时立即被释放，订阅随即取消。换句话说，订阅根本没有生效就结束了，UI 不会更新。`store(in: &cancellables)` 将令牌的所有权转移给集合，集合随 ViewController 一起销毁，订阅在 VC 消失时自动取消——这是 Combine 内存管理的标准模式。

---

**Q5：`@Published` 的初始值会触发订阅吗？**

> 会。`@Published` 属性在初始化完成后，`$property` 就持有当前值作为第一个元素（类似 `CurrentValueSubject`）。所以 `.sink` 订阅后会立即收到一次初始值的回调。如果不希望处理初始值（比如初始 `danmaku` 为 `nil`），需要加 `.dropFirst()` 或 `.compactMap { $0 }` 来过滤。

---

**Q6：Child ViewController 和直接 addSubview 有什么区别？**

> Child ViewController 建立了父子 VC 关系，子 VC 能正确接收 `viewWillAppear`、`viewDidAppear`、`viewWillDisappear`、`viewDidDisappear` 等生命周期回调，以及 `traitCollection` 变化（深色模式、横竖屏等）。直接 `addSubview` 只是在视图层级上添加了一个 view，没有建立 VC 关系，子模块的生命周期回调会断链，导致 timer、displayLink 等资源无法正确管理。

---

**Q7：如果直播间弹幕量突然暴增，你如何保护 UI 不卡顿？**

> 本项目已有两层保护：
> 1. **轨道饱和时直接丢弃**：`availableTrack()` 返回 `nil` 时，`addDanmaku()` 直接 `return`，不创建新 label，保证屏幕上弹幕密度上限。
> 2. **复用池限制对象总数**：即使高频触发 `addDanmaku`，Label 的总数也不会超过「轨道数 × 屏幕可见弹幕上限」，没有无界内存增长。
>
> 进阶优化可以在 ViewModel 层加**令牌桶限流**（Token Bucket），每秒最多向 View 层投递 N 条弹幕，超出部分在队列里等待或丢弃，从根源控制流量。
