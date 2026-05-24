<div align="center">

# ⚔️ HERO LEGEND

**一款半人工半AI协作的像素风动作平台游戏 Demo**

[![Godot Engine](https://img.shields.io/badge/Godot-4.6-blue.svg)](https://godotengine.org/)
[![GDScript](https://img.shields.io/badge/Language-GDScript-green.svg)](https://docs.godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](#license)

<details><summary><b>🌍 English Description</b></summary>

*A Semi-Human, Semi-AI Collaborative Pixel Art Action Platformer Demo*

</details>

---

<img src="main_menu.png" width="80%" alt="主菜单 Main Menu">

*主菜单 Main Menu*

</div>

---

## 🎮 游戏简介

**HERO LEGEND** 是一款使用 Godot 4.6 引擎开发的 2D 像素风格动作平台游戏 Demo。玩家操控一名像素骑士英雄，在奇幻森林场景中与多种敌人战斗，并最终挑战双阶段 Boss。

<details><summary><b>🌍 English</b></summary>

**HERO LEGEND** is a 2D pixel art action platformer demo built with the Godot 4.6 engine. The player controls a pixel knight hero, fighting various enemies in a fantasy forest setting, and ultimately challenging a two-phase boss.

</details>

### 🤖 关于这个项目

这是一个**边学习边制作**的游戏项目。作为一名 Godot 引擎和游戏开发的初学者，我在整个开发过程中大量借助了 AI 工具（Claude）来辅助编程、调试和设计。项目中既有我手动编写和调整的代码，也有 AI 生成后经过人工修改和优化的内容。可以说，这是一个**半人工半 AI 协作**的产物——AI 是我的编程导师和结对编程伙伴，而我负责所有的游戏设计决策、素材选择和最终质量把控。

<details><summary><b>🌍 English</b></summary>

This is a game project built **while learning**. As a beginner in Godot engine and game development, I extensively used AI tools (Claude) throughout the development process for coding assistance, debugging, and design. The project contains both manually written code and AI-generated code that has been reviewed, modified, and optimized by me. It is truly a **semi-human, semi-AI collaboration** — AI served as my programming mentor and pair-programming partner, while I was responsible for all game design decisions, asset selection, and final quality control.

</details>

---

## 📸 游戏截图

<div align="center">
<img src="level_01.png" width="80%" alt="关卡1 - 奇幻森林冒险">

*关卡 1 — 奇幻森林冒险*

<br><br>

<img src="boss_battle.png" width="80%" alt="Boss战">

*Boss 战 — 骑士双阶段决战*

</div>

<details><summary><b>🌍 English</b></summary>

<div align="center">
<img src="level_01.png" width="80%" alt="Level 1">

*Level 1 — Fantasy Forest Adventure*

<br><br>

<img src="boss_battle.png" width="80%" alt="Boss Battle">

*Boss Battle — Two-Phase Knight Duel*

</div>

</details>

---

## ✨ 游戏特性

### 战斗系统

- 近战攻击（带击退效果与伤害判定）
- 无敌帧机制（受伤后短暂无敌）
- 顿帧打击感（命中时短暂停顿 + 屏幕震动）
- 战斗反馈特效

<details><summary><b>🌍 English</b></summary>

- Melee attack (with knockback and damage detection)
- Invincibility frames (brief invincibility after taking damage)
- Hit-stop for impact feel (brief pause + screen shake on hit)
- Combat feedback effects

</details>

### 角色能力

- 二段跳
- 冲刺（带冷却时间）
- 跳跃切割（松开跳跃键可缩短跳跃高度）
- 3 点生命值系统

<details><summary><b>🌍 English</b></summary>

- Double Jump
- Dash (with cooldown)
- Jump Cut (release jump key to shorten jump height)
- 3-HP health system

</details>

### 敌人种类

| 敌人 | 描述 |
|------|------|
| 🟢 **史莱姆 (Slime)** | 基础敌人，巡逻行为 |
| ⚔️ **剑盾兵 (Soldier)** | 中等威胁，主动追击 |
| 🏹 **弓箭手 (Archer)** | 远程攻击 |
| 👹 **哥布林 (Goblin)** | 快速近战 |
| 🛡️ **骑士 Boss (Knight Boss)** | 双阶段 Boss 战 |

<details><summary><b>🌍 English</b></summary>

| Enemy | Description |
|-------|-------------|
| 🟢 **Slime** | Basic enemy, patrol behavior |
| ⚔️ **Soldier** | Medium threat, active pursuit |
| 🏹 **Archer** | Ranged attack |
| 👹 **Goblin** | Fast melee combat |
| 🛡️ **Knight Boss** | Two-phase boss fight |

</details>

### Boss 战

- **阶段一**：巡逻、追击、攻击
- **阶段二**（HP ≤ 50%）：速度 +30%，新增翻滚闪避、格挡、连击
- 视差滚动洞穴背景
- Boss 专属生命条 UI

<details><summary><b>🌍 English</b></summary>

- **Phase 1**: Patrol, chase, attack
- **Phase 2** (HP ≤ 50%): Speed +30%, adds roll dodge, block, combos
- Parallax scrolling cave background
- Dedicated boss health bar UI

</details>

### 音频系统

- BGM 淡入淡出切换
- 音效对象池（多音效同时播放）
- UI 按钮自动音效（hover/click）

<details><summary><b>🌍 English</b></summary>

- BGM fade-in/fade-out transitions
- SFX object pool (simultaneous multi-sound playback)
- Auto UI button SFX (hover/click)

</details>

### UI 系统

- 主菜单 / 暂停菜单 / 死亡界面
- 设置菜单（音量调节）
- 像素风心形血条 UI
- 像素字体 (Press Start 2P)

<details><summary><b>🌍 English</b></summary>

- Main Menu / Pause Menu / Death Screen
- Settings Menu (volume control)
- Pixel-art heart HP bar UI
- Pixel font (Press Start 2P)

</details>

---

## 🎮 操作说明

| 按键 | 动作 |
|------|------|
| `A` / `D` | 左右移动 |
| `W` | 跳跃（支持二段跳）|
| `J` | 攻击 |
| `Space` | 冲刺 |
| `Esc` | 暂停 |

<details><summary><b>🌍 English</b></summary>

| Key | Action |
|-----|--------|
| `A` / `D` | Move Left / Right |
| `W` | Jump (Double Jump supported) |
| `J` | Attack |
| `Space` | Dash |
| `Esc` | Pause |

</details>

---

## 🛠️ 技术栈

| 技术 | 说明 |
|------|------|
| **Godot 4.6** | 游戏引擎 |
| **GDScript** | 脚本语言 |
| **Forward+ Renderer** | 渲染器 (D3D12) |
| **Dialogue Manager** | 对话系统插件 |

<details><summary><b>🌍 English</b></summary>

| Tech | Description |
|------|-------------|
| **Godot 4.6** | Game Engine |
| **GDScript** | Scripting Language |
| **Forward+ Renderer** | Renderer (D3D12) |
| **Dialogue Manager** | Dialogue System Plugin |

</details>

### 核心技术实现

- 状态机模式（所有角色）
- 角色继承体系（EnemyBase 基类 → 子类覆写）
- 信号驱动 UI 更新（血条、Boss 生命条）
- 音频管理器单例（BGM + SFX 池）
- 全局游戏管理器（关卡切换、重启）
- 射线检测边缘防护（敌人不会掉落悬崖）

<details><summary><b>🌍 English</b></summary>

- State Machine pattern (all characters)
- Character inheritance (EnemyBase → subclass overrides)
- Signal-driven UI updates (HP bar, Boss health bar)
- Audio Manager singleton (BGM + SFX pool)
- Global Game Manager (level switching, restart)
- Raycast edge detection (enemies won't fall off cliffs)

</details>

---

## 📁 项目结构

```
.
├── project.godot              # 项目配置
├── icon.svg                   # 项目图标
├── main_menu.png              # 游戏截图
├── level_01.png
├── boss_battle.png
├── addons/
│   └── dialogue_manager/      # 对话系统插件
├── assets/
│   ├── audio/
│   │   ├── bgm/               # 背景音乐 (4首)
│   │   ├── hero/              # 英雄音效
│   │   ├── enemy/             # 敌人音效
│   │   └── ui/                # UI音效
│   ├── character/
│   │   ├── hero/              # 英雄精灵图
│   │   └── enemy/             # 敌人精灵图
│   ├── Knight Hero Platfomer/ # Boss骑士动画帧
│   ├── effects/               # 特效精灵
│   ├── fonts/                 # 像素字体
│   ├── themes/                # UI 主题
│   ├── tilesets/              # 瓦片集
│   ├── parallax cave/         # Boss战视差背景
│   ├── Legacy-Fantasy*/       # 森林瓦片和背景
│   ├── 16x16_ClassicTilePack/ # 经典像素瓦片
│   ├── UI_object/             # 心形血条
│   └── Tiny RPG*/             # 角色素材
├── scenes/
│   ├── characters/            # 角色场景
│   │   ├── hero.tscn
│   │   ├── slime.tscn
│   │   ├── soldier.tscn
│   │   ├── goblin.tscn
│   │   ├── arrow_soldier.tscn
│   │   └── knight.tscn        # Boss
│   ├── levels/                # 关卡场景
│   │   ├── level_01.tscn
│   │   ├── boss_battle.tscn
│   │   └── node_2d.tscn       # 测试场景
│   └── ui/                    # UI 场景
│       ├── main_menu.tscn
│       ├── pause_menu.tscn
│       ├── death_screen.tscn
│       ├── settings_menu.tscn
│       ├── Player Life.tscn
│       └── Boss Life.tscn
└── scripts/
    ├── game_manager.gd        # 全局游戏管理器
    ├── audio_manager.gd       # 音频管理器
    ├── combat_feedback.gd     # 战斗反馈(顿帧/震动)
    ├── characters/
    │   ├── hero.gd            # 英雄(状态机)
    │   ├── enemy_base.gd      # 敌人基类
    │   ├── slime.gd
    │   ├── soldier.gd
    │   ├── goblin.gd
    │   ├── arrow_soldier.gd
    │   └── knight.gd          # Boss(双阶段)
    ├── levels/
    │   ├── game_level.gd
    │   ├── boss_battle.gd
    │   └── enemy_spawner.gd
    └── ui/
        ├── main_menu.gd
        ├── pause_menu.gd
        ├── death_screen.gd
        ├── health_ui.gd
        └── boss_health_bar.gd
```

<details><summary><b>🌍 English (Comments)</b></summary>

```
.
├── project.godot              # Project config
├── icon.svg                   # Project icon
├── main_menu.png              # Game screenshots
├── level_01.png
├── boss_battle.png
├── addons/
│   └── dialogue_manager/      # Dialogue system plugin
├── assets/
│   ├── audio/
│   │   ├── bgm/               # BGM (4 tracks)
│   │   ├── hero/              # Hero SFX
│   │   ├── enemy/             # Enemy SFX
│   │   └── ui/                # UI SFX
│   ├── character/
│   │   ├── hero/              # Hero sprite sheet
│   │   └── enemy/             # Enemy sprite sheets
│   ├── Knight Hero Platfomer/ # Boss knight animation frames
│   ├── effects/               # Effect sprites
│   ├── fonts/                 # Pixel font
│   ├── themes/                # UI theme
│   ├── tilesets/              # Tilesets
│   ├── parallax cave/         # Boss parallax backgrounds
│   ├── Legacy-Fantasy*/       # Forest tiles & backgrounds
│   ├── 16x16_ClassicTilePack/ # Classic pixel tiles
│   ├── UI_object/             # Heart HP assets
│   └── Tiny RPG*/             # Character assets
├── scenes/
│   ├── characters/            # Character scenes
│   ├── levels/                # Level scenes
│   └── ui/                    # UI scenes
└── scripts/
    ├── game_manager.gd        # Global game manager
    ├── audio_manager.gd       # Audio manager
    ├── combat_feedback.gd     # Combat feedback (hit-stop/shake)
    ├── characters/            # Character scripts (state machines)
    ├── levels/                # Level scripts
    └── ui/                    # UI scripts
```

</details>

---

## 🤝 AI 协作说明

本项目是一个**人机协作**的典型案例。

### AI 做了什么
- GDScript 代码生成与调试
- 状态机架构设计建议
- 敌人 AI 行为逻辑实现
- 音频管理器设计与实现
- 角色物理与碰撞系统调优
- UI 场景搭建与脚本编写

### 人类做了什么
- 游戏概念与玩法设计
- 所有素材资源的选择与整合
- 关卡布局设计
- 游戏手感调参（速度、重力、跳跃高度等）
- 代码审查与修改优化
- 整体项目方向决策
- 素材裁剪与适配

### 使用到的 AI 工具
- **Claude (Anthropic)** — 代码生成、架构设计、调试、文档编写
- **Belt / FLUX** — 部分精灵图素材生成

<details><summary><b>🌍 English</b></summary>

This project is a typical case of **human-AI collaboration**.

### What AI Did
- GDScript code generation and debugging
- State machine architecture design suggestions
- Enemy AI behavior logic implementation
- Audio manager design and implementation
- Character physics and collision system tuning
- UI scene building and script writing

### What the Human Did
- Game concept and gameplay design
- Selection and integration of all assets
- Level layout design
- Game feel tuning (speed, gravity, jump height, etc.)
- Code review and modification/optimization
- Overall project direction decisions
- Asset cropping and adaptation

### AI Tools Used
- **Claude (Anthropic)** — Code generation, architecture design, debugging, documentation
- **Belt / FLUX** — Some sprite asset generation

</details>

---

## 🚀 如何运行

### 前置条件
- [Godot Engine 4.6+](https://godotengine.org/download) (Standard 版本即可)

### 运行步骤
```
1. 克隆仓库
   git clone https://github.com/你的用户名/仓库名.git

2. 用 Godot 打开项目
   打开 Godot Engine → Import → 选择项目文件夹

3. 运行游戏
   按 F5 或点击右上角 ▶ 按钮
```

<details><summary><b>🌍 English</b></summary>

### Prerequisites
- [Godot Engine 4.6+](https://godotengine.org/download) (Standard version)

### Steps
```
1. Clone the repository
   git clone https://github.com/your-username/your-repo.git

2. Open with Godot
   Godot Engine → Import → Select the project folder

3. Run the game
   Press F5 or click the ▶ button in the top-right corner
```

</details>

---

## 🎨 素材来源

| 素材 | 来源 |
|------|------|
| Legacy-Fantasy High Forest | [Pixel-Boy & AAA](https://pixel-boy.itch.io/) |
| Knight Hero Platformer | [Penzilla](https://penzilla.itch.io/) |
| Tiny RPG Character Pack | [Pixel Frog](https://pixelfrog-assets.itch.io/) |
| 16x16 Classic Tile Pack | [Kenney](https://kenney.nl/) |
| Parallax Cave Background | Free game assets |
| UI Hearts | Free game assets |
| Press Start 2P Font | [Google Fonts](https://fonts.google.com/specimen/Press+Start+2P) |
| BGM & Sound Effects | Free game audio assets |
| Dialogue Manager | [Godot Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager) |

<details><summary><b>🌍 English</b></summary>

| Asset | Source |
|-------|--------|
| Legacy-Fantasy High Forest | [Pixel-Boy & AAA](https://pixel-boy.itch.io/) |
| Knight Hero Platformer | [Penzilla](https://penzilla.itch.io/) |
| Tiny RPG Character Pack | [Pixel Frog](https://pixelfrog-assets.itch.io/) |
| 16x16 Classic Tile Pack | [Kenney](https://kenney.nl/) |
| Parallax Cave Background | Free game assets |
| UI Hearts | Free game assets |
| Press Start 2P Font | [Google Fonts](https://fonts.google.com/specimen/Press+Start+2P) |
| BGM & Sound Effects | Free game audio assets |
| Dialogue Manager | [Godot Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager) |

</details>

---

## 📝 开发日志

这个项目始于一个简单的想法：**一边学习 Godot 引擎，一边做一款自己的游戏**。没有任何游戏开发经验的我，从零开始摸索。AI 在这个过程中扮演了"导师"的角色——它教我状态机模式、信号系统、碰撞层设计等游戏开发基础知识，同时帮助我将这些概念转化为可运行的代码。

<details><summary><b>🌍 English</b></summary>

This project started with a simple idea: **learn the Godot engine by building a game**. With zero game development experience, I explored everything from scratch. AI played the role of "mentor" — teaching me state machine patterns, signal systems, collision layer design, and other game dev fundamentals, while helping me translate these concepts into runnable code.

</details>

---

## 📜 License

This project is for learning and demonstration purposes. All third-party assets are credited to their respective creators.

本项目仅供学习和演示用途。所有第三方素材版权归原作者所有。

---

<div align="center">

**Made with Godot + Human + AI**

*用 Godot + 人类 + AI 制作*

</div>
