# 掘进助手 (TunnelMate)

掘进一线技术员辅助管理App，支持人员管理、考勤打卡、值班排班等功能，完全离线运行。

## 功能

- 人员信息管理（录入、编辑、搜索、筛选）
- 考勤管理（打卡、批量点名、月度统计）
- 值班排班（日历视图、手动排班）
- 数据备份与导出

## 使用方式

### 方式一：GitHub Actions自动编译（推荐）

1. Fork本仓库到你的GitHub账号
2. 进入仓库的 Actions 页面
3. 点击 "Build APK" 工作流，再点击 "Run workflow"
4. 等待约5分钟后，在 Artifacts 中下载 APK 文件

### 方式二：本地编译

```bash
flutter pub get
flutter build apk --release
```

APK文件路径：`build/app/outputs/flutter-apk/app-release.apk`
