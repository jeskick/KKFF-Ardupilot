# FFardupilot 项目说明

本仓库基于 [ArduPilot](https://ardupilot.org) 官方源码，叠加 **编队雷达 OSD**、**手抛起飞 RC 油门**、**Matek H7A3 板载电流计** 等自定义改动，用于固定翼编队飞行与手抛实验。

官方 ArduPilot 说明见根目录 `README.md`；**本文档只描述我们额外做了什么、如何选分支和编译**。

---

## 一、项目里有什么

### 1. 与上游的关系

| 项目 | 说明 |
|------|------|
| 上游 | `upstream` → [ArduPilot/ardupilot](https://github.com/ArduPilot/ardupilot) |
| 基线版本 | **4.5.7**（稳定）、**4.8.0-dev**（开发，当前主线） |
| 车机类型 | 主要维护 **ArduPlane**（固定翼） |

### 2. 分支结构（三层）

```
upstream/master（官方，只读参考）
    │
    ├── base/plane-4.5.7              纯净 4.5.7 锚点
    ├── base/plane-4.8.0-dev          纯净 4.8.0-dev 锚点
    │
    ├── feature/formation-radar       编队功能（单功能，便于移植）
    ├── feature/takeoff-rc-throttle   手抛 TKOFF_RC_THR（单功能）
    │
    ├── formationflt-4.5.7              ← 产品：4.5.7 + 编队（旧名，待统一）
    ├── ardupilot.4.8.5dev_FF_RADAR     ← 产品：4.8.x-dev + 编队  ← 当前主线
    ├── tkoff-4.5.7                     ← 产品：4.5.7 + 编队 + TKOFF
    └── tkoff-4.8.0-dev                  ← 产品：4.8.x-dev + 编队 + TKOFF
```

### 产品分支命名规则

| 分支名 | 含义 |
|--------|------|
| `ardupilot.<版本>dev_FF_RADAR` | 官方 ArduPilot + 编队雷达（FF = FormationFlight） |
| `ardupilot.<版本>dev_FF_RADAR_TKOFF` | 上者 + 手抛油门（规划中，`tkoff-4.8.0-dev` 待改名） |
| `formationflt-*` / `tkoff-*` | 旧命名，逐步废弃 |

| 分支类型 | 用途 |
|----------|------|
| `base/*` | 版本锚点，**不要在此开发** |
| `feature/*` | 单一功能，改完后 cherry-pick 到各版本产品分支 |
| `formationflt-*` | 编队成品线（旧名） |
| `ardupilot.*_FF_RADAR` | 编队成品线（新命名） |
| `tkoff-*` | 编队 + 手抛油门实验成品线 |

### 3. 工作目录（worktree）

| 目录 | 分支 | 用途 |
|------|------|------|
| `FFardupilot` | `ardupilot.4.8.5dev_FF_RADAR` | 主编译环境（H7A3 等 4.8 板） |
| `FFardupilot-tkoff-rc` | `feature/takeoff-rc-throttle` | 单独开发 TKOFF 功能（基于 4.5.7 编队） |

---

## 二、我们做了哪些功能

### 功能 1：编队多同伴雷达 OSD（Formation Radar）

**作用：** 编队飞行时，通过 MSP 接收多架同伴的位置信息，在 OSD 上 **A~F 六个槽位独立显示**，无数据时不占位。

**主要参数：**

| 参数 | 说明 |
|------|------|
| `RADAR_ENABLE` | 启用雷达 |
| `RADAR_TYPE = 1` | MSP 输入 |
| `OSDn_RADAR_A_EN` … `RADAR_F_Y` | 六个同伴 OSD 位置 |

**涉及文件：**

| 路径 | 说明 |
|------|------|
| `libraries/AP_Radar/` | 新增雷达库（6 路 peer） |
| `libraries/AP_MSP/` | MSP 雷达报文解析 |
| `libraries/AP_OSD/` | OSD A~F 槽位绘制 |
| `ArduPlane/Plane.*` `system.cpp` `Parameters.*` | Plane 集成 |
| `docs/formationflight_osd_radar_multipeer.md` | 详细设计说明 |

**所在分支：** `feature/formation-radar`；已合并进所有 `formationflt-*` 和 `tkoff-*` 产品分支。

---

### 功能 2：手抛起飞 RC 油门（TKOFF_RC_THR）

**作用：** TAKEOFF 模式 + 摇杆抖动解锁（`TKOFF_THR_MINACC > 0`）时：

- `TKOFF_RC_THR = 0`：等待期间油门为 0，起飞用默认油门
- `TKOFF_RC_THR = 1`：等待期间跟随 RC 油门；检测到抛飞后 **捕获当前油门** 作为本次起飞最大油门

**主要参数：** `TKOFF_RC_THR`（需配合 `TKOFF_THR_MINACC > 0`）

**涉及文件：**

| 路径 | 说明 |
|------|------|
| `ArduPlane/takeoff.cpp` | 核心逻辑 |
| `ArduPlane/servos.cpp` | 等待期间油门透传 |
| `ArduPlane/mode_takeoff.cpp` `mode.h` | 模式进入/退出重置 |
| `ArduPlane/Plane.h` `Parameters.*` | 参数与状态 |

**所在分支：** `feature/takeoff-rc-throttle`；已合并进 `tkoff-4.5.7`、`tkoff-4.8.0-dev`。**未**包含在 `formationflt-*` 中。

---

### 功能 3：Matek H7A3 板载 INA2xx 电流计（仅 4.8 产品分支）

**作用：** H7A3 / H7A3-Wing 主电池默认走板载 **I2C INA2xx**，刷固件后无需再手动设 `BATT_MONITOR` 等参数，电流一般免校准。

**固件默认值：**

| 参数 | 值 |
|------|-----|
| `BATT_MONITOR` | 21（INA2xx） |
| `BATT_SHUNT` | 0.00025 |
| `BATT_MAX_AMPS` | 164 |
| `BATT_I2C_BUS` | 0 |
| `BATT_I2C_ADDR` | 0（自动探测 0x45） |

**涉及文件：**

| 路径 | 说明 |
|------|------|
| `libraries/AP_HAL_ChibiOS/hwdef/MatekH7A3/hwdef.inc` | 硬件默认（Wing 板共用） |
| `libraries/AP_HAL_ChibiOS/hwdef/MatekH7A3*/README.md` | 板级说明 |

**所在分支：** `ardupilot.4.8.5dev_FF_RADAR`（及基于它衍生的 `tkoff-4.8.0-dev`）。

---

## 三、产品分支对照表（怎么选）

| 我要… | 检出分支 | 典型板型 | ArduPlane 版本 |
|--------|----------|----------|----------------|
| 编队 + H7A3 + 板载电流计 | `ardupilot.4.8.5dev_FF_RADAR` | `MatekH7A3-Wing` | 4.8.x-dev |
| 只要编队（4.5.7 稳定） | `formationflt-4.5.7` | `MatekF405-Wing` | 4.5.7 |
| 编队 + 手抛油门（4.8） | `tkoff-4.8.0-dev` | `MatekH7A3-Wing` | 4.8.0-dev |
| 编队 + 手抛油门（4.5.7） | `tkoff-4.5.7` | `MatekF405-Wing` | 4.5.7 |
| 只改编队逻辑 | `feature/formation-radar` | — | — |
| 只改 TKOFF | `feature/takeoff-rc-throttle` | — | — |

---

## 四、如何编译

### 环境要求

- Python 3.9+（推荐 3.10）
- ARM GCC **10.2.1**（路径示例：`/opt/gcc-arm-none-eabi-10-2020-q4-major/bin`）
- 建议 PATH 前置：`/usr/lib/ccache`
- 子模块已初始化：`git submodule update --init --recursive`

### 方式 A：一键脚本（推荐）

```bash
# 查看所有分支与当前 HEAD
./Tools/scripts/ff_product.sh list

# 切到产品分支并编译
./Tools/scripts/ff_product.sh build MatekH7A3-Wing ardupilot.4.8.5dev_FF_RADAR

# 编队 + TKOFF（4.8）
./Tools/scripts/ff_product.sh build MatekH7A3-Wing tkoff-4.8.0-dev

# 编队（4.5.7 F405）
./Tools/scripts/ff_product.sh build MatekF405-Wing formationflt-4.5.7
```

固件输出：

```
build/<板名>/bin/arduplane_with_bl.hex
```

### 方式 B：手动 waf

```bash
git checkout ardupilot.4.8.5dev_FF_RADAR
export PATH="/usr/lib/ccache:/opt/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH"
./waf configure --board MatekH7A3-Wing
./waf plane
```

---

## 五、修改汇总（相对官方 ArduPilot）

### 4.8.x-dev 产品分支 `ardupilot.4.8.5dev_FF_RADAR` 相对 `base/plane-4.8.0-dev`

| 提交 | 内容 |
|------|------|
| `978e35ae46` | 编队雷达完整移植到 4.8（AP_Radar、MSP、OSD、Plane 集成） |
| `de6ffc2ad9` | 分支说明 `docs/DEVELOPMENT.md` + 编译脚本 `ff_product.sh` |
| `395c5aaf22` | H7A3 默认 INA2xx I2C 电流计 |

### 4.5.7 产品分支 `formationflt-4.5.7` 相对 `base/plane-4.5.7`

| 提交 | 内容 |
|------|------|
| `a4332e2f38` | FormationFlight 合入 |
| `c0505c3292` | 多同伴雷达 OSD 与安全检查增强 |

### TKOFF 功能（`tkoff-*` 分支在编队之上额外包含）

| 提交 | 内容 |
|------|------|
| `7a805dd502` / `2c4eac3177` | `TKOFF_RC_THR` 手抛 RC 油门捕获 |

---

## 六、开发流程简表

| 任务 | 操作 |
|------|------|
| 改编队 | 在 `ardupilot.4.8.5dev_FF_RADAR` 改 `libraries/AP_Radar/` 等 → 提交 |
| 改 TKOFF | 在 `FFardupilot-tkoff-rc` 改 `ArduPlane/takeoff.cpp` 等 → cherry-pick 到 `tkoff-*` |
| 同步官方小更新 | 见下方 **第七节**（`fetch upstream` + `merge`） |
| 升级 ArduPilot 大版本 | 新建 `base/plane-x.y.z` → cherry-pick `feature/*` → 新建 `formationflt-x.y.z` |
| 新电脑开始 | `git clone` → `submodule update --init --recursive` → `ff_product.sh list` |

更细的分支与 cherry-pick 说明见 **`docs/DEVELOPMENT.md`**。

---

## 七、同步官方 ArduPilot 新代码（二次开发）

本仓库是**二次开发**：改动只留在自己的 fork，**不需要**合并回上级，也**不需要**向父 fork 提 PR。

### 不要做的事

| 操作 | 原因 |
|------|------|
| GitHub 页 **Sync fork** | 针对父 fork（如 MUSTARDTIGERFPV），不是你的日常同步方式 |
| **Discard N commits** | 会删掉自己的 ArduPilot 基线和编队改动 |
| 向 `formationflight` push | 除非明确要和对方的 fork 对齐 |

页面上 `15739 commits ahead of MUSTARDTIGERFPV/ardupilot` 只表示你和**那个 fork** 历史不同，可忽略。

### 两个「上级」怎么选

| 远程 | 指向 | 何时使用 |
|------|------|----------|
| **`upstream`** | [ArduPilot/ardupilot](https://github.com/ArduPilot/ardupilot) 官方 | ✅ **日常同步新代码用这个** |
| `formationflight` | MUSTARDTIGERFPV 的 fork | 仅当需要跟对方 fork 对齐时 |
| `jeskick` | 你自己的 `KKFF-Ardupilot` | 推送自己的分支 |

### 同步官方 master 到产品分支（4.8 示例）

```bash
cd /home/kk/FFardupilot

# 建议用系统 git（~/.local/git 可能缺 git-remote-https）
/usr/bin/git fetch upstream

/usr/bin/git checkout ardupilot.4.8.5dev_FF_RADAR
/usr/bin/git merge upstream/master
```

有冲突时解决后：

```bash
/usr/bin/git add <冲突文件>
/usr/bin/git commit    # 完成 merge 提交
```

编译验证：

```bash
./Tools/scripts/ff_product.sh build MatekH7A3-Wing
```

推到自己 fork：

```bash
/usr/bin/git push jeskick ardupilot.4.8.5dev_FF_RADAR
```

### 4.5.7 稳定线同步

```bash
/usr/bin/git fetch upstream
/usr/bin/git checkout formationflt-4.5.7
/usr/bin/git merge Plane-4.5.7    # 或 upstream 上对应稳定标签的最新修复分支
./Tools/scripts/ff_product.sh build MatekF405-Wing
/usr/bin/git push jeskick formationflt-4.5.7
```

### 合并冲突时优先保留自己的文件

| 路径 | 说明 |
|------|------|
| `libraries/AP_Radar/` | 编队雷达库（整目录保留我方） |
| `libraries/AP_OSD/` | 雷达 OSD 绘制相关改动 |
| `libraries/AP_MSP/` | MSP 雷达报文相关改动 |
| `ArduPlane/Plane.*` `system.cpp` `Parameters.*` | 编队集成 |
| `hwdef/MatekH7A3/` | H7A3 板载 INA2xx 等硬件默认 |

其余文件（官方驱动、通用库等）一般接受官方版本。

### 查看与官方差多少提交

```bash
/usr/bin/git fetch upstream
/usr/bin/git log --oneline ardupilot.4.8.5dev_FF_RADAR..upstream/master   # 官方有、你还没有的
/usr/bin/git log --oneline upstream/master..ardupilot.4.8.5dev_FF_RADAR   # 你自己的定制提交
```

---

## 八、相关文档索引

| 文档 | 内容 |
|------|------|
| **`FFARDUPILOT.md`**（本文） | 项目总览、功能、分支、编译 |
| `docs/DEVELOPMENT.md` | 分支结构、worktree、开发流程 |
| `docs/formationflight_osd_radar_multipeer.md` | 编队雷达 OSD 设计与参数 |
| `Tools/scripts/ff_product.sh` | 分支列表 / 切换 / 编译脚本 |
| `libraries/AP_HAL_ChibiOS/hwdef/MatekH7A3-Wing/README.md` | H7A3-Wing 硬件与电池说明 |

---

## 九、远程仓库与推送

常用 remote：

| 名称 | 地址 |
|------|------|
| `upstream` | ArduPilot 官方 |
| `origin` | 自有 fork（按本机 `git remote -v` 为准） |
| `jeskick` | KKFF-Ardupilot fork |

推送产品分支示例：

```bash
git push -u jeskick ardupilot.4.8.5dev_FF_RADAR
```

---

## 十、旧分支（勿用于日常开发）

- `ff_publish_clean`：历史 4.5.7 大发布快照
- 仅含编译产物、无功能差异的旧提交

日常请使用 **`ardupilot.*_FF_RADAR`** 产品分支（旧名 `formationflt-*` / `tkoff-*` 仍可用）。
