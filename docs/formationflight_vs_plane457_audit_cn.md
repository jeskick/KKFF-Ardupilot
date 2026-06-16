# FormationFlight 相对 ArduPilot Plane-4.5.7 改动审计清单

## 1. 审计范围与基线

- 基线（Base）：`ArduPilot/ardupilot` 标签 `Plane-4.5.7`
- 对比目标（Head）：`MUSTARDTIGERFPV/ardupilot:master`（FormationFlight 主线）
- 对比链接：<https://github.com/ArduPilot/ardupilot/compare/Plane-4.5.7...MUSTARDTIGERFPV:master>
- 结果摘要：
  - FormationFlight 侧新增提交：2
  - 文件变更：19
  - 主体目标：引入 Radar 模块（MSP 输入 + Plane 接入 + OSD 展示）

## 2. 提交级变化（FormationFlight 侧）

1. `35f5f0ef4f9a3543d36e0dad672fba07127d5775`
   - 标题：`Add iNav Radar functionality`
   - 性质：核心功能提交，包含绝大多数代码变更
2. `e0b64053598e04631cc8d8f0313c1e2c9fc13fcb`
   - 标题：`Merge remote-tracking branch 'origin'`
   - 性质：合并提交（不引入大量独立业务改动）

## 3. 文件级详细清单（按子系统分组）

### 3.1 Plane 机型集成层

1. `ArduPlane/ArduPlane.cpp`
   - 新增 `AP_Radar` 周期任务到调度器
   - 关键点：`SCHED_TASK_CLASS(AP_Radar, &plane.radar, update, 100, 25, ...)`
   - 风险点：任务频率提升会带来轻微 CPU 占用增长（通常可接受）

2. `ArduPlane/Plane.h`
   - 新增 `#include <AP_Radar/AP_Radar.h>`
   - 新增成员：`AP_Radar radar;`（`AP_RADAR_ENABLED` 条件编译）
   - 风险点：无（标准模块接入方式）

3. `ArduPlane/system.cpp`
   - 启动流程新增 `radar.init(-1)`（仅 `radar.enabled()` 时）
   - 风险点：初始化顺序依赖于参数加载完成状态（当前写法符合常规）

4. `ArduPlane/Parameters.h`
   - 参数枚举新增 `k_param_radar`
   - 风险点：参数索引需保持唯一（已按规范新增）

5. `ArduPlane/Parameters.cpp`
   - 参数表新增 `GOBJECT(radar, "RADAR", AP_Radar)`
   - 风险点：参数表冲突风险低，遵循 ArduPilot 标准 GOBJECT 接入

### 3.2 构建与特性开关

6. `Tools/ardupilotwaf/ardupilotwaf.py`
   - 构建库列表新增 `AP_Radar`

7. `Tools/scripts/build_options.py`
   - 新增 feature：`RADAR` → `AP_RADAR_ENABLED`
   - 新增 feature：`MSP_RADAR` → `HAL_MSP_RADAR_ENABLED`
   - 调整 `MSP_SENSORS` 依赖串，加入 `MSP_RADAR`
   - 风险点：关闭 `RADAR` 时应不引入多余依赖（当前由宏控制）

### 3.3 MSP 协议与遥测接收链路

8. `libraries/AP_MSP/msp_protocol.h`
   - 新增命令常量：
     - `MSP2_SET_RADAR_POS (0x100B)`
     - `MSP2_SET_RADAR_ITD (0x100C)`

9. `libraries/AP_MSP/msp.h`
   - 新增 `msp_radar_pos_message_t` 数据结构
   - 字段：`radar_no/state/lat/lon/alt/heading/speed/lq`

10. `libraries/AP_MSP/AP_MSP_Telem_Backend.h`
    - 新增接口声明：`msp_handle_radar(...)`

11. `libraries/AP_MSP/AP_MSP_Telem_Backend.cpp`
    - 命令分发放行 `MSP2_SET_RADAR_POS`
    - 传感器命令处理新增 radar 分支
    - 新增 `msp_handle_radar()`，将数据转交 `AP::radar()->handle_msp(pkt)`
    - 风险点：消息 ID 或负载不合法时需防御（后续已在你当前分支补了越界保护）

### 3.4 OSD 展示层（FormationFlight 原始设计）

12. `libraries/AP_OSD/AP_OSD.h`
    - 新增 `AP_OSD_Setting radar`
    - 新增 `draw_radar()`、`draw_vdistance()`

13. `libraries/AP_OSD/AP_OSD_Screen.cpp`
    - 参数表新增 `RADAR_EN/RADAR_X/RADAR_Y`
    - 新增 `draw_radar()`：单槽位轮播显示健康 peer（约 2s 切换）
    - 新增 `draw_vdistance()`：垂直间距箭头 + 数值绘制
    - 在 `draw()` 接入 `DRAW_SETTING(radar)`
    - 风险点：
      - 原始设计为“单位置轮播”，多机并行态势感知能力有限
      - 若无健康目标，显示占位字符（可读性一般）

### 3.5 新增 AP_Radar 子系统（6 个新文件）

14. `libraries/AP_Radar/AP_Radar.h`（新增）
15. `libraries/AP_Radar/AP_Radar.cpp`（新增）
16. `libraries/AP_Radar/AP_Radar_Backend.h`（新增）
17. `libraries/AP_Radar/AP_Radar_Backend.cpp`（新增）
18. `libraries/AP_Radar/AP_Radar_MSP.h`（新增）
19. `libraries/AP_Radar/AP_Radar_MSP.cpp`（新增）

新增内容要点：
- 定义 `AP_Radar` 前端 + backend 抽象 + MSP backend
- `RADAR_MAX_PEERS = 6`，维护每个 peer 的位置/航向/速度/链路质量/更新时间
- 通过 `AP_Radar::get_peer_healthy()` 判断数据新鲜度（3s 窗口）

原始实现风险提示（你后续已修复）：
- `AP_Radar_MSP.cpp` 中使用 `uint8_t id = pkt.radar_no;` 直接下标，存在潜在越界风险（协议若 1-based 或异常包）

## 4. 与你当前分支（已完成修复版）的增量差异

相对上述 FormationFlight 原始改动，你当前分支额外做了这些关键增强：

1. `libraries/AP_OSD/AP_OSD.h`
   - 将单 `radar` 配置升级为 `AP_OSD_RadarPeers`（A~F 独立开关与坐标）

2. `libraries/AP_OSD/AP_OSD_Screen.cpp`
   - 从“单槽位轮播”改为“多槽位独立绘制 `draw_radar_peer(...)`”
   - 无有效数据时不显示占位符，避免误导
   - 缩小 `AHRS` 锁范围，降低锁竞争/死锁风险
   - 参数表重构以满足 `AP_Param` 索引与嵌套限制

3. `libraries/AP_Radar/AP_Radar_MSP.cpp`
   - 增加 `radar_no` 边界校验，避免数组越界写入

## 5. 结论与建议

- FormationFlight 相对 Plane-4.5.7 的本质是“新增 Radar 功能栈并接入 Plane/OSD/MSP”。
- 你当前版本已在其基础上完成“多目标独立显示 + 参数结构合规 + 输入边界防护”三项关键强化。
- 后续若要跟进上游新版本，建议按“先 rebase/merge，再回归验证 Radar 链路（MSP 输入、OSD 参数、飞行实测）”执行。

