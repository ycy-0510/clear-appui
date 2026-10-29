# 完整元件庫 QA — 2026-10-29

本次檢查涵蓋 `lib/src/components/` 的 35 個元件資料夾、39 個元件族群，
不是只檢查課程示範頁。單選／多選及 Dialog／AlertDialog 分開列；
CheckboxGroup／RadioGroup 與其控制項一起檢查。
同資料夾的 style、controller、painter 和私有 helper 納入完整回歸測試。
產品 API `lib/src/app_ui/` 另有 `test/app_ui/`，不混入 39 項計數。

## 可重現的檢查

- **L：版面** — 每項 6 組，共 234 組。320px 明／暗；320px 2× 長文字；
  320px 暗色 2× RTL 長文字；1024px 長文字；1024px 暗色 2× RTL 長文字。
  檢查真正的 Flutter layout exceptions，未關閉 overflow 錯誤。
- **V：視覺** — 每項明／暗各一張，共 78 張，載入 Geist 與 Lucide 實際字體，
  人工檢視文字層級、間距、對齊、圓角、狀態。浮層另查展開畫面。
  這組是檢視證據；正式 golden 仍使用原測試與誤差限制。
- **T：觸控與標籤** — 下表標示的 25 個互動族群各執行 Flutter
  `iOSTapTargetGuideline`（44×44）與 `labeledTapTargetGuideline`。
  這檢查的是語意樹目標，不等同所有平台的螢幕閱讀器人工驗收。
- **O：浮層** — 13 項，在 320／1024px、2×、長內容下實際開啟，確認
  展開內容存在，再關閉／卸載並檢查 exceptions，共 26 組。
- **R：回歸** — 完整套件 unit／widget／golden，包含各元件的狀態、
  controller、style precedence、語意、鍵盤與取消測試。

`L/V` 適用全部 39 項。`—` 表示該項未執行 T 或 O，不能解讀成通過。
原始品質準則見 [component checklist](../components/checklist.md)，
Apple 官方依據與圓角／材質限制見 [HIG notes](APPLE_HIG_NOTES.md)。

## 逐項紀錄

下列來源連結定位主要實作；同資料夾的 supporting files 與測試一併回歸。
「保留」代表本輪場景未發現需修改的問題，不代表省略檢查。

| # | 元件／主要來源 | T | O | 檢查重點與本輪結果 |
|---|---|---|---|---|
| 1 | [Button](../../lib/src/components/button/foss_button.dart) | ✓ | — | 全 variants／sizes、disabled／loading；透明留白點擊修正已有邊緣回歸。 |
| 2 | [TextField](../../lib/src/components/text_field/foss_text_field.dart) | — | — | label／helper／error／disabled／多行，明暗與長文字版面保留。 |
| 3 | [Checkbox + Group](../../lib/src/components/checkbox/foss_checkbox.dart) | ✓ | — | 單一、混合、群組；群組短選項改為真實 48px 最小目標。 |
| 4 | [Radio + Group](../../lib/src/components/radio/foss_radio.dart) | ✓ | — | 單選／disabled／描述；plain row 改為 48px 最小目標。 |
| 5 | [Switch](../../lib/src/components/switch/foss_switch.dart) | ✓ | — | on／off／disabled、標籤與大字體保留。 |
| 6 | [Toggle](../../lib/src/components/toggle/foss_toggle.dart) | ✓ | — | 選取／圖示／disabled；透明 padding 納入點擊。 |
| 7 | [ToggleGroup](../../lib/src/components/toggle_group/foss_toggle_group.dart) | ✓ | — | 單選／多選；橫列不足時捲動，避免 2× 字體溢出。 |
| 8 | [Slider](../../lib/src/components/slider/foss_slider.dart) | — | — | 連續／分段／disabled、RTL 場景保留；手勢／鍵盤由原測試回歸。 |
| 9 | [Select](../../lib/src/components/select/foss_select.dart) | ✓ | ✓ | 選單、disabled、長選項與 2× 開關檢查。 |
| 10 | [MultiSelect](../../lib/src/components/select/foss_multi_select.dart) | ✓ | ✓ | 多選摘要、選項與長內容檢查。 |
| 11 | [Combobox](../../lib/src/components/combobox/foss_combobox.dart) | ✓ | ✓ | 可搜尋選單；清除／展開鈕改用真實 48×48 目標，移除 OverflowBox 假放大。 |
| 12 | [MultiCombobox](../../lib/src/components/combobox/foss_combobox.dart) | ✓ | ✓ | 多選 chip、移除與開關檢查；共用本輪修正的 Chip。 |
| 13 | [Autocomplete](../../lib/src/components/combobox/foss_combobox.dart) | ✓ | ✓ | 實際輸入篩選文字並確認建議列存在。 |
| 14 | [NumberField](../../lib/src/components/number_field/foss_number_field.dart) | ✓ | — | 上下界／disabled；步進按鈕由 40×34 改為至少 48×48。 |
| 15 | [OtpField](../../lib/src/components/otp_field/foss_otp_field.dart) | — | — | 六碼／分組；窄版橫向捲動，輸入時自動顯示 active slot。 |
| 16 | [Chip](../../lib/src/components/chip/foss_chip.dart) | ✓ | — | 靜態／可選／可移除；移除鈕改為真正 48×48，四邊可點。 |
| 17 | [Calendar](../../lib/src/components/calendar/foss_calendar.dart) | — | — | 單日／多日／範圍與明暗、RTL；密集日期格限制見下方。 |
| 18 | [DatePicker](../../lib/src/components/date_picker/foss_date_picker.dart) | ✓ | ✓ | 日期／範圍／disabled；預設操作標籤改採 placeholder。 |
| 19 | [TimePicker](../../lib/src/components/time_picker/foss_time_picker.dart) | ✓ | ✓ | 12／24 小時、間隔、disabled、實際滾輪；補預設操作標籤。 |
| 20 | [Text](../../lib/src/components/text/foss_text.dart) | — | — | display／heading／title／body／caption，長內容換行保留。 |
| 21 | [Card](../../lib/src/components/card/foss_card.dart) | — | — | title／description／content／footer 的間距、圓角與長文字保留。 |
| 22 | [Separator](../../lib/src/components/separator/foss_separator.dart) | — | — | 水平與垂直方向、明暗分隔線保留。 |
| 23 | [Tabs](../../lib/src/components/tabs/foss_tabs.dart) | ✓ | — | 兩種外觀；水平可捲、垂直受限、44px 目標，鍵盤焦點自動顯示。 |
| 24 | [Accordion](../../lib/src/components/accordion/foss_accordion.dart) | ✓ | — | 已展開／收合／disabled、長標題描述、觸控範圍與標籤檢查。 |
| 25 | [ListTile](../../lib/src/components/list_tile/foss_list_tile.dart) | ✓ | — | leading／trailing／subtitle／disabled、內嵌按鈕保留。 |
| 26 | [Pagination](../../lib/src/components/pagination/foss_pagination.dart) | ✓ | — | 頁碼視窗不足時保留上一頁／目前／下一頁，極窄時可捲動。 |
| 27 | [Spinner](../../lib/src/components/spinner/foss_spinner.dart) | — | — | 16／24／40 尺寸、明暗與 reduce-motion 回歸。 |
| 28 | [Progress](../../lib/src/components/progress/foss_progress.dart) | — | — | 0／65%／100%；label／valueLabel 空間不足時換行，數值維持尾端對齊。 |
| 29 | [Skeleton](../../lib/src/components/skeleton/foss_skeleton.dart) | — | — | 圓／矩形、明暗與 reduce-motion 回歸。 |
| 30 | [Meter](../../lib/src/components/meter/foss_meter.dart) | — | — | 長 formatValue／label 空間不足時換行，保留 intrinsic layout 支援。 |
| 31 | [Badge](../../lib/src/components/badge/foss_badge.dart) | — | — | 全 variants；過長標籤可省略，保留完整語意文字。 |
| 32 | [Avatar](../../lib/src/components/avatar/foss_avatar.dart) | — | — | 全 sizes／fallback、明暗版面保留；圖片載入由原測試回歸。 |
| 33 | [Alert](../../lib/src/components/alert/foss_alert.dart) | — | — | 全 variants、描述及雙 action、窄版長內容保留。 |
| 34 | [Popover](../../lib/src/components/popover/foss_popover.dart) | ✓ | ✓ | 長內容預設捲動；trigger 合併標籤但不合併浮層語意；可設 scrollable:false。 |
| 35 | [Dialog](../../lib/src/components/dialog/foss_dialog.dart) | ✓ | ✓ | 表單、標題描述、Done、Escape／焦點回歸。 |
| 36 | [AlertDialog](../../lib/src/components/dialog/foss_alert_dialog.dart) | ✓ | ✓ | 取消／確認、長描述；實際 Cancel 關閉。 |
| 37 | [Drawer](../../lib/src/components/drawer/foss_drawer.dart) | ✓ | ✓ | bottom／right 展示；本輪壓力測試展開 bottom，其他方向由原測試回歸。 |
| 38 | [Tooltip](../../lib/src/components/tooltip/foss_tooltip.dart) | ✓ | ✓ | 有標籤的 icon trigger、長按顯示說明；hover／Escape 由原測試回歸。 |
| 39 | [Toast](../../lib/src/components/toast/foss_toast.dart) | ✓ | ✓ | 全 variants 入口；另補兩／三則的窄／寬尺寸回歸，修正後卡過寬及排到前方前即逾時。後卡留白是既有堆疊設計。 |

## 證據與重跑

- 元件場景：[`component_catalog.dart`](../../example/lib/component_catalog.dart)。
- 全部 `lib/` 檔案另經靜態分析；theme／foundation／icons 的 unit tests 與
  `test/app_ui/` 納入完整回歸，generated token files 不手動改寫。
- 逐項矩陣：[`component_qa_test.dart`](../../example/test/component_qa_test.dart)。
- 視覺輸出：[`component_visual_qa_test.dart`](../../example/test/component_visual_qa_test.dart)。
- 本機圖片：`/private/tmp/appui-component-qa/<id>_light.png`／`<id>_dark.png`；
  浮層為 `<id>_open_light.png`／`<id>_open_dark.png`。
  `board_*` 與 `open_*_<page>.png` 是 contact boards，不放大原圖。
- 測試與預覽指令見 [DEVELOPMENT.md](DEVELOPMENT.md)。每次先檢查 CPU，單 worker，
  不與 analyzer／原生編譯／Preview 編譯同時執行。

最終回歸：完整套件 1,324 項（包含 78 項 Golden），Example 290 項全部通過；
靜態分析無問題。九種 Widget Preview 已載入，目錄搜尋、分頁切換、2×／RTL
已實際操作。畫面見 [qa-preview.png](qa-preview.png)。Native hot restart 成功，
runtime errors 為零；macOS 桌面人工操作因電腦鎖定待解鎖。
完整紀錄見 [TODO.md](../../TODO.md)。

## 尚未宣稱完成的項目

- 最新 iOS 的真實觸控、VoiceOver／Switch Control、原生鍵盤與觸覺驗收。
  本輪不啟動模擬器；Widget tests／macOS／Web Preview 不取代 iOS 驗收。
- 每個色彩／狀態的量化對比、完整 locale、全部 API 任意組合、每個 hover／focus
  的新增視覺基準。上表 V 是指定場景，不是任意輸入的視覺保證。
- Calendar 使用密集日期格，未納入本輪 44×44 guideline pass；目前約 40px。
  OTP 作為一個文字欄位驗證，未把每個顯示 slot 宣稱為獨立觸控控制項。
- HIG 沒有規定所有元件共用同一個圓角數字。這個 fork 使用產品主題與連續圓角；
  視覺檢查不能當成 Apple 認證，也不代表 Flutter 材質等同系統 Liquid Glass。

後續修改任何元件，都應先切到它的獨立 Gallery 場景，再跑其專項測試與這份矩陣；
不能只看課程頁就把整個元件庫勾選完成。
