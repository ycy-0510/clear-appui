# Clear AppUI

為產品開發打造的 Flutter UI 元件庫，基於 [FossUI](https://github.com/fossui/fossui)
擴充。提供共用主題、自適應版面、浮動導覽，以及協調 Sheet、Popover 與拖放的
presentation host。設計決策參考 Apple Human Interface Guidelines。

專案目前持續開發中。已有可操作的 39 類元件目錄與課程互動示範；完整功能與
驗收進度見 [TODO](TODO.md)。

## 從 GitHub 安裝

目前透過 GitHub 使用這個 fork。將以下內容加入應用程式的 `pubspec.yaml`：

```yaml
dependencies:
  flutter:
    sdk: flutter
  fossui:
    git:
      url: https://github.com/ycy-0510/clear-appui.git
      ref: main
```

然後執行：

```bash
flutter pub get
```

`main` 提供目前的 Clear AppUI 版本。正式產品可以將
`ref` 換成已驗證的完整 commit SHA，固定使用的版本；分支更新則執行
`flutter pub upgrade fossui`。

**Repo 名稱是 `clear-appui`，Dart 套件識別仍是 `fossui`**，沿用現有 import
與上游 API。`flutter pub add fossui` 會安裝 pub.dev 上的上游版本；本 fork
請使用上面的 Git dependency。

## 開始使用

產品元件由 `package:fossui/app_ui.dart` 匯出：

```dart
import 'package:flutter/cupertino.dart';
import 'package:fossui/app_ui.dart';

void main() => runApp(
  CupertinoApp(
    home: AppTheme(
      child: CupertinoPageScaffold(
        child: Center(
          child: AppButton(
            onPressed: () {},
            child: const AppText('開始使用'),
          ),
        ),
      ),
    ),
  ),
);
```

`AppTheme` 預設跟隨系統明暗設定，也可指定 `AppThemeData.light` 或
`AppThemeData.dark`。產品的顏色、字體、間距與圓角共用既有 FossTheme token
來源。底層 `Foss*` 元件可從 `package:fossui/fossui.dart` 使用。

使用 Sheet 與拖放時，將 `AppPresentationHost` 放在對應 route 的 `AppTheme`
之下。Sheet 的列表需接上它提供的 `ScrollController`。完整組合方式見
[開發指南](doc/app_ui/DEVELOPMENT.md#composition-contract)。

## 目前提供的能力

| 範圍 | 內容 |
| --- | --- |
| 產品基礎 | `AppTheme`、明暗主題、尺寸與動畫設定、平台觸覺 adapter。 |
| 常用元件 | `AppButton`、`AppText`、`AppIcon`、`AppCard`、`AppBadge`、`AppTextField`、`AppCheckbox`、`AppSwitch`、`AppListTile`、`AppEmptyState`。 |
| 版面與導覽 | `AppAdaptiveLayout`、`AppConstrainedContent`、`AppAdaptiveGrid`、`AppScaffold`、`AppNavigationBar`。 |
| 呈現與互動 | 共用 presentation host、多段高度 `AppSheet`、`AppPopover`、自適應 `AppDatePicker`、型別化拖放與取消流程。 |
| 底層元件 | 保留上游 39 類元件，涵蓋輸入、選擇器、回饋、浮層、版面與媒體。 |
| 示範與 QA | 可搜尋的完整目錄、明暗／2× 字體／RTL／長內容控制，以及課程安排互動。 |

39 類底層元件與產品 `App*` API 的範圍分開記錄；逐項來源、修正與已驗證場景見
[元件 QA 紀錄](doc/app_ui/COMPONENT_QA.md)。

## Widget Preview

開發使用 `.fvmrc` 指定的 **Flutter 3.47.8 / Dart 3.13.7**。可使用 FVM，或
完全相同版本的本機 Flutter；下列指令中的 `flutter` 須指向該版本。
Preview 啟動補救腳本另需 Node.js 22 或更新版本。

```bash
git clone https://github.com/ycy-0510/clear-appui.git
cd clear-appui
flutter pub get
cd example
flutter pub get
cd ..
bash scripts/dev/preview.sh
```

開啟終端機印出的網址即可互動。九種預覽涵蓋手機明暗、平板、大字體、產品狀態，
以及三種可切換全部 39 類元件的目錄。修改來源後支援 hot reload。

Widget Preview 會編譯獨立的 Web 預覽，不需產出 iOS App 或啟動模擬器。
支援的 IDE 也可讀取 [`example/lib/previews.dart`](example/lib/previews.dart)
內的預覽標註。

## macOS 示範

在 repo 根目錄執行：

```bash
bash scripts/dev/check-cpu.sh
cd example
flutter run -d macos
```

- 「完整元件庫」：搜尋元件、切換明暗、2× 字體、RTL 與長內容。
- 「課程互動」：展開／收合 Sheet、拖曳課程、使用替代的「安排」操作，以及
  寬畫面的雙欄版面。

## 設計與驗證

Sheet 的材質、邊距與圓角隨高度連續變化；導覽項目提供完整點擊區域與即時選取。
設定值由共用 theme 管理。Apple 官方依據與 Flutter 材質的實作界線見
[HIG 設計筆記](doc/app_ui/APPLE_HIG_NOTES.md)。

最近一輪完整紀錄為套件 1,324 項測試（含 78 項 Golden）及 Example 290 項通過，
靜態分析無問題。這是指定場景的回歸結果；最新 iOS 的觸控、VoiceOver、原生
鍵盤及觸覺仍待裝置驗收。可重跑的命令與限制見
[開發指南](doc/app_ui/DEVELOPMENT.md#resource-limits-and-validation)。

執行編譯、測試或啟動 Preview 前先檢查 CPU，工作依序執行。最多同時啟動一台
模擬器，且只使用本機最新的 iOS runtime。

## Agent Skill 規劃

預計採用通用的 Agent Skills 格式，讓不同 AI agent 讀取同一套元件使用規則：

- 先查本套件的實際 API 與範例，優先組合現成的 `App*`／`Foss*` 元件。
- 使用共用 theme 與 HIG 設計原則處理版面、間距與無障礙。
- 檢查專案的 Git dependency 與版本，再進行 Preview 和適當驗證。
- 透過 NPX 安裝流程選擇目標 agent，並與套件版本配對。

**Skill 與 NPX 安裝流程尚未實作。** 目前安裝 UI 套件請使用上方的 GitHub
方式。Skill 指令與 Dart 套件安裝會分別驗證，進度列在 [TODO](TODO.md)。
規劃參考 [Agent Skills 規格](https://agentskills.io/specification) 與
[Vercel Skills CLI](https://github.com/vercel-labs/skills)。

## 文件與授權

- [完整需求與 To Do](TODO.md)
- [開發、Preview、API 組合與驗證](doc/app_ui/DEVELOPMENT.md)
- [39 類元件逐項 QA](doc/app_ui/COMPONENT_QA.md)
- [Apple HIG 設計筆記](doc/app_ui/APPLE_HIG_NOTES.md)
- [貢獻指南](CONTRIBUTING.md)與[變更紀錄](CHANGELOG.md)

Clear AppUI 是獨立維護的 FossUI fork。上游為
[`fossui/fossui`](https://github.com/fossui/fossui)，設為 Git `upstream`。
本專案採 MIT 授權，保留原始作者及 coss.com/ui、Base UI、shadcn/ui 的來源聲明。
分發時請保留 [LICENSE](LICENSE)、[NOTICE](NOTICE) 與 Geist 的
[SIL Open Font License](fonts/OFL.txt)。
