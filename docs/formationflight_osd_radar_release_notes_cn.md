# FormationFlight OSD 雷达多同伴改动发布说明（中文）

## 1. 适用范围

- 代码仓库基线：`MUSTARDTIGERFPV/ardupilot`（FormationFlight 定制分支）
- 飞控固件基线：`ArduPlane V4.5.7`
- 本次改动目标：编队雷达 OSD 从“单位置轮播”改为“多同伴独立显示”

## 2. 背景问题

### 2.1 功能层面问题

原逻辑为雷达信息在同一位置轮播，不利于编队多机实时观察。

需求为：
- 同时支持多个同伴（A~F）在不同 OSD 坐标独立显示；
- 某同伴无有效数据时，不显示占位符。

### 2.2 稳定性问题（已定位并修复）

开发过程中出现过两类启动级问题，均已修复：

1) `Bad parameter table`  
原因：参数组索引使用了超范围值（`idx >= 64`）触发 `AP_Param` 校验失败。

2) `double group nesting in A`  
原因：参数层级嵌套超过允许深度（形成三层 group）。

最终方案将参数结构调整为合法的两层模型，保证启动稳定。

## 3. 核心实现

### 3.1 参数结构（最终）

在 OSD 屏幕参数下保留 `RADAR` 父组，父组内直接定义 A~F 六组参数：

- `A_EN/A_X/A_Y`
- `B_EN/B_X/B_Y`
- `C_EN/C_X/C_Y`
- `D_EN/D_X/D_Y`
- `E_EN/E_X/E_Y`
- `F_EN/F_X/F_Y`

对应 peer 映射：
- A -> `peer_id 0`
- B -> `peer_id 1`
- C -> `peer_id 2`
- D -> `peer_id 3`
- E -> `peer_id 4`
- F -> `peer_id 5`

### 3.2 显示逻辑

- 每个槽位由独立 `*_EN` 控制是否绘制；
- 绘制前调用 `get_peer_healthy(peer_id)`；
- 不健康（无新数据/无定位/LQ 无效）直接返回，不写屏；
- OSD 每帧清屏后重绘，因此不会产生旧数据残留占位。

### 3.3 输入边界保护

在 `AP_Radar_MSP::handle_msp()` 增加 `radar_no` 范围检查：
- 非 `1..RADAR_MAX_PEERS` 的包直接丢弃；
- 防止越界写 `peers[]`，避免潜在内存破坏。

## 4. 代码改动文件

### 飞控逻辑

- `libraries/AP_OSD/AP_OSD.h`
- `libraries/AP_OSD/AP_OSD_Screen.cpp`
- `libraries/AP_Radar/AP_Radar_MSP.cpp`

### 文档与工具

- `docs/formationflight_osd_radar_multipeer.md`
- `Tools/scripts/sync_to_shared_FFardupilot.sh`
- `docs/formationflight_osd_radar_release_notes_cn.md`（本文）

## 5. 参数迁移说明

旧参数命名（平铺 `RADAR`, `RADAR2` ...）已调整为 `RADAR_A~RADAR_F`。

升级后建议：
- 在地面站重新检查并设置 `RADAR_A~F` 的 EN/X/Y；
- 避免直接复用旧参数文件中的旧命名项。

## 6. 构建产物（本次随分支同步）

### MatekH743
- `build/MatekH743/bin/H743.4.5.7arduplane_with_bl.hex`
- `build/MatekH743/bin/arduplane.apj`
- `build/MatekH743/bin/arduplane.bin`

### MatekF405-Wing
- `build/MatekF405-Wing/bin/F405-Wing.4.5.7.arduplane_with_bl.hex`
- `build/MatekF405-Wing/bin/arduplane.apj`
- `build/MatekF405-Wing/bin/arduplane.bin`

## 7. 回归验证建议

1. 启动验证  
- 上电后不再出现 `Bad parameter table` / `double group nesting`。

2. 参数验证  
- 地面站可看到 `RADAR_A~F` 参数组并可保存。

3. 显示验证  
- 仅开启 A：只有 A 显示；  
- 同时开启 A/B：A、B独立显示；  
- 关闭 B 或 B 无数据：B 区域不显示占位符。

4. 边界验证  
- 注入非法 `radar_no` 的 MSP 包不会导致飞控异常（被安全忽略）。

## 8. 对外建议描述（可直接用于发布）

“本版本基于 FormationFlight 定制 ArduPilot Plane 4.5.7，新增编队雷达 OSD 多同伴（A~F）独立显示能力，并加入 MSP 雷达输入边界保护与参数结构稳定性修复。无有效雷达数据时对应槽位不显示占位符。”

