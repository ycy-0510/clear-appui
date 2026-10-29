# Flutter Custom UI Library — To Do

依據使用者完整製作計畫，採 FossUI fork + 自有 AppUI 公開介面。
`[x]` 表示已有可檢查的產出；測試與裝置驗收另列，不能以實作取代驗證。

## 0. Repository 與開發流程
- [x] Fork `fossui/fossui` → `ycy-0510/clear-appui`（原名 `fossui`），保留 Git 歷史及 upstream。
- [x] 保存完整原始需求：`doc/app_ui/original-plan.txt`。
- [x] 寫入單台模擬器、最新版 iOS、CPU 負載限制與 Preview 優先規則。
- [x] 提供明暗主題、手機、平板、大字體及核心互動 Widget Previews。
- [x] 實際啟動六種預覽並確認來源修改熱更新。
- [x] 整理開發指令、API 範例與能力界線。

## 1. Foundation（原計畫 4）
- [x] 上游已有語意顏色、字體、間距、圓角、陰影、動畫及明暗主題。
- [x] AppTheme 單一設計來源與局部覆寫。
- [x] AppDimensions：觸控尺寸、內容寬度、欄寬、導航高度。
- [x] AppMotion：Reduce Motion 與按壓規則。
- [ ] 字體角色、中英文混排及數字樣式。
- [ ] 系統主題切換、High Contrast、Theme interpolation 回歸驗證。

## 2. Components（原計畫 5）
- [x] 上游已有 Button、Text、Badge、Card、TextField、Checkbox、Radio、Switch。
- [x] 上游已有 Chip、ListTile、Avatar、Progress、Spinner、Skeleton、Separator。
- [x] AppButton：variants、非同步提交防重、錯誤回呼、按壓取消、鍵盤及語意。
- [x] AppText、AppIcon、AppCard、AppBadge、AppTextField 穩定介面。
- [x] AppCheckbox、AppSwitch、AppListTile 與狀態呈現介面。
- [ ] AppIconButton、文字按鈕、ButtonGroup、FloatingActionButton。
- [ ] TextArea、Search、Password、NumberField 與完整表單驗證狀態。
- [ ] Radio、SegmentedControl、ChoiceChip、FilterChip、SelectableListItem。
- [ ] ListSection、InsetDivider、滑動操作與拖曳排序。
- [ ] EmptyState、ErrorState、Retry、Tooltip、Image、SelectableText。
- [ ] 每個產品 API 的使用範例、互動測試與 Golden baseline。

## 3. Adaptive Layout（原計畫 6）
- [ ] AppLayoutEnvironment：父層可用空間、600/840 size class、insets。
- [x] AppAdaptiveLayout：單／雙欄、欄比例、空間不足降級與手動覆寫。
- [ ] ConstrainedContent、AdaptiveGrid、ResponsiveVisibility。
- [x] AppScaffold：Safe Area、鍵盤、浮動導航、內容末端可達。
- [ ] 平板主從內容、NavigationRail、Sidebar、三欄。
- [ ] DisplayFeature 避讓、hinge 分區與姿態變更；不依裝置名稱猜測。

## 4. Navigation（原計畫 7）
- [x] AppNavigationBar：整格點擊、同步選取、標籤、Badge slot、鍵盤及可選觸覺。
- [ ] Badge 複合無障礙標籤與實機觸覺驗收。
- [x] 明確區分 reservedSpace / overlay 模式。
- [ ] Rail、Sidebar、TabBar、TopBar、BackButton、轉場。
- [ ] 與既有 Router 整合 deep link、返回及頁面狀態保留。

## 5. Presentation 與 Overlay（原計畫 8、11）
- [x] 上游已有 Dialog、Drawer、Popover、焦點與 Escape 基礎。
- [x] 共用 AppPresentationHost：層級、開關、結果、焦點與生命週期。
- [x] AppSheet：多段比例／固定高度、吸附、handle、列表捲動協調。
- [ ] Sheet 鍵盤、安全區域、向下關閉、取消及 Reduce Motion。
- [x] 非 modal Sheet 支援外層目標；modal Sheet 拖曳期間放行底層目標。
- [ ] Content-fit / custom detent、floating / side / centered presentation。
- [ ] Nested Navigator、路由離開、背景清理、多 Sheet 堆疊。
- [x] AppPopover：anchor、邊界、空間不足自動轉 Sheet、Escape。
- [ ] Alert / Confirm / Form / Destructive / Loading Dialog。
- [ ] ContextMenu：長按、右鍵、快捷鍵與 disabled / destructive。

## 6. Drag and Drop（原計畫 10）
- [x] AppDragCoordinator、Session、State、取消與接受／拒絕。
- [x] AppDraggable<T>、AppDropTarget<T>、root Overlay Preview。
- [ ] 跨列表、跨欄、Sheet 內到外層／另一個 Sheet。
- [x] 拖曳時不誤觸 Sheet resize / dismiss、不被來源裁切。
- [ ] Drop acceptance、錯誤還原、移除來源與生命週期清理。
- [ ] 拖曳邊界自動捲動與排序動畫。
- [x] 鍵盤／螢幕閱讀器可用的替代移動操作。
- [ ] 原生跨 App 拖放 Adapter（後續階段）。

## 7. Pickers（原計畫 9）
- [x] 上游已有 Calendar、DatePicker、TimePicker、日期範圍及日期限制。
- [x] AppDatePicker：手機 Sheet / 寬畫面 Popover，邏輯與呈現分開。
- [ ] AppTimePicker：12/24、小時／分鐘間隔、上下界、鍵盤輸入。
- [ ] Compact / Inline / Range / Month-Year、Locale 與週起始日。

## 8. Feedback 與 Platform（原計畫 12、13）
- [x] 上游已有 Toast、Alert、Loading、Progress 與 Skeleton。
- [x] AppHaptics 與平台能力查詢；Preview 使用無副作用實作。
- [ ] Success / Warning / Error 觸覺的原生能力與明確降級。
- [ ] 統一 Toast queue、Undo、無障礙朗讀與 Loading Overlay。
- [ ] Foldable Adapter、姿態事件、不可用時降級。
- [ ] Native ContextMenu / DragDrop / SystemInsets 的 capability adapters。
- [ ] 原生 API 依實際平台／SDK 驗證，不承諾未確認的特定裝置能力。

## 9. Accessibility 與測試（原計畫 14、15）
- [x] 新增功能的 unit / widget tests：detents、breakpoints、drag lifecycle。
- [ ] Sheet → 外層接受、拒絕、取消、捲動、鍵盤與多尺寸互動回歸。
- [ ] Focus、Escape / Back、Dynamic Type、Reduce Motion 與觸控目標。
- [ ] Golden：Light / Dark、不同寬度與字體大小。
- [x] 靜態分析與既有上游測試回歸（單 worker）。
- [ ] iOS 最新 runtime 單台模擬器驗收（CPU 許可時）。
- [ ] Android、平板、折疊及原生能力實機驗收。

## 10. 第一個可交付版本（原計畫 16–20）
- [x] 課程管理範例：手機列表 → Sheet → 拖到日期／分類。
- [x] 同一頁面在寬畫面轉為雙欄，Picker 改用 Popover。
- [ ] 替代移動操作、取消、錯誤、明暗主題與鍵盤可用。
- [x] 既有 39 項元件的完整 Gallery：variants、states、尺寸及明暗主題。
- [ ] API 文件、變更紀錄、版本相容性規則與產品試用。

依原計畫增量交付；尚未勾選的進階功能與裝置驗收仍是工作項目。

## 本輪新增要求與驗證紀錄
- [x] iOS Runner 的 `ITSAppUsesNonExemptEncryption` 為 Boolean false，plutil 通過。
- [x] macOS Runner 同樣宣告 false，plutil 通過。
- [x] macOS 示範入口可切換「完整元件庫」及「課程互動」。
- [x] 更新 example 圖示套件，修正 Flutter 3.47 IconData final 相容性。
- [x] 1,236 項非 Golden 回歸測試通過（單 worker）。
- [x] macOS 視窗實際操作、grabber 展開／收合與 hot reload / restart 驗證。
- [x] 新增明暗 Golden baseline 並檢視；78 項 Golden 測試通過。

## HIG 與 Sheet 修正（2026-10-29）
- [x] 下載並查閱 Apple 官方 Sheets / Materials Markdown 與 WWDC25 設計說明。
- [x] 以 HIG 的材質與層級原則調整；使用者舉例的 50% 不作為硬性門檻。
- [x] 邊距、連續圓角與玻璃通透感跟隨高度平順變化。
- [x] Grabber 支援點按循環、上下鍵與無障礙調整；高度語意即時更新。
- [x] 修正縮小 Sheet 時 viewport correction 中斷吸附動畫。
- [x] 15 項 AppUI 核心與材質測試通過；原生示範無 runtime errors。
- [x] 小型 Sheet 改用緊湊列表，Mac 滑鼠可直接拖曳。
- [x] 移除開發用 DEBUG 角標。

## 導覽與視覺修正（2026-10-29）
- [x] 查閱官方 Tab bars / Accessibility / Adopting Liquid Glass。
- [x] 修正底層 FossButton：透明留白也包含在承諾的點擊區域內。
- [x] 導覽分頁整格可點、立即回應；切換不進入非同步 loading gate。
- [x] 按下、hover、焦點、取消及無障礙 selected 狀態。
- [x] 大視窗限制導覽寬度、圖文橫排；大字體可增高並預留內容空間。
- [x] 切換分頁保留輸入與捲動狀態。
- [x] 課程頁改為群組列表，移除重複卡片說明，統一頁邊距與內距。
- [x] 明暗產品主題、主要操作色、容器與控制項圓角、48px 按鈕與輸入框。
- [x] Mac 實際點擊兩個分頁的邊緣空白區都可正常切換。
- [x] 新增四邊點擊／快速切換、取消／鍵盤、兩倍字體／內容避讓、頁面狀態回歸測試。

### 本輪驗證結果
- [x] 完整 1,241 項非 Golden 回歸通過；最後鍵盤留白修正另跑 17 項專項測試通過。
- [x] 78 項 Golden 回歸通過，僅更新此次改版的兩張 AppUI 明暗基準。
- [x] 範例 App 切換測試通過；flutter analyze 無問題；git diff --check 通過。
- [x] Native hot reload 成功，未發現 runtime errors。
- [x] 六種 Widget Preview 實際呈現，修改預覽名稱後正常 hot reload。
- [x] 啟動腳本加入空預覽快取時的 DTD/LSP 查詢補救；Node 22 腳本實測讀取六種預覽。
- [x] 全程未啟動模擬器；編譯、回歸與預覽依序執行並檢查 CPU。

## 完整元件庫逐項 QA（2026-10-29）

逐項來源、場景、證據與限制見 [COMPONENT_QA.md](doc/app_ui/COMPONENT_QA.md)。

- [x] 盤點 35 個元件資料夾、39 個族群，單／多選分列，群組納入控制項。
- [x] 完整 Gallery 改為逐項目錄，支援搜尋、明暗、2× 字體、RTL、長內容。
- [x] 桌面側欄／窄版搜尋選擇器，各項場景獨立持有狀態。
- [x] 新增 234 組逐項版面場景、25 類觸控／標籤檢查、26 組浮層開關檢查。
- [x] 修正 Toggle／Chip 透明區域點擊、Chip／Combobox 實際移除／清除目標。
- [x] 修正 Checkbox／Radio 群組及 NumberField 步進按鈕的觸控尺寸。
- [x] 修正 Tabs／ToggleGroup／OTP／Pagination 窄版與大字體溢出。
- [x] 鍵盤焦點／目前 OTP 欄位自動捲入可見區，加入專項回歸。
- [x] 修正長 Badge、Progress／Meter 數值、Popover 長內容與 picker 語意標籤。
- [x] 新增可重跑的實際字體明暗圖與浮層展開圖輸出器。
- [x] 新增三種可切換全部元件的 Widget Preview（預覽共九種）。
- [ ] 最新 iOS 真機／模擬器觸控、VoiceOver／Switch Control 及原生能力驗收。
- [ ] 完整色彩／狀態對比、所有 locale、Calendar 密集日期格的 44px 方案。

### 最終驗證紀錄

- [x] 完整 1,324 項測試通過：1,246 項非 Golden ＋ 78 項 Golden，單 worker。
- [x] Example 290 項通過，包含 287 項逐項矩陣／目錄檢查、兩個視覺輸出測試、入口測試。
- [x] 78 張實際字體明暗圖及 26 張浮層展開圖，逐項檢視並保留重跑指令。
- [x] 靜態分析無問題；git diff --check 通過。
- [x] macOS hot restart 成功，runtime errors 為零。
- [ ] 更新後的 macOS 目錄人工操作：電腦鎖定，等待使用者解鎖。
- [x] 九種 Widget Preview 已載入；完整目錄搜尋、分頁切換、2× 字體與 RTL 實際操作通過。
- [x] 預覽切換加入獨立 key，避免 SDK 篩選時沿用其他尺寸的範例狀態；hot reload 通過。
- [x] 預覽保持開啟，桌面版畫面見 [qa-preview.png](doc/app_ui/qa-preview.png)。

不把上游 roadmap 的 shipped 標記當作每項跨平台 QA 已完成的證據。

## Clear AppUI 命名與安裝（2026-10-29）

- [x] 依使用者指定，GitHub fork 改名為 `ycy-0510/clear-appui`。
- [x] README 改為 Clear AppUI 自有介紹，提供 GitHub dependency、Preview 與示範操作。
- [x] Repo 連結、套件介紹與範例顯示名稱同步更新；Dart 識別仍為 `fossui`。
- [x] 套件安裝採 GitHub，設定 `publish_to: none`。
- [x] 將目前開發成果以保留歷史的方式推送至新 repo 的 `main`。
- [x] 獨立專案依 README 從 GitHub 安裝，實際解析 `4b1abd1`；直接擷取公開 API 範例執行 analyze，無問題。
- [x] 改名後的範例入口測試通過；macOS hot reload 成功，runtime errors 為零；兩份 Info.plist 與 README 本地連結檢查通過。
- [ ] GitHub Actions workflow 更新：本機 `codex/fork-setup` 保留修改；目前 GitHub CLI 憑證缺少 `workflow` scope，遠端先保留原流程。
- [x] 通用 Agent Skill：先讀真實 API、重用現成元件，再套用 HIG 與共用 theme。
- [x] Skill 的 API contract、套件內 matching skill 與 doctor 來源解析；本機實測與官方格式驗證通過。
- [x] 透過 NPX 實際安裝到 BIOCAB；doctor 確認 Git ref `785b344`、API contract 1 與 matching Skill 相容。
- [x] AppText 明確隔離 semantics container；標題／操作語意測試與 AppUI 非 Golden 21 項通過。

## Toast 連續通知修正（2026-10-29）

- [x] 重現桌面後卡寬度 992px、前卡 360px 的錯誤，新增 320／1024px、兩／三則通知測試。
- [x] 最大寬度套用至整個通知堆疊，後卡隨前卡尺寸縮放。
- [x] 後卡維持上游留白堆疊；僅前卡顯示訊息與接收操作。
- [x] 修正後排計時：訊息尚未到前排時暫停，避免未讀即消失。
- [x] Toast 31 項專項（含兩張 CI 明暗 Golden）通過；靜態分析無問題，hot reload 成功，runtime errors 為零。

## 公開文件整理（2026-10-29）

- [x] README 改為精簡英文版，面向套件使用者，保留安裝、快速使用、Preview 與文件入口。
- [x] 新增 docs 首頁、Getting Started、Components 與 Agent Skill 使用指南。
- [x] 維護規則寫入 docs：API／行為改動同步更新範例、Skill contract、changelog 與 QA。
- [x] 11 份文件的本地連結檢查通過；Skill 官方驗證腳本通過。


## 共用設計樣式更新（2026-10-29）

- [x] 在 package 新增 AppTopBar：返回獨立浮動、右側操作共用一個不透明 capsule。
- [x] 產品 type scale、16pt card padding 與設計規則集中於 AppTheme／DESIGN_STYLE。
- [x] 更新 portable Skill 與 doctor 的設計文件來源。
- [x] AppUI 26 項通過，涵蓋分組、RTL、觸控／鍵盤／取消與窄版；兩張產品 Golden 已更新並重跑通過。
- [x] 發布 Git 修訂 `324b24b`、透過 NPX 重新安裝 BIOCAB Skill；doctor 確認完全匹配。
- [x] Skill／設計文件補上品牌遷移規則：原版配色、標誌、launcher／啟動畫面；以既有 retheme API 集中映射，保留共用字級與互動。


## 互動連續性與原版遷移修正（2026-10-29）

- [x] 上游 FossTabs 已有連續指示器；保留並要求搜尋分段重用。
- [x] AppNavigationBar 改為同一個 indicator 移動／縮放；快速反向不跳回起點。
- [x] AppTopBar 群組與底部容器尺寸動畫；Reduce Motion 直接使用最終幾何。
- [x] AppButton 恢復 Foss 層次、快速點按／鍵盤回饋、立即防重與延遲 loading 顯示。
- [x] AppNavigationBody 保留分頁狀態並交叉淡化；離開頁面不可點按／聚焦／朗讀。
- [x] AppScaffold 底部 viewport 延伸到裝置邊緣，尾端 scroll padding 避開導航與系統 inset。
- [x] AppListGroup／AppSliverListGroup：只有群組外緣圓角，中間平直、分隔線、lazy rows。
- [x] Skill／文件要求保留原版 navigation、設定入口、搜尋模式與捲動範圍，HIG 不當成 iOS 皮膚。
- [x] AppUI 39 項測試通過，含鍵盤導航淡出／回復、動畫中間影格／反向、RTL、Reduce Motion、鍵盤／取消、底部避讓、群組與 lazy scrolling；兩張 CI 視覺圖已更新及檢視。
- [x] BIOCAB 升級至 e222748，NPX 重新安裝 repo 層 Skill；doctor 確認 contract 1 與 matching bytes，預覽確認原版三分頁／字根搜尋／設定返回。
- [ ] 新版實機動畫、VoiceOver 與效能驗收；不以 Widget tests／Preview 取代。


## 上方透明／毛玻璃捲動背景（2026-10-29）

- [x] 本次實作：AppScaffold 將 topBar 改成 overlay；viewport 延伸到上緣，MediaQuery 提供實際量測的 top clearance。
- [x] 頂端透明，垂直捲動後連續浮現局部毛玻璃／主題色 tint，回頂還原；保留獨立返回與右側群組。
- [x] 分頁切換恢復各頁 scroll material；忽略巢狀／水平捲動，支援 Reduce Motion 與 High Contrast。
- [x] 新增 7 項測試；AppUI 共 46 項（含既有兩張 Golden）通過，未變更 Golden 圖。
- [x] 更新套件範例、設計指南、API 文件與 portable Skill 的前後 scroll inset 規則。
- [x] 嚴格 analyze 無問題；SDK TickerMode API 更新後 7 項專項再次通過。
- [x] BIOCAB 升級與 Skill doctor 匹配；39 項 App 測試及嚴格分析通過，Preview 實際確認透明／毛玻璃、回頂還原與最底列避讓。
- [ ] 實機視覺、VoiceOver 與效能驗收。


## 底部按壓與滑動回饋補正（2026-10-29）

- [x] 補回底部 destination 短按／鍵盤縮放 pulse；callback 立即執行，取消後回復。
- [x] 移除按壓時另一片 selection 色填滿，保留單一背景滑動；使用與 FossTabs 相同的 easeInOut。
- [x] 更新共用 Skill 與設計指南，避免消費端自行實作。
- [x] AppUI 48 項測試（含兩張 Golden）與嚴格 analyze 通過；短按縮放／指示器中間影格、鍵盤與 Reduce Motion 專項通過。
- [x] 發佈 e222748，BIOCAB 使用 matching package／Skill；39 項測試與嚴格 analyze 通過，Preview 實際點按三分頁與來回切換保留 scroll。


Preview hot restart 2,782ms 成功；SDK 在 restart 時出現 disposed EngineFlutterView assertion，瀏覽器 refresh 後恢復，後續新 session 操作無錯誤。未宣稱 SDK 問題已修復；新版實機驗收仍待完成。


## 白底與 Sheet 首拖／進退場修正（2026-10-30）

- [x] 上游 FossUI 原本白底、中性文字／secondary fills；本次 AppTheme 移除整頁灰底與 accent 染色，品牌只覆寫重點操作色。
- [x] Host 統一 Sheet 進退場及 barrier 動畫，結果等待退場完成；支援中途反向、Reduce Motion、背景／route dispose 立即取消。
- [x] 首拖根因：滿高不透明狀態轉毛玻璃時，條件式新增 BackdropFilter 會銷毀手勢 subtree。改為固定 filter、切換 enabled。
- [x] 同一次把手／內容下拉可改變高度並關閉；取消仍可繼續操作。
- [x] AppUI 53 項測試通過，包含 5 項新增 Sheet 連續性測試與更新後的明暗 Golden；已檢視兩張圖片。
- [ ] 嚴格 analyze、消費端／Skill 升級及互動 Preview 驗證。
- [ ] 新版實機手勢／VoiceOver／效能驗收。
