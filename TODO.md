# MoonInput 参赛开发 TODO

更新时间：2026-09-23

## 硬性目标

- [x] 有效源码与测试代码达到 4,000–10,000 行，不使用重复或填充代码凑数。
- [x] Git 历史至少包含 10 个有实质意义的提交，不使用空提交或机械拆分。
- [ ] GitHub 仓库公开可访问，默认分支 CI 全绿。
- [x] MoonBit 是主要实现语言，C 仅承担 Linux ABI 与 ioctl 薄封装。
- [x] 使用 OSI 认可的 MIT 许可证。
- [x] README 覆盖目标、安装、使用、示例、权限、安全、限制和路线图。
- [x] 核心逻辑具有不依赖真实输入硬件的自动化测试。
- [ ] 发布到 mooncakes.io，并验证其他项目可以安装和引用。
- [ ] 准备一页以内、由参赛者审阅和改写的项目申报书（`SUBMISSION.md` 草稿已就绪）。

## 已完成基线

- [x] P0：MoonBit 工程结构、native C FFI、Linux/非 Linux 构建边界。
- [x] P1：强类型事件、常用按键与轴、Unknown 值保留和解码测试。
- [x] P2：设备打开、关闭、名称、ID 和结构化错误。
- [x] P3：阻塞式事件读取、EventStream 和 monitor 示例。
- [x] P4：设备能力位图、绝对轴元数据、查询 API 和 device_info 示例。
- [x] FFI 参数补齐新版编译器要求的 `#borrow` 所有权注解。
- [x] Windows 严格检查与 WSL2 Ubuntu 原生验证。
- [x] GitHub Actions Linux native CI 配置。
- [x] 已建立连续、可追踪的有效提交历史；当前至少 11 个，达到最低要求。

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

- [x] 安全枚举 `/dev/input/event*`，不猜测固定编号。
- [x] 单个设备权限失败时继续列出其他设备并展示原因。
- [x] 添加 `examples/list_devices`。
- [x] 为路径排序、过滤和错误聚合添加测试。

### 3. Event Packetization（计划 Commit 5）

- [x] 定义 `EventPacket`。
- [x] 实现纯 MoonBit `Packetizer` 状态机。
- [x] 以 `SYN_REPORT` 结束一帧，空帧跳过。
- [x] 提供 `Device::packets()`。
- [x] 覆盖 REL、KEY、多包、未知同步码和流断开测试。

### 4. SYN_DROPPED Recovery（计划 Commit 6）

- [x] 检测 `SYN_DROPPED` 并进入失同步状态。
- [x] 丢弃含 `SYN_DROPPED` 的整帧，并在其 `SYN_REPORT` 后恢复。
- [x] C shim 支持 `EVIOCGKEY` 与绝对轴状态查询。
- [x] 使用可替换状态源测试恢复状态机。
- [x] 提供 `Device::synced_packets()` 与 `Device::state()` API。

### 5. EVIOCGRAB（计划 Commit 7）

- [x] 实现 `Device::grab()` 与 `Device::ungrab()`。
- [x] close/finalizer 关闭文件描述符时由内核释放 grab。
- [x] 明确重复 grab、重复 ungrab、关闭和设备断开的错误行为。
- [x] monitor 示例保持默认不 grab。

### 6. uinput Core（计划 Commit 8）

- [x] 定义 `VirtualDeviceBuilder` 和配置验证错误。
- [x] 支持名称、bus/vendor/product/version 和 capability 配置。
- [x] C shim 使用系统头文件实现 `UI_SET_*`、`UI_DEV_SETUP`、`UI_DEV_CREATE`。
- [x] 定义 `VirtualDevice` 生命周期和 `UI_DEV_DESTROY`。
- [x] builder 去重重复 capability，重复绝对轴配置采用首次配置，并以测试固定行为。

### 7. Virtual Keyboard（计划 Commit 9）

- [x] 提供底层 `emit()` 和 `sync()`，并拒绝超出 Linux ABI 范围的 event type/code。
- [x] 提供 `key_down()`、`key_up()`、`key_click()`，各自正确结束 SYN_REPORT 帧。
- [x] 添加 `examples/virtual_keyboard`。
- [x] 无 `/dev/uinput` 时返回可操作的权限或不可用错误。

### 8. Virtual Mouse（计划 Commit 10）

- [x] 支持 `REL_X`、`REL_Y` 和三种常见鼠标按钮。
- [x] 提供 `move_by()` 和按钮 down/up/click helper。
- [x] 添加 `examples/virtual_mouse`。
- [x] 验证位移、按下和释放帧都正确发送 `SYN_REPORT`。

### 9. Async API（计划 Commit 11）

- [x] 核对当前 `moonbitlang/async@0.22.1` RawFd API。
- [x] 在保留同步 API 的同时添加异步事件、帧和丢帧恢复读取。
- [x] 直接 await 描述符读取，不创建后台任务；取消保留部分记录，资源由流显式关闭。
- [x] 添加不依赖真实输入设备的异步测试。

### 10. Remapper 与发布（计划 Commit 12）

- [x] 完成 CapsLock + H/J/K/L 方向键 remapper。
- [x] 显式 grab，异常退出时释放资源。
- [x] 排除自己创建的虚拟设备，防止反馈环。
- [x] 完成八个 examples 的使用文档。
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

- 有效提交：至少 12 / 10，达到最低要求。
- 源码与测试代码：4,086 / 4,000–10,000 行（`src`、`examples` 中的 `.mbt` 与 `.c`；不含生成代码、依赖和文档）。
- 自动化测试：Windows 48/48；WSL2 Ubuntu 51/51；Linux 严格 C 编译通过。
- 真实 uinput 同步与异步回环：已在现有 WSL2 Ubuntu 中成功运行，未使用 Docker 或修改设备权限。
- 包名已调整为 `eisem/mooninput`，`moon package --list` 通过；Windows MoonBit 已登录 `eisem`，WSL 未登录。
- 已配置 GitHub 远端 `https://github.com/Eisem/moon_uinput.git`，并填写 MoonBit 仓库元数据；远端内容和公开状态尚未验证，尚未推送。
- 剩余外部步骤：验证远端并安全推送、确认公开状态与 CI、打标签、发布 mooncakes.io、参赛者审阅申报书。
