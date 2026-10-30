# Clear AppUI development

- 最多同時啟動一台模擬器，而且只能使用本機可用的最新版 iOS runtime。
- CPU 總使用率達 50% 時，不得啟動編譯、測試、預覽編譯或其他高 CPU 工作；可繼續閱讀和編輯。
- 開發元件優先使用 Flutter Widget Preview，原生功能與最後驗收才使用模擬器／實機。
- 使用 `.fvmrc` 指定的 SDK；沒有 FVM 時，可使用完全相同版本的本機 Flutter。
- `lib/src/app_ui/` 是產品 API；產品範例使用 `package:fossui/app_ui.dart`。
- 保留上游 `Foss*` API、授權、NOTICE、字體授權及既有測試，避免不必要的改名。
- 設計值由 AppTheme 轉接既有 FossTheme，避免維護兩套 Token。
- Sheet、拖放與 presentation 的協調必須共用 host，不得在產品頁面重做。
- 新增互動附上取消、錯誤、鍵盤及跨容器測試；待驗證項目不得標成完成。
- 更新 `TODO.md`，明確區分上游已有能力、本次實作與仍待完成的項目。
