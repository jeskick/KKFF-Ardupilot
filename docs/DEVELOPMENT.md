# FFardupilot 开发分支说明

本仓库在 ArduPilot 官方源码上叠加 **编队雷达** 与 **手抛油门** 等自定义功能。  
分支按 **版本基线** 与 **功能** 两层组织，换电脑 `git clone` 后按本文操作即可继续开发。

## 分支结构

```
upstream/master (ArduPilot 官方，只读参考)
    │
    ├── base/plane-4.5.7          ← 标签 Plane-4.5.7
    ├── base/plane-4.8.0-dev      ← upstream 4.8.0-dev 快照
    │
    ├── feature/formation-radar   ← 编队功能（可 cherry-pick）
    ├── feature/takeoff-rc-throttle ← 手抛 TKOFF_RC_THR（可 cherry-pick）
    │
    ├── formationflt-4.5.7        ← 产品：4.5.7 + 编队
    ├── formationflt-4.8.0-dev    ← 产品：4.8.0-dev + 编队
    ├── tkoff-4.5.7               ← 产品：4.5.7 + 编队 + TKOFF
    └── tkoff-4.8.0-dev           ← 产品：4.8.0-dev + 编队 + TKOFF
```

### 分支含义

| 分支 | 用途 |
|------|------|
| `base/*` | 纯净 ArduPilot 版本锚点，**不要在此开发** |
| `feature/*` | 单一功能提交，便于移植到新版本 |
| `formationflt-*` | 编队成品线，日常编译编队固件 |
| `tkoff-*` | 编队 + 手抛油门实验成品线 |

## 工作目录（worktree）

| 目录 | 检出分支 | 做什么 |
|------|----------|--------|
| `FFardupilot` | `formationflt-4.8.0-dev` | 主编译环境（H7A3 等 4.8 板） |
| `FFardupilot-tkoff-rc` | `feature/takeoff-rc-throttle` | 仅改 TKOFF 功能（基于 4.5.7 编队） |

创建 worktree 示例：

```bash
git worktree add ../FFardupilot-tkoff-rc feature/takeoff-rc-throttle
git worktree add ../FFardupilot-457 formationflt-4.5.7
```

## 快速切换与编译

```bash
# 查看所有产品与功能分支
./Tools/scripts/ff_product.sh list

# 切换到某产品分支并编译
./Tools/scripts/ff_product.sh checkout formationflt-4.8.0-dev
./Tools/scripts/ff_product.sh build MatekH7A3-Wing

./Tools/scripts/ff_product.sh checkout tkoff-4.5.7
./Tools/scripts/ff_product.sh build MatekF405-Wing
```

手动方式：

```bash
git checkout formationflt-4.8.0-dev
./waf configure --board MatekH7A3-Wing
./waf plane
```

固件输出：`build/<板名>/bin/arduplane_with_bl.hex`

## 开发流程

### 只改编队功能

```bash
git checkout formationflt-4.8.0-dev   # 或 formationflt-4.5.7
# 修改 libraries/AP_Radar/ libraries/AP_OSD/ ...
git commit -m "formation: <说明>"
```

### 只改 TKOFF 手抛油门

```bash
cd FFardupilot-tkoff-rc    # 或 checkout feature/takeoff-rc-throttle
# 修改 ArduPlane/takeoff.cpp servos.cpp ...
git commit -m "feature: <说明>"
```

验证通过后，将提交 cherry-pick 到各版本产品分支：

```bash
git checkout tkoff-4.8.0-dev
git cherry-pick <commit-hash>
```

### 升级 ArduPilot 版本（例：4.9.0）

```bash
git fetch upstream
git branch base/plane-4.9.0-dev <upstream-commit>
git checkout -b formationflt-4.9.0-dev base/plane-4.9.0-dev
git cherry-pick feature/formation-radar   # 或按提交逐个 pick，解决冲突
```

## 编队相关参数

- `RADAR_TYPE = 1`（MSP）
- `OSDn_RADAR_A_EN` … `RADAR_F_*`（多同伴 OSD 槽位）

## TKOFF 相关参数

- `TKOFF_RC_THR = 1`（需配合 `TKOFF_THR_MINACC > 0`）
- 等待抖动期间 RC 油门实时输出，并捕获为本次起飞最大油门

## 新电脑克隆后

```bash
git clone <你的远程仓库> FFardupilot
cd FFardupilot
git submodule update --init --recursive
git worktree add ../FFardupilot-tkoff-rc feature/takeoff-rc-throttle
./Tools/scripts/ff_product.sh list
```

## 旧分支说明

- `ff_publish_clean`：历史发布快照（4.5.7 大提交），**不再用于日常开发**
- `formationflt-4.5.7` 上 `44fbef9d72` 仅为旧编译产物提交，产品分支已指向 `c0505c3292`
