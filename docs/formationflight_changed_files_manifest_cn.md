# FormationFlight 改动文件清单（相对基线 e0b6405）

本文档用于记录本分支中已修改/新增并已提交的文件，便于追踪发布内容。

## 一、代码与脚本文档改动

1. `libraries/AP_OSD/AP_OSD.h`
2. `libraries/AP_OSD/AP_OSD_Screen.cpp`
3. `libraries/AP_Radar/AP_Radar_MSP.cpp`
4. `Tools/scripts/sync_to_shared_FFardupilot.sh`
5. `docs/formationflight_osd_radar_multipeer.md`
6. `docs/formationflight_osd_radar_release_notes_cn.md`

## 二、build 产物（各目标 bin 目录）

### 目标：MatekH743

1. `build/MatekH743/bin/H743.4.5.7arduplane_with_bl.hex`
2. `build/MatekH743/bin/arduplane.apj`
3. `build/MatekH743/bin/arduplane.bin`

### 目标：MatekF405-Wing

1. `build/MatekF405-Wing/bin/F405-Wing.4.5.7.arduplane_with_bl.hex`
2. `build/MatekF405-Wing/bin/arduplane.apj`
3. `build/MatekF405-Wing/bin/arduplane.bin`

## 三、说明

- 本清单基于分支 `formationflight-osd-radar` 相对基线提交 `e0b6405` 的差异生成。
- 若后续新增其它目标板编译产物（`build/<board>/bin/*`），应在提交时同步更新本清单。

