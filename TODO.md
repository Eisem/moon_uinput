# MoonInput 参赛开发 TODO

更新时间：2026-09-22

## 硬性目标

- [ ] 有效源码与测试代码达到 4,000–10,000 行，不使用重复或填充代码凑数。
- [ ] Git 历史至少包含 10 个有实质意义的提交，不使用空提交或机械拆分。
- [ ] GitHub 仓库公开可访问，默认分支 CI 全绿。
- [ ] MoonBit 是主要实现语言，C 仅承担 Linux ABI 与 ioctl 薄封装。
- [x] 使用 OSI 认可的 MIT 许可证。
- [ ] README 覆盖目标、安装、使用、示例、权限、安全、限制和路线图。
- [ ] 核心逻辑具有不依赖真实输入硬件的自动化测试。
- [ ] 发布到 mooncakes.io，并验证其他项目可以安装和引用。
- [ ] 准备一页以内、由参赛者审阅和改写的项目申报书。

## 已完成基线

- [x] P0：MoonBit 工程结构、native C FFI、Linux/非 Linux 构建边界。
- [x] P1：强类型事件、常用按键与轴、Unknown 值保留和解码测试。
- [x] P2：设备打开、关闭、名称、ID 和结构化错误。
- [x] P3：阻塞式事件读取、EventStream 和 monitor 示例。
- [x] P4：设备能力位图、绝对轴元数据、查询 API 和 device_info 示例。
- [x] FFI 参数补齐新版编译器要求的 `#borrow` 所有权注解。
- [x] Windows 严格检查与 WSL2 Ubuntu 原生验证。
- [x] GitHub Actions Linux native CI 配置。
- [x] 已建立连续、可追踪的有效提交历史；当前 3 个，目标至少 10 个。

## 实施顺序

### 1. Device Capabilities（计划 Commit 3）

- [x] 定义 `DeviceCapabilities`。
- [x] 定义 `AbsoluteAxisInfo` 和绝对轴能力记录。
- [x] 在 MoonBit 中实现 Linux capability bitmap 解码。
- [x] 提供 `supports_event`、`supports_key`、`supports_relative_axis` 等查询 API。
- [x] 覆盖跨字节边界、稀疏位图、未知代码和空位图测试。
- [x] C shim 增加 `EVIOCGBIT` 与 `EVIOCGABS`。
- [x] `Device::capabilities()` 返回完整能力信息。
- [x] 添加 `examples/device_info`。

### 2. Device Discovery（计划 Commit 4）

- [ ] 安全枚举 `/dev/input/event*`，不猜测固定编号。
- [ ] 单个设备权限失败时继续列出其他设备并展示原因。
- [ ] 添加 `examples/list_devices`。
- [ ] 为路径排序、过滤和错误聚合添加测试。

### 3. Event Packetization（计划 Commit 5）

- [ ] 定义 `EventPacket`。
- [ ] 实现纯 MoonBit `Packetizer` 状态机。
- [ ] 以 `SYN_REPORT` 结束一帧，明确空包策略。
- [ ] 提供 `Device::packets()`。
- [ ] 覆盖 REL、KEY、多包、未知同步码和流断开测试。

### 4. SYN_DROPPED Recovery（计划 Commit 6）

- [ ] 检测 `SYN_DROPPED` 并进入失同步状态。
- [ ] 丢弃直到下一次 `SYN_REPORT` 的不可信事件。
- [ ] C shim 支持 `EVIOCGKEY` 与必要的绝对轴状态查询。
- [ ] 使用可替换状态源测试恢复状态机。
- [ ] 提供 `synced_packets()` 或等价的默认安全 API。

### 5. EVIOCGRAB（计划 Commit 7）

- [ ] 实现 `Device::grab()` 与 `Device::ungrab()`。
- [ ] close/finalizer 保证释放文件描述符。
- [ ] 明确重复 grab、重复 ungrab 和设备断开的错误行为。
- [ ] monitor 示例保持默认不 grab。

### 6. uinput Core（计划 Commit 8）

- [ ] 定义 `VirtualDeviceBuilder` 和配置验证错误。
- [ ] 支持名称、bus/vendor/product/version 和 capability 配置。
- [ ] C shim 使用系统头文件实现 `UI_SET_*`、`UI_DEV_SETUP`、`UI_DEV_CREATE`。
- [ ] 定义 `VirtualDevice` 生命周期和 `UI_DEV_DESTROY`。
- [ ] builder 自动补全或拒绝冲突配置，并以测试固定行为。

### 7. Virtual Keyboard（计划 Commit 9）

- [ ] 提供底层 `emit()` 和 `sync()`。
- [ ] 提供 `key_down()`、`key_up()`、`key_click()`。
- [ ] 添加 `examples/virtual_keyboard`。
- [ ] 无 `/dev/uinput` 时返回可操作的权限或不可用错误。

### 8. Virtual Mouse（计划 Commit 10）

- [ ] 支持 `REL_X`、`REL_Y` 和三种常见鼠标按钮。
- [ ] 提供 `move_by()` 和按钮 helper。
- [ ] 添加 `examples/virtual_mouse`。
- [ ] 验证每组高层操作都正确发送 `SYN_REPORT`。

### 9. Async API（计划 Commit 11）

- [ ] 核对当前 `moonbitlang/async` RawFd API。
- [ ] 在保留同步 API 的同时添加异步事件读取。
- [ ] 使用结构化并发和取消机制，避免遗留后台任务。
- [ ] 添加不依赖真实输入设备的异步测试。

### 10. Remapper 与发布（计划 Commit 12）

- [ ] 完成 CapsLock + H/J/K/L 方向键 remapper。
- [ ] 显式 grab，异常退出时释放资源。
- [ ] 排除自己创建的虚拟设备，防止反馈环。
- [ ] 完成六个 examples 的使用文档。
- [ ] 完成 GitHub 仓库、CI 徽章、变更记录和 `v0.1.0` 标签。
- [ ] 发布并验证 mooncakes.io 包。

## 每项完成定义

每一项只有同时满足以下条件才能勾选并提交：

1. 公共 API 有文档，错误行为明确。
2. 核心逻辑有自动化测试；硬件相关部分有可跳过的集成测试策略。
3. `moon fmt` 不再产生差异。
4. `moon check --warn-list +unnecessary_annotation --deny-warn` 通过。
5. `moon test --target native --deny-warn` 通过。
6. `moon build --target native --deny-warn` 通过。
7. `moon info --target native` 已生成并审查公共接口。
8. WSL2 Ubuntu 严格 C 编译与 Linux 验证通过。
9. 提交信息描述真实功能，不拆分空提交。

## 当前指标

- 有效提交：3 / 10（最低要求）。
- 源码与测试代码：约 1,745 / 4,000–10,000 行。
- 自动化测试：Windows 10/10；WSL2 Ubuntu 10/10。
- 当前工作项：Device Discovery 与 list_devices 示例。
