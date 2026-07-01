# FFardupilot 开发分支说明

本仓库在 ArduPilot 官方源码上叠加 **编队雷达（FF_RADAR）** 与 **手抛油门（FF_TKOFF）** 等独立模块。  
分支分 **三层**：`base` → `feature` → `product`。总览见根目录 **`FFARDUPILOT.md`**。

## 三层结构

```
upstream/master
    │
    ├─ base/ardupilot.4.5.7              纯净 4.5.7
    ├─ base/ardupilot.4.7.0beta7          纯净 4.7.0-beta7
    │
    ├─ feature/FF_RADAR                 编队雷达（独立模块）
    ├─ feature/FF_TKOFF                 手抛 TKOFF（独立模块）
    │
    ├─ ardupilot.4.5.7_FF_RADAR
    ├─ ardupilot.4.5.7_FF_RADAR_TKOFF
    ├─ ardupilot.4.7.0beta7_FF_RADAR      ← 当前主线
    └─ ardupilot.4.7.0beta7_FF_RADAR_TKOFF
```

| 层级 | 分支 | 用途 |
|------|------|------|
| base | `base/ardupilot.*` | 官方版本锚点，**不要开发** |
| feature | `feature/FF_RADAR` | 只改编队，改完 cherry-pick 到产品 |
| feature | `feature/FF_TKOFF` | 只改 TKOFF，改完 cherry-pick 到 `*_TKOFF` 产品 |
| product | `ardupilot.<ver>_FF_*` | 日常编译刷机 |

## 工作目录（worktree）

| 目录 | 分支 | 用途 |
|------|------|------|
| `FFardupilot` | `ardupilot.4.7.0beta7_FF_RADAR` | 主编译（4.8 + 编队） |
| `FFardupilot-tkoff-rc` | `feature/FF_TKOFF` | 只改 TKOFF 模块 |
| `FFardupilot-FF_RADAR`（可选） | `feature/FF_RADAR` | 只改编队模块 |

```bash
git worktree add ../FFardupilot-FF_RADAR feature/FF_RADAR
git worktree add ../FFardupilot-tkoff-rc feature/FF_TKOFF
```

## 快速编译

```bash
./Tools/scripts/ff_product.sh list

./Tools/scripts/ff_product.sh build MatekH7A3-Wing ardupilot.4.7.0beta7_FF_RADAR
./Tools/scripts/ff_product.sh build MatekF405-Wing ardupilot.4.5.7_FF_RADAR
./Tools/scripts/ff_product.sh build MatekF405-Wing ardupilot.4.5.7_FF_RADAR_TKOFF
./Tools/scripts/ff_product.sh build MatekH7A3-Wing ardupilot.4.7.0beta7_FF_RADAR_TKOFF
```

固件：`build/<板名>/bin/arduplane_with_bl.hex`

## 开发流程

### 改编队模块

```bash
git checkout feature/FF_RADAR    # 或 cd FFardupilot-FF_RADAR
# 改 libraries/AP_Radar/ libraries/AP_OSD/ ...
git commit -m "feature/FF_RADAR: <说明>"

# 合并到各产品分支
git checkout ardupilot.4.7.0beta7_FF_RADAR
git cherry-pick <commit>
```

### 改 TKOFF 模块

```bash
cd FFardupilot-tkoff-rc    # feature/FF_TKOFF
# 改 ArduPlane/takeoff.cpp servos.cpp ...
git commit -m "feature/FF_TKOFF: <说明>"

git checkout ardupilot.4.7.0beta7_FF_RADAR_TKOFF
git cherry-pick <commit>
```

### 升级 ArduPilot 版本

```bash
git fetch upstream
git branch base/ardupilot.4.9.0dev <upstream-commit>
git checkout -b ardupilot.4.9.0dev_FF_RADAR base/ardupilot.4.9.0dev
git cherry-pick feature/FF_RADAR   # 解决冲突后提交
```

## 同步官方代码

见 `FFARDUPILOT.md` 第七节：`git fetch upstream` + `git merge upstream/master`  
**不要用** GitHub 的 Sync fork。

## 编队 / TKOFF 参数

- `RADAR_TYPE = 1`，`OSDn_RADAR_A_EN` … `RADAR_F_*`
- `TKOFF_RC_THR = 1`（需 `TKOFF_THR_MINACC > 0`）

## 新电脑克隆

```bash
git clone https://github.com/jeskick/KKFF-Ardupilot.git FFardupilot
cd FFardupilot
git checkout ardupilot.4.7.0beta7_FF_RADAR
git submodule update --init --recursive
git worktree add ../FFardupilot-tkoff-rc feature/FF_TKOFF
./Tools/scripts/ff_product.sh list
```
