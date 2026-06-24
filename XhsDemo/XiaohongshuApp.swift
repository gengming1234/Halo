// XiaohongshuApp.swift
//
// ⚠️ 此文件已完成 MVVM 改造，原有代码已按职责拆分到各自目录：
//
// ┌─────────────────────────────────────────────────────────────────┐
// │                     MVVM 架构文件分布                             │
// ├──────────────┬──────────────────────────────────────────────────┤
// │  Models/     │ Note.swift        — UI 展示模型（纯字段）            │
// │              │ NoteDTO.swift     — JSON 原始结构（解码用）           │
// ├──────────────┼──────────────────────────────────────────────────┤
// │  Services/   │ NoteService.swift — 数据加载 & DTO→Model 转换       │
// ├──────────────┼──────────────────────────────────────────────────┤
// │  ViewModels/ │ DiscoverViewModel.swift    — 发现页状态 & 业务逻辑  │
// │              │ NoteDetailViewModel.swift  — 详情页状态 & 业务逻辑  │
// ├──────────────┼──────────────────────────────────────────────────┤
// │  Views/      │ NoteCell.swift    — 列表 Cell（纯 UI）              │
// ├──────────────┼──────────────────────────────────────────────────┤
// │  Controllers/│ UIColViewContainer.swift          — 首页 Tab 容器  │
// │              │ DiscoverFeedViewController.swift  — 发现 Feed 列表  │
// │              │ NoteDetailViewController.swift    — 笔记详情页      │
// │              │ TabChildControllers.swift          — 其他简单页面   │
// └──────────────┴──────────────────────────────────────────────────┘
//
// MVVM 各层职责速查：
//
//  Model     → 只存数据字段，没有任何逻辑
//  Service   → 加载数据，把 DTO 转换成 Model
//  ViewModel → 持有 UI 状态，处理业务逻辑，用闭包通知 View 刷新
//  View/VC   → 只管显示 UI，把用户操作转发给 ViewModel
//
// 通信方式速查：
//
//  UIKit 框架要求     → 代理（delegate）  如：dataSource = self
//  子组件通知父组件   → 闭包（closure）   如：onDetailTap = { ... }
//  用户操作 → ViewModel → VC 更新 UI  如：bindViewModel() 里的 onNotesUpdated
