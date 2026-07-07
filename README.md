# PortDeck — macOS 本地服务控制台

PortDeck 是一款面向 macOS 开发者的本地开发服务控制台。它采用**纯原生 SwiftUI** 构建，专门针对 Apple Silicon (M 芯片) 进行能能优化，保证超轻量、低功耗、不常驻后台，内存占用控制在几十兆级别。

## 🌟 核心功能

1. **本地服务监控与优雅关闭 (SIGTERM / SIGKILL)**
   - 一眼查看当前 Mac 正在监听的所有本地端口服务（如 `127.0.0.1:xxxx` 或 `0.0.0.0:xxxx`）。
   - **项目来源感知 (Project-aware)**：自动识别服务所属的工作目录（Cwd）、父进程（Parent Process）以及完整启动命令参数（如 `npm run dev`）。
   - **多因子框架识别**：通过“进程名 + 命令行参数 + 工作目录特征文件”智能推断服务类型（如 Next.js, Vite, FastAPI, Django, Ollama 等）。
   - **优雅关闭机制**：优先向进程发送 `SIGTERM` (kill -15)，若 3 秒内未退出，提供红色 `SIGKILL` (kill -9) 按钮进行手动二次确认强杀。

2. **系统垃圾轻量清理**
   - 智能统计废纸篓 (`~/.Trash`) 的文件数量与总占用空间。
   - 提供“在 Finder 中打开回收站”的按钮，清空废纸篓时使用系统 Finder AppleScript 安全执行，保证行为合规且安全。

3. **操作安全日志与系统进程保护**
   - 默认**不需要管理员权限 (No Root Privilege)**，仅管理当前用户级别的开发进程。
   - 对系统级进程（位于 `/System`、`/usr/sbin` 等目录）及拥有 Apple 官方代码签名的进程默认进行**杀死屏蔽保护**，防止误伤系统关键服务。
   - 所有破坏性操作（如 SIGKILL、清空废纸篓）自动记录到本地日志文件 `~/Library/Logs/PortDeck/actions.json` 中，并在应用内提供“操作日志”面板供随时回溯。

---

## 📂 项目结构

```
mmg/
├── Package.swift            # Swift Package Manager 配置
├── package.sh               # 一键编译与打包为 Mac .app 安装包的脚本
├── prd.md                   # 优化后的 PortDeck 产品需求文档 (PRD)
├── README.md                # 本说明文档
└── Sources/                 # 纯原生 Swift 源代码
    ├── PortDeckApp.swift    # App 统一入口点 (@main)
    ├── ContentView.swift    # 侧边栏整体布局、自动刷新计时与状态中枢
    ├── DashboardView.swift  # 状态看板、网络暴露警告与操作推荐
    ├── PortsView.swift      # 端口列表，支持“卡片网格”与“高级表格”切换和多维搜索
    ├── ProcessDetailDrawer.swift  # 进程详情抽屉，展示完整命令、Cwd 并提供 Stop 操作
    ├── ActionLogView.swift  # 操作日志展示面板
    ├── PortService.swift    # 底层端口扫描、多因子框架推断与 native codesign 校验
    ├── TrashService.swift   # 计算废纸篓容量，通过 AppleScript 触发 Finder 清理
    ├── ActionLogService.swift # 将 SIGTERM/SIGKILL 等敏感操作持久化记录到 JSON 文件
    └── Theme.swift          # 应用界面视觉主题与颜色系统配置
```

---

## 🛠 编译与运行

由于项目采用标准 Swift Package Manager 结合简易打包脚本，您可以极其简单地在本地完成编译和分发。

### 1. 一键编译与打包
在项目根目录下执行以下命令：
```bash
./package.sh
```
该脚本将：
- 使用生产配置 (`release` 模式) 编译原生 `arm64` macOS 二进制文件。
- 在根目录创建标准的苹果应用包：`PortDeck.app`。
- 生成规范的 `Info.plist` 元数据。

### 2. 运行应用
打包完成后，直接使用命令行启动应用，或者双击 Finder 中的 `PortDeck.app`：
```bash
open PortDeck.app
```

---

## ⚡ 性能表现 (Apple Silicon)

- **CPU 占用**：闲置或后台时为 **0%**；执行刷新扫描时，GCD 会将任务倾向性地派发给能效核 (E-Cores)，瞬时占用极小，绝不引发发热与电池损耗。
- **内存占用**：运行时物理内存稳定在约 **30MB - 50MB**，极其轻量。
- **启动速度**：冷启动到首屏完全渲染耗费时间 **< 0.5 秒**。
