# FormationFlight 5.0：编队多同伴雷达 OSD 独立显示说明

## 目标

在 FormationFlight 编队场景中，希望雷达信息能够针对 **多个同伴** 以 **独立位置** 同时显示，而不是像之前那样复用同一块区域轮播显示。

同时要求：

- 允许用户在 OSD 参数里分别配置 **A~F** 六个同伴槽位的显示位置；
- 当某个同伴没有有效雷达数据时，该槽位 **不显示任何占位符**；
- 只开启一个槽位时，即便实际存在更多同伴雷达数据，也不会产生“数据堆积/溢出/异常”的系统问题（只是不绘制未开启槽位）。

## 实现概述

### 1. OSD 雷达槽位 A~F（独立显示）

实现方式是在 `AP_OSD_Screen` 中为 Formation 雷达增加 **6 路独立显示参数**：

- `RADAR` 作为 OSD 这一屏的父组（保持在合法的组索引范围内）；
- 6 路同伴槽位作为该父组下面的参数子项：`A~F`；
- 每个槽位绑定 `peer_id`：
  - `A` -> `peer_id = 0`
  - `B` -> `peer_id = 1`
  - `C` -> `peer_id = 2`
  - `D` -> `peer_id = 3`
  - `E` -> `peer_id = 4`
  - `F` -> `peer_id = 5`

绘制逻辑使用 `AP_Radar::get_peer_healthy(peer_id)` 判断该 peer 是否“健康”（最近更新且位置非零且 LQ>0）。不健康时直接返回，不写入任何字符，因此不会产生占位符。

OSD 的每帧更新会清屏后再绘制，因此不会因为“上一次画过”导致“残影”。

### 2. 线程/锁安全（AHRS 读 + AP_Radar 读的顺序）

`draw_radar_peer()` 读取 AHRS 的经纬度/航向时持有 `ahrs.get_semaphore()`，但不会在持锁期间调用 `AP_Radar` 的读接口。

这样避免了 OSD 绘制线程与雷达/其它线程之间可能出现的锁顺序交错问题。

### 3. 雷达数据输入的边界保护（MSP 报文）

在 `AP_Radar_MSP::handle_msp()` 中加入了 `pkt.radar_no` 的范围检查：

- `radar_no` 为 1-based；
- 合法范围为 `1..RADAR_MAX_PEERS`；
- 否则直接丢弃，防止越界写。

## 参数如何配置

### 1. 参数名（Mission Planner / MAVLink 参数）

建议在地面站参数里搜索以下关键词：

- `RADAR_A_EN` / `RADAR_A_X` / `RADAR_A_Y`
- `RADAR_B_EN` / ... / `RADAR_F_Y`

具体前缀（例如 `OSD1_`、`OSD2_` 等）取决于你使用的是哪一屏/哪一个 OSD 实例；末尾的 `RADAR_A_*` 规则保持一致。

如果你之前已经在地面站里配置过“旧命名”（例如 `RADAR`/`RADAR2` 那种平铺参数名），升级到本版本后需要按新的 `RADAR_A~RADAR_F` 名字重新设置一次（因为我们为了满足 `AP_Param` 校验规则调整了参数分组结构）。

### 2. 开启/关闭显示

- 只开启某一个槽位：只会绘制该槽位（并且仅当该 peer 健康时才会绘制）。
- 同时存在多个 peer 数据：未开启的槽位不会绘制，但不会影响其它已开启槽位或系统稳定性。

## 代码改动点清单

1. `libraries/AP_OSD/AP_OSD.h`
   - 新增 `AP_OSD_RadarPeers` 参数容器；
   - 将 `AP_OSD_Screen` 内原先单一 `radar` 设置替换为新的 `radar`（类型变为 `AP_OSD_RadarPeers`）。

2. `libraries/AP_OSD/AP_OSD_Screen.cpp`
   - 新增 `AP_OSD_RadarPeers::var_info[]`：定义 `A~F` 的 `EN/X/Y` 参数子项；
   - 修改该屏的 `var_info`：将 `RADAR` 父组挂到 `AP_OSD_RadarPeers`；
   - 修改绘制：
     - `draw()` 按 `A~F` 各自 `*_EN` 独立调用 `draw_radar_peer(..., peer_id)`；
     - `draw_radar_peer()` 按健康状态绘制，不健康则不写入字符（无占位符）。

3. `libraries/AP_Radar/AP_Radar_MSP.cpp`
   - 为 `pkt.radar_no` 增加合法范围检查，避免潜在越界。

## 备注：为什么使用这种参数结构

ArduPilot 的 `AP_Param` 对参数分组的嵌套/索引存在硬约束：

- 父组的子项 `idx` 需要满足合法范围；
- 嵌套深度也有上限；

因此本实现使用：

- 一层合法父组 `RADAR`；
- 父组内用 `A~F` 作为直接参数子项，

以满足 `AP_Param` 的校验规则，避免启动时出现参数表异常。

## 验证建议（快速测试）

1. 在参数里仅开启 `RADAR_A_EN`，设置 `RADAR_A_X/Y` 到目标位置；
2. 同时让实际系统产生至少两个 peer 的雷达数据；
3. 观察：
   - 仅 `A` 槽位有显示；
   - `B~F` 坐标不应有残留或占位符；
   - 断开某个 peer 后，corresponding 槽位应自动变为空白（不写入任何字符）。

