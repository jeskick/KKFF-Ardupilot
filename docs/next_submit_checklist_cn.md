# 下次提交说明（只提交修改内容 + 编译产物）

## 目标

以后每次提交，统一遵循：

1. 只提交本次真正修改的代码/文档；
2. 同时提交对应目标板的编译产物（`build/<board>/bin` 关键文件）；
3. 不提交无关文件，不混入历史残留改动。

---

## 一、提交前流程

1. 进入仓库并更新基线：

```bash
cd /home/kk/FFardupilot
/usr/bin/git checkout master
/usr/bin/git pull
```

2. 新建本次功能分支（不要直接在 master 改）：

```bash
/usr/bin/git checkout -b feat/<本次功能名>
```

3. 完成代码修改后，编译目标板（示例）：

```bash
export PATH=/opt/gcc-arm-none-eabi-10-2020-q4-major/bin:/usr/lib/ccache:$PATH
./waf configure --board MatekH743 && ./waf plane
./waf configure --board MatekF405-Wing && ./waf plane
```

---

## 二、本次允许提交的内容

### 1) 修改内容（代码/文档）

仅 `git add` 本次相关文件，例如：

- `libraries/AP_OSD/...`
- `libraries/AP_Radar/...`
- `docs/...`
- `Tools/scripts/...`

### 2) 编译产物（按需）

每个目标板建议提交以下 3 类文件：

- `build/<board>/bin/*with_bl*.hex`
- `build/<board>/bin/arduplane.apj`
- `build/<board>/bin/arduplane.bin`

---

## 三、推荐提交命令（示例）

```bash
cd /home/kk/FFardupilot

# 1) 先添加代码与文档
/usr/bin/git add libraries/AP_OSD/AP_OSD.h \
  libraries/AP_OSD/AP_OSD_Screen.cpp \
  libraries/AP_Radar/AP_Radar_MSP.cpp \
  docs/formationflight_osd_radar_multipeer.md

# 2) 再强制添加产物（build 目录通常在 .gitignore 内）
/usr/bin/git add -f \
  build/MatekH743/bin/*with_bl*.hex \
  build/MatekH743/bin/arduplane.apj \
  build/MatekH743/bin/arduplane.bin \
  build/MatekF405-Wing/bin/*with_bl*.hex \
  build/MatekF405-Wing/bin/arduplane.apj \
  build/MatekF405-Wing/bin/arduplane.bin

# 3) 提交前检查
/usr/bin/git status --short
/usr/bin/git diff --cached --name-only

# 4) 提交
/usr/bin/git commit -m "本次功能说明（含代码改动和对应板卡产物）"
```

---

## 四、禁止项

- 不要 `git add .`（容易把无关改动一并提交）；
- 不要提交与你本次功能无关的大量文件；
- 不要在未编译验证情况下提交产物；
- 不要直接在 `master` 上开发。

---

## 五、提交后检查

1. 推送分支后确认改动文件数量是否符合预期；
2. PR 合并前检查：
   - 代码改动是否完整；
   - 产物是否为本次最新编译结果；
   - 文档是否同步更新。

