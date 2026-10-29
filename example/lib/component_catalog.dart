import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:fossui/fossui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One independently inspectable component family, including its related APIs.
class ComponentEntry {
  /// Creates a catalog record used by the gallery and its QA matrix.
  const ComponentEntry(this.id, this.name, this.category, this.description);

  /// Stable source/test identifier.
  final String id;

  /// Public family name.
  final String name;

  /// Navigation group.
  final String category;

  /// What to inspect in this sample.
  final String description;
}

/// Complete public component families; compound/group APIs share their family.
const componentCatalog = [
  ComponentEntry('button', 'Button', '操作與輸入', '外觀、尺寸、停用、載入與圖示按鈕。'),
  ComponentEntry('text_field', 'TextField', '操作與輸入', '標籤、說明、錯誤、停用與多行輸入。'),
  ComponentEntry('checkbox', 'Checkbox', '操作與輸入', '選取、混合狀態、停用及群組。'),
  ComponentEntry('radio', 'Radio', '操作與輸入', '單選群組、長標籤及停用選項。'),
  ComponentEntry('switch', 'Switch', '操作與輸入', '開關狀態、拖曳與停用。'),
  ComponentEntry('toggle', 'Toggle', '操作與輸入', '文字與圖示切換、選取及停用。'),
  ComponentEntry('toggle_group', 'ToggleGroup', '操作與輸入', '單選、多選、鍵盤方向及焦點。'),
  ComponentEntry('slider', 'Slider', '操作與輸入', '連續值、離散值與停用。'),
  ComponentEntry('select', 'Select', '操作與輸入', '單選清單、長選項、停用及焦點返回。'),
  ComponentEntry('multi_select', 'MultiSelect', '操作與輸入', '多選、選取摘要及清除。'),
  ComponentEntry('combobox', 'Combobox', '操作與輸入', '搜尋、篩選、停用項目及空結果。'),
  ComponentEntry('multi_combobox', 'MultiCombobox', '操作與輸入', '多選標籤、搜尋與移除。'),
  ComponentEntry('autocomplete', 'Autocomplete', '操作與輸入', '輸入建議、鍵盤選取與自由文字。'),
  ComponentEntry('number_field', 'NumberField', '操作與輸入', '步進、數值上下限與停用。'),
  ComponentEntry('otp_field', 'OtpField', '操作與輸入', '六碼輸入、群組、錯誤及大字體。'),
  ComponentEntry('chip', 'Chip', '操作與輸入', '外觀、選取、移除與停用。'),
  ComponentEntry('calendar', 'Calendar', '日期與時間', '單日、多日、日期區間與月份切換。'),
  ComponentEntry('date_picker', 'DatePicker', '日期與時間', '日期、範圍、停用與確認／取消。'),
  ComponentEntry('time_picker', 'TimePicker', '日期與時間', '12／24 小時、分鐘間隔與確認／取消。'),
  ComponentEntry('text', 'Text', '內容與版面', '文字層級、換行與長內容。'),
  ComponentEntry('card', 'Card', '內容與版面', '標題、內容、頁尾與內距。'),
  ComponentEntry('separator', 'Separator', '內容與版面', '水平與垂直分隔。'),
  ComponentEntry('tabs', 'Tabs', '內容與版面', '分段、底線、長標籤與面板切換。'),
  ComponentEntry('accordion', 'Accordion', '內容與版面', '展開、收合、停用與長標題。'),
  ComponentEntry('list_tile', 'ListTile', '內容與版面', '圖示、標題、副標題、尾端操作與停用。'),
  ComponentEntry('pagination', 'Pagination', '內容與版面', '頁碼、上一頁／下一頁與窄寬度。'),
  ComponentEntry('spinner', 'Spinner', '狀態與回饋', '載入尺寸與無障礙標籤。'),
  ComponentEntry('progress', 'Progress', '狀態與回饋', '進度、標籤與長數值。'),
  ComponentEntry('skeleton', 'Skeleton', '狀態與回饋', '圓形、文字與載入版面。'),
  ComponentEntry('meter', 'Meter', '狀態與回饋', '有界數值、標籤與範圍。'),
  ComponentEntry('badge', 'Badge', '狀態與回饋', '各語意狀態與長標籤。'),
  ComponentEntry('avatar', 'Avatar', '狀態與回饋', '尺寸與圖片失敗時的文字替代。'),
  ComponentEntry('alert', 'Alert', '狀態與回饋', '各語意狀態、說明與多個操作。'),
  ComponentEntry('popover', 'Popover', '浮層與提示', '定位、關閉、Escape 與焦點返回。'),
  ComponentEntry('dialog', 'Dialog', '浮層與提示', '捲動內容、操作、取消與焦點。'),
  ComponentEntry('alert_dialog', 'AlertDialog', '浮層與提示', '確認、取消與不可意外關閉。'),
  ComponentEntry('drawer', 'Drawer', '浮層與提示', '側邊／底部面板、捲動與關閉。'),
  ComponentEntry('tooltip', 'Tooltip', '浮層與提示', '滑鼠、長按與焦點提示。'),
  ComponentEntry('toast', 'Toast', '浮層與提示', '語意狀態、通知佇列與移除。'),
];

/// Stateful, isolated samples shared by the app, Widget Preview and QA tests.
class ComponentSample extends StatefulWidget {
  /// Creates one sample; stress enables deliberately long content.
  const ComponentSample({required this.id, this.stress = false, super.key});

  /// Catalog entry identifier.
  final String id;

  /// Exercises content that must wrap or truncate intentionally.
  final bool stress;

  @override
  State<ComponentSample> createState() => _ComponentSampleState();
}

class _ComponentSampleState extends State<ComponentSample> {
  bool _checked = false;
  bool _on = true;
  bool _selected = false;
  bool _removed = false;
  double _volume = 40;
  num? _quantity = 2;
  int _page = 4;
  String? _choice;
  Set<String> _choices = {'design'};
  DateTime? _date;
  Set<DateTime> _dates = {};
  FossDateRange? _range;
  FossTimeOfDay? _time;
  final _popover = FossPopoverController();

  String get _label => widget.stress
      ? 'A deliberately long label that must remain usable at large text sizes'
      : 'Design systems';
  String get _description => widget.stress
      ? 'Long supporting content describes the current state and should wrap '
            'naturally without covering actions or escaping its container.'
      : 'Reusable components for everyday product work.';

  List<FossSelectItem<String>> get _selectItems => [
    FossSelectItem(value: 'design', label: _label),
    const FossSelectItem(value: 'engineering', label: 'Engineering'),
    const FossSelectItem(
      value: 'disabled',
      label: 'Unavailable',
      enabled: false,
    ),
  ];
  List<FossComboboxItem<String>> get _comboItems => [
    FossComboboxItem(value: 'design', label: _label),
    const FossComboboxItem(value: 'engineering', label: 'Engineering'),
    const FossComboboxItem(
      value: 'disabled',
      label: 'Unavailable',
      enabled: false,
    ),
  ];

  Widget _column(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: children,
  );
  Widget _wrap(List<Widget> children) => Wrap(
    spacing: 12,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );

  Future<void> _dialog({bool alert = false}) async {
    if (alert) {
      await showFossAlertDialog<void>(
        context: context,
        builder: (context) => FossAlertDialog(
          title: Text(_label),
          description: Text(_description),
          actions: [
            FossButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FossButton(
              variant: FossButtonVariant.destructive,
              onPressed: () => Navigator.pop(context),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      await showFossDialog<void>(
        context: context,
        builder: (context) => FossDialog(
          title: Text(_label),
          description: Text(_description),
          content: const FossTextField(label: 'Name', hintText: 'Enter a name'),
          actions: [
            FossButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _drawer(FossDrawerSide side) async {
    await showFossDrawer<void>(
      context: context,
      side: side,
      builder: (context) => FossDrawer(
        showHandle: side == FossDrawerSide.bottom,
        title: Text(_label),
        description: Text(_description),
        content: Text(_description),
        actions: [
          FossButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.id) {
      'button' => _column([
        _wrap([
          for (final variant in FossButtonVariant.values)
            FossButton(
              variant: variant,
              onPressed: () {},
              child: Text(variant.name),
            ),
        ]),
        _wrap([
          for (final size in FossButtonSize.values)
            FossButton(size: size, onPressed: () {}, child: Text(size.name)),
          const FossButton(child: Text('Disabled')),
          const FossButton(loading: true, child: Text('Loading')),
          FossButton.icon(
            onPressed: () {},
            semanticLabel: 'Add',
            icon: const Icon(LucideIcons.plus),
          ),
        ]),
        FossButton(onPressed: () {}, child: Text(_label)),
      ]),
      'text_field' => _column([
        FossTextField(
          label: _label,
          hintText: 'Enter text',
          helperText: _description,
        ),
        const FossTextField(
          label: 'Error',
          errorText: 'Please enter a valid value.',
        ),
        const FossTextField(
          label: 'Disabled',
          enabled: false,
          hintText: 'Unavailable',
        ),
        const FossTextField(
          label: 'Notes',
          maxLines: 3,
          hintText: 'Write a note',
        ),
      ]),
      'checkbox' => _column([
        FossCheckbox(
          value: _checked,
          label: _label,
          description: _description,
          onChanged: (v) => setState(() => _checked = v),
        ),
        const FossCheckbox(
          value: null,
          label: 'Mixed, disabled',
        ),
        FossCheckboxGroup<String>(
          values: _choices,
          onChanged: (v) => setState(() => _choices = v),
          children: const [
            FossCheckboxItem(value: 'design', label: 'Design'),
            FossCheckboxItem(value: 'engineering', label: 'Engineering'),
          ],
        ),
      ]),
      'radio' => FossRadioGroup<String>(
        groupValue: _choice,
        onChanged: (v) => setState(() => _choice = v),
        children: [
          FossRadio(value: 'design', label: _label, description: _description),
          const FossRadio(value: 'engineering', label: 'Engineering'),
          const FossRadio(
            value: 'disabled',
            label: 'Unavailable',
            enabled: false,
          ),
        ],
      ),
      'switch' => _column([
        Row(
          children: [
            FossSwitch(
              value: _on,
              semanticLabel: 'Notifications',
              onChanged: (v) => setState(() => _on = v),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_label)),
          ],
        ),
        const FossSwitch(value: false, semanticLabel: 'Unavailable'),
      ]),
      'toggle' => _wrap([
        FossToggle(
          pressed: _selected,
          onPressedChanged: (v) => setState(() => _selected = v),
          child: Text(_label),
        ),
        FossToggle(
          pressed: _selected,
          onPressedChanged: (v) => setState(() => _selected = v),
          semanticLabel: 'Bold',
          leading: const Icon(LucideIcons.bold),
        ),
        const FossToggle(pressed: false, child: Text('Disabled')),
      ]),
      'toggle_group' => _column([
        FossToggleGroup.single(
          value: _choice,
          onChanged: (v) => setState(() => _choice = v),
          children: const [
            FossToggleGroupItem(value: 'design', child: Text('One')),
            FossToggleGroupItem(value: 'engineering', child: Text('Two')),
            FossToggleGroupItem(
              value: 'disabled',
              child: Text('Three'),
              enabled: false,
            ),
          ],
        ),
        FossToggleGroup.multiple(
          value: _choices,
          onChanged: (v) => setState(() => _choices = v),
          children: const [
            FossToggleGroupItem(
              value: 'design',
              leading: Icon(LucideIcons.bold),
              semanticLabel: 'Bold',
            ),
            FossToggleGroupItem(
              value: 'engineering',
              leading: Icon(LucideIcons.italic),
              semanticLabel: 'Italic',
            ),
          ],
        ),
      ]),
      'slider' => _column([
        FossSlider(
          value: _volume,
          semanticLabel: 'Volume',
          onChanged: (v) => setState(() => _volume = v),
        ),
        FossSlider(
          value: _volume,
          divisions: 10,
          semanticLabel: 'Steps',
          onChanged: (v) => setState(() => _volume = v),
        ),
        const FossSlider(
          value: 50,
          onChanged: null,
          semanticLabel: 'Unavailable',
        ),
      ]),
      'select' => _column([
        FossSelect<String>(
          label: _label,
          placeholder: 'Choose a discipline',
          value: _choice,
          items: _selectItems,
          onChanged: (v) => setState(() => _choice = v),
        ),
        FossSelect<String>(
          label: 'Disabled',
          placeholder: 'Unavailable',
          items: _selectItems,
          enabled: false,
        ),
      ]),
      'multi_select' => FossMultiSelect<String>(
        label: _label,
        values: _choices,
        items: _selectItems,
        onChanged: (v) => setState(() => _choices = v),
      ),
      'combobox' => FossCombobox<String>(
        label: _label,
        hintText: 'Search disciplines',
        value: _choice,
        items: _comboItems,
        onChanged: (v) => setState(() => _choice = v),
      ),
      'multi_combobox' => FossMultiCombobox<String>(
        label: _label,
        hintText: 'Add disciplines',
        values: _choices,
        items: _comboItems,
        onChanged: (v) => setState(() => _choices = v),
      ),
      'autocomplete' => FossAutocomplete(
        label: _label,
        hintText: 'Start typing',
        items: const ['Design', 'Engineering', 'Operations'],
      ),
      'number_field' => _column([
        FossNumberField(
          value: _quantity,
          min: 0,
          max: 10,
          onChanged: (v) => setState(() => _quantity = v),
        ),
        const FossNumberField(value: 3, enabled: false),
      ]),
      'otp_field' => const FossOtpField(
        length: 6,
        groups: [3, 3],
        semanticsLabel: 'Verification code',
      ),
      'chip' => _column([
        _wrap([
          for (final variant in FossChipVariant.values)
            FossChip(label: Text(variant.name), variant: variant),
        ]),
        if (!_removed)
          FossChip(
            label: Text(_label),
            selected: _selected,
            onSelected: (v) => setState(() => _selected = v),
            onRemove: () => setState(() => _removed = true),
          ),
        FossChip(label: Text(_label), enabled: false),
      ]),
      'calendar' => _column([
        FossCalendar.single(
          initialMonth: DateTime(2026, 10),
          selected: _date,
          onSelected: (v) => setState(() => _date = v),
        ),
        FossCalendar.multiple(
          initialMonth: DateTime(2026, 10),
          selected: _dates,
          onSelected: (v) => setState(() => _dates = v),
        ),
        FossCalendar.range(
          initialMonth: DateTime(2026, 10),
          selected: _range,
          onSelected: (v) => setState(() => _range = v),
        ),
      ]),
      'date_picker' => _column([
        FossDatePicker.single(
          selected: _date,
          onSelected: (v) => setState(() => _date = v),
        ),
        FossDatePicker.range(
          selected: _range,
          onSelected: (v) => setState(() => _range = v),
        ),
        FossDatePicker.single(
          selected: null,
          onSelected: (_) {},
          enabled: false,
        ),
      ]),
      'time_picker' => _column([
        FossTimePicker(
          value: _time,
          minuteStep: 15,
          use24HourFormat: true,
          onChanged: (v) => setState(() => _time = v),
        ),
        FossTimePicker(
          value: _time,
          use24HourFormat: false,
          onChanged: (v) => setState(() => _time = v),
        ),
        FossTimePicker(value: null, enabled: false, onChanged: (_) {}),
      ]),
      'text' => _column([
        FossText.display(_label),
        FossText.heading(_label),
        FossText.title(_label),
        FossText.body(_description),
        const FossText.caption('Supporting caption'),
      ]),
      'card' => FossCard(
        title: Text(_label),
        description: Text(_description),
        content: Text(_description),
        footer: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FossButton(onPressed: () {}, child: const Text('Continue')),
        ),
      ),
      'separator' => _column([
        const Text('Section one'),
        const FossSeparator(),
        const Text('Section two'),
        const SizedBox(
          height: 44,
          child: Row(
            children: [
              Text('One'),
              SizedBox(width: 12),
              FossSeparator(orientation: FossSeparatorOrientation.vertical),
              SizedBox(width: 12),
              Text('Two'),
            ],
          ),
        ),
      ]),
      'tabs' => _column([
        for (final variant in FossTabsVariant.values)
          FossTabs<String>(
            variant: variant,
            tabs: [
              FossTab(
                value: 'overview',
                label: widget.stress ? 'Overview and details' : 'Overview',
                content: Text(_description),
              ),
              const FossTab(
                value: 'activity',
                label: 'Activity',
                content: Text('Recent activity'),
              ),
              const FossTab(
                value: 'disabled',
                label: 'Unavailable',
                enabled: false,
              ),
            ],
          ),
      ]),
      'accordion' => FossAccordion(
        initialValue: const {'one'},
        children: [
          FossAccordionItem(
            value: 'one',
            title: Text(_label),
            child: Text(_description),
          ),
          const FossAccordionItem(
            value: 'two',
            title: Text('Details'),
            child: Text('Additional information'),
          ),
          const FossAccordionItem(
            value: 'disabled',
            title: Text('Unavailable'),
            enabled: false,
            child: Text('Not available'),
          ),
        ],
      ),
      'list_tile' => _column([
        FossListTile(
          title: Text(_label),
          subtitle: Text(_description),
          leading: const Icon(LucideIcons.bookOpen),
          trailing: FossButton.icon(
            onPressed: () {},
            semanticLabel: 'More options',
            icon: const Icon(LucideIcons.ellipsis),
          ),
          onTap: () {},
        ),
        const FossListTile(title: Text('Disabled'), enabled: false),
      ]),
      'pagination' => FossPagination(
        page: _page,
        pageCount: 12,
        onPageChanged: (v) => setState(() => _page = v),
      ),
      'spinner' => _wrap([
        for (final size in [16.0, 24.0, 40.0]) FossSpinner(size: size),
      ]),
      'progress' => _column([
        FossProgress(
          value: .65,
          label: _label,
          valueLabel: widget.stress ? '65 of 100 items completed' : '65%',
        ),
        const FossProgress(value: 0),
        const FossProgress(value: 1),
      ]),
      'skeleton' => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FossSkeleton.circle(size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: _column([
              const FossSkeleton(height: 16),
              const FossSkeleton(height: 12),
            ]),
          ),
        ],
      ),
      'meter' => FossMeter(
        value: 65,
        label: _label,
        formatValue: widget.stress
            ? (_, _, _) => '65 of 100 items completed'
            : null,
      ),
      'badge' => _wrap([
        for (final variant in FossBadgeVariant.values)
          FossBadge(
            label: Text(widget.stress ? _label : variant.name),
            variant: variant,
          ),
      ]),
      'avatar' => _wrap([
        for (final size in FossAvatarSize.values)
          FossAvatar(size: size, fallback: const Text('AB')),
      ]),
      'alert' => _column([
        for (final variant in FossAlertVariant.values)
          FossAlert(
            variant: variant,
            title: Text(_label),
            description: Text(_description),
            actions: [
              FossButton(onPressed: () {}, child: const Text('Review')),
              FossButton(
                variant: FossButtonVariant.ghost,
                onPressed: () {},
                child: const Text('Dismiss'),
              ),
            ],
          ),
      ]),
      'popover' => FossPopover(
        controller: _popover,
        builder: (_) => _column([
          Text(_label),
          Text(_description),
          FossButton(onPressed: _popover.close, child: const Text('Done')),
        ]),
        child: FossButton(
          onPressed: _popover.toggle,
          child: const Text('Open popover'),
        ),
      ),
      'dialog' => FossButton(
        onPressed: () => unawaited(_dialog()),
        child: const Text('Open dialog'),
      ),
      'alert_dialog' => FossButton(
        onPressed: () => unawaited(_dialog(alert: true)),
        child: const Text('Open alert dialog'),
      ),
      'drawer' => _wrap([
        for (final side in [FossDrawerSide.bottom, FossDrawerSide.right])
          FossButton(
            onPressed: () => unawaited(_drawer(side)),
            child: Text('Open ${side.name} drawer'),
          ),
      ]),
      'tooltip' => FossTooltip(
        message: _description,
        child: FossButton.icon(
          onPressed: () {},
          semanticLabel: 'More information',
          icon: const Icon(LucideIcons.info),
        ),
      ),
      'toast' => _wrap([
        for (final variant in FossToastVariant.values)
          FossButton(
            onPressed: () => showFossToast(
              context,
              FossToast(
                variant: variant,
                title: Text(_label),
                description: Text(_description),
              ),
            ),
            child: Text('Show ${variant.name} toast'),
          ),
      ]),
      _ => throw ArgumentError.value(widget.id, 'id', 'Unknown catalog entry'),
    };
  }
}
