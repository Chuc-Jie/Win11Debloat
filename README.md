# Win11Debloat

[![GitHub Release](https://img.shields.io/github/v/release/Raphire/Win11Debloat?style=for-the-badge&label=Latest%20release)](https://github.com/Raphire/Win11Debloat/releases/latest)
[![Join the Discussion](https://img.shields.io/badge/Join-the%20Discussion-2D9F2D?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Raphire/Win11Debloat/discussions)
[![Static Badge](https://img.shields.io/badge/Documentation-_?style=for-the-badge&logo=bookstack&color=grey)](https://github.com/Raphire/Win11Debloat/wiki/)

Win11Debloat 是一个轻量、易用的 PowerShell 脚本，可以让您快速清理并自定义 Windows 体验。它可以卸载预装的臃肿应用、禁用遥测、移除碍眼的界面元素等等。无需亲自逐项检查所有设置，也无需一个一个卸载应用。Win11Debloat 让这个过程变得快速且简单！

该脚本还包含许多系统管理员和高级用户喜欢的功能，例如强大的命令行接口、对 Windows 审核模式的支持，以及为其他 Windows 用户应用更改的选项。详情请参阅我们的 [wiki](https://github.com/Raphire/Win11Debloat/wiki/)。

![Win11Debloat 菜单](/Assets/Images/menu.png)

#### 这个脚本对您有帮助吗？欢迎请我喝杯咖啡来支持我的工作

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M5C6UPC)

## 使用方法

> [!Warning]
> 我们已尽力确保此脚本不会无意中破坏任何系统功能，但使用时请自行承担风险！如遇任何问题，请在 [这里](https://github.com/Raphire/Win11Debloat/issues) 反馈。

### 快捷方式

通过 PowerShell 自动下载并运行脚本。

1. 打开 PowerShell 或 Terminal（推荐以管理员身份运行）。
2. 将下面的命令复制粘贴到 PowerShell 中：

```PowerShell
& ([scriptblock]::Create((irm "https://debloat.raphi.re/")))
```

3. 等待脚本自动下载 Win11Debloat。
4. 仔细阅读并按照屏幕上的说明操作。

此方法支持命令行参数以自定义脚本行为。详情请点击 [这里](https://github.com/Raphire/Win11Debloat/wiki/Command%E2%80%90line-Interface#parameters)。

### 传统方式

<details>
  <summary>手动下载并运行脚本。</summary><br/>

  1. [下载最新版本的脚本](https://github.com/Raphire/Win11Debloat/releases/latest)，并将 .ZIP 文件解压到您想要的位置。
  2. 进入 Win11Debloat 文件夹
  3. 双击 `Run.bat` 文件启动脚本。注意：如果控制台窗口立即关闭且什么也没发生，请尝试下方的高级方式。
  4. 接受 Windows UAC 提示以管理员身份运行脚本，这是脚本运行所必需的。
  5. 仔细阅读并按照屏幕上的说明操作。
</details>

### 高级方式

<details>
  <summary>手动下载脚本并通过 PowerShell 运行。推荐给高级用户。</summary><br/>

  1. [下载最新版本的脚本](https://github.com/Raphire/Win11Debloat/releases/latest)，并将 .ZIP 文件解压到您想要的位置。
  2. 以管理员身份打开 PowerShell 或 Terminal。
  3. 输入以下命令临时启用 PowerShell 执行：

  ```PowerShell
  Set-ExecutionPolicy Unrestricted -Scope Process -Force
  ```

  4. 在 PowerShell 中，导航到解压文件的目录。例如：`cd c:\Win11Debloat`
  5. 输入以下命令运行脚本：

  ```PowerShell
  .\Win11Debloat.ps1
  ```

  6. 仔细阅读并按照屏幕上的说明操作。

  此方法支持命令行参数以自定义脚本行为。详情请点击 [这里](https://github.com/Raphire/Win11Debloat/wiki/Command%E2%80%90line-Interface#parameters)。
</details>

## 功能

以下是 Win11Debloat 提供的主要功能概览。关于默认设置预设的更多信息，请参阅 [wiki](https://github.com/Raphire/Win11Debloat/wiki/Default-Settings)。

> [!Tip]
> Win11Debloat 所做的所有更改都可以轻松还原，几乎所有应用都可以通过 Microsoft Store 重新安装。完整的还原指南请见 [这里](https://github.com/Raphire/Win11Debloat/wiki/Reverting-Changes)。

#### 应用卸载

- 卸载多种预装应用。详情请点击 [这里](https://github.com/Raphire/Win11Debloat/wiki/App-Removal)。

#### 隐私与建议内容

- 禁用遥测、诊断数据、活动历史记录、应用启动跟踪和定向广告。
- 禁用 Windows 中的提示、技巧、建议和广告。
- 禁用 Windows 定位服务和应用位置访问。
- 禁用"查找我的设备"位置跟踪。
- 禁用"Windows 聚焦"以及锁屏上的提示和技巧。
- 禁用"Windows 聚焦"桌面背景选项。
- 禁用 Microsoft Edge 中的广告、建议和 MSN 新闻源。
- 在"设置"主页隐藏 Microsoft 365 广告，或彻底隐藏"主页"。

#### AI 功能

- 禁用并移除 Microsoft Copilot。
- 禁用 Windows Recall。
- 禁用 Click to Do（AI 文本与图像分析工具）。
- 阻止 AI 服务（WSAIFabricSvc）自动启动。
- 禁用 Edge 中的 AI 功能。
- 禁用画图中的 AI 功能。
- 禁用记事本中的 AI 功能。

#### 系统

- 禁用用于共享和移动文件的"拖动托盘"。
- 恢复经典 Windows 10 风格的右键菜单。
- 关闭增强指针精度（即鼠标加速）。
- 禁用粘滞键键盘快捷方式。
- 禁用存储感知自动磁盘清理。
- 禁用快速启动以确保完全关机。
- 禁用 BitLocker 自动设备加密。
- 在新式待机期间禁用网络连接以减少电池消耗。

#### Windows 更新

- 阻止 Windows 尽快获取更新。
- 用户登录时阻止更新后自动重启。
- 禁用与其他电脑共享已下载的更新，即"传递优化"。

#### 外观

- 为系统和应用启用深色模式。
- 禁用透明效果。
- 禁用动画和视觉效果。

#### 开始菜单与搜索

- 移除或替换开始菜单中所有已固定的应用。
- 隐藏开始菜单中的推荐部分。
- 隐藏开始菜单中的"所有应用"部分。
- 禁用开始菜单中的手机连接移动设备集成。
- 禁用 Windows 搜索中的 Bing 网页搜索和 Copilot 集成。
- 禁用 Windows 搜索中的 Microsoft Store 应用建议。
- 禁用任务栏搜索框中的搜索亮点（动态/品牌内容）。
- 禁用本地 Windows 搜索历史记录。

#### 任务栏

- 任务栏图标左对齐。
- 隐藏或更改任务栏上的搜索图标/搜索框。
- 在任务栏上隐藏任务视图按钮。
- 禁用任务栏和锁屏上的小组件。
- 在任务栏上隐藏聊天（立即开会）图标。
- 启用任务栏右键菜单中的"结束任务"选项。
- 启用任务栏应用区域的"最后活动单击"行为。这让您可以反复单击任务栏中应用的图标，在该应用的多个打开窗口之间切换焦点。
- 选择使用多个显示器时任务栏上应用图标的显示方式。
- 选择任务栏按钮和标签的合并模式。

#### 文件资源管理器

- 更改文件资源管理器的默认打开位置。
- 显示已知文件类型的扩展名。
- 显示隐藏的文件、文件夹和驱动器。
- 从文件资源管理器导航窗格中隐藏"主页"或"图库"部分。
- 从文件资源管理器导航窗格中隐藏重复的可移动驱动器条目，只保留"此电脑"下的条目。
- 将所有常用文件夹（桌面、下载等）重新添加回文件资源管理器的"此电脑"。
- 从文件资源管理器导航窗格中隐藏 3D 对象、音乐或 OneDrive 文件夹。
- 从右键菜单中隐藏"包含在库中"、"授予访问权限"和"共享"选项。
- 更改文件资源管理器中驱动器盘符的位置或显示。

#### 多任务

- 禁用窗口贴靠。
- 贴靠窗口时禁用贴靠辅助建议。
- 将窗口拖到屏幕顶部以及悬停在最大化按钮上时，禁用贴靠布局建议。
- 更改贴靠或按 Alt+Tab 时是否显示标签页。

#### 可选 Windows 功能

- 启用 Windows 沙盒，一个用于安全隔离运行应用程序的轻量级桌面环境。
- 启用适用于 Linux 的 Windows 子系统，让您可以直接在 Windows 上运行 Linux 环境。

#### 其他

- 禁用 Xbox 游戏栏集成和游戏/屏幕录制。如果您卸载了 Xbox 游戏栏，这也会禁用 `ms-gamingoverlay`/`ms-gamebar` 弹窗。
- 禁用 Brave 浏览器中的臃肿功能（AI、加密货币、新闻等）。

#### 高级功能

- 可以 [为其他用户应用更改](https://github.com/Raphire/Win11Debloat/wiki/Advanced-Features#running-as-another-user)，而不是当前登录的用户。
- [Sysprep 模式](https://github.com/Raphire/Win11Debloat/wiki/Advanced-Features#sysprep-mode)：将更改应用到 Windows 默认用户配置文件，确保所有新用户都会自动应用这些更改。

## 贡献

我们欢迎各种形式的贡献！请查看我们的 [贡献指南](/.github/CONTRIBUTING.md) 了解如何开始以及最佳实践。

## 许可证

Win11Debloat 基于 MIT 许可证发布。详情请见 LICENSE 文件。
