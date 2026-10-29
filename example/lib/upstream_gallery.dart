import 'package:flutter/widgets.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui_example/component_catalog.dart';

/// Complete component catalog with independent samples and QA display controls.
class ExampleApp extends StatefulWidget {
  /// Opens a component family with an optional initial appearance.
  const ExampleApp({this.initialComponent = 'button', this.dark, super.key});

  /// Initial identifier from [componentCatalog].
  final String initialComponent;

  /// Initial appearance, or the system preference.
  final bool? dark;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late String _selected;
  bool? _dark;
  bool _largeText = false;
  bool _rtl = false;
  bool _stress = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initialComponent;
    _dark = widget.dark;
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        _dark ?? MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final data = dark ? AppThemeData.dark : AppThemeData.light;
    final t = data.tokens;
    return AppTheme(
      data: data,
      child: WidgetsApp(
        debugShowCheckedModeBanner: false,
        title: 'AppUI Component Library',
        color: t.colors.background,
        textStyle: t.typography.base.copyWith(color: t.colors.foreground),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: IconTheme(
          data: IconThemeData(color: t.colors.foreground, size: 20),
          child: ColoredBox(
            color: t.colors.background,
            child: SafeArea(
              child: FossToaster(
                child: LayoutBuilder(
                  builder: (context, limits) {
                    final wide = limits.maxWidth >= 900;
                    final entry = componentCatalog.firstWhere(
                      (c) => c.id == _selected,
                    );
                    return Column(
                      children: [
                        Padding(
                          padding: t.spacing.all(5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 16,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 12,
                                spacing: 20,
                                children: [
                                  const FossText.heading('完整元件庫 · 39'),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      FossButton(
                                        variant: FossButtonVariant.ghost,
                                        onPressed: () =>
                                            setState(() => _dark = !dark),
                                        child: Text(dark ? '淺色' : '深色'),
                                      ),
                                      _option(
                                        '2× 字體',
                                        _largeText,
                                        () => setState(
                                          () => _largeText = !_largeText,
                                        ),
                                      ),
                                      _option(
                                        'RTL',
                                        _rtl,
                                        () => setState(() => _rtl = !_rtl),
                                      ),
                                      _option(
                                        '長內容',
                                        _stress,
                                        () =>
                                            setState(() => _stress = !_stress),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (!wide)
                                FossCombobox<String>(
                                  label: '選擇元件',
                                  hintText: '搜尋元件名稱',
                                  value: _selected,
                                  items: [
                                    for (final c in componentCatalog)
                                      FossComboboxItem(
                                        value: c.id,
                                        label: c.name,
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selected = value);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (wide)
                                SizedBox(width: 248, child: _sidebar(context)),
                              Expanded(
                                child: MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    textScaler: TextScaler.linear(
                                      _largeText ? 2 : 1,
                                    ),
                                  ),
                                  child: Directionality(
                                    textDirection: _rtl
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 880,
                                        ),
                                        child: ListView(
                                          key: ValueKey(
                                            'catalog-page-$_selected',
                                          ),
                                          padding: t.spacing.all(5),
                                          children: [
                                            FossText.caption(entry.category),
                                            const SizedBox(height: 8),
                                            FossText.heading(entry.name),
                                            const SizedBox(height: 8),
                                            Text(
                                              entry.description,
                                              style: t.typography.sm.copyWith(
                                                color: t.colors.mutedForeground,
                                              ),
                                            ),
                                            const SizedBox(height: 28),
                                            ComponentSample(
                                              key: ValueKey(_selected),
                                              id: _selected,
                                              stress: _stress,
                                            ),
                                            const SizedBox(height: 32),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _option(String label, bool selected, VoidCallback activate) =>
      FossToggle(
        pressed: selected,
        onPressedChanged: (_) => activate(),
        child: Text(label),
      );

  Widget _sidebar(BuildContext context) {
    final t = context.fossTheme;
    final entries = componentCatalog
        .where(
          (c) => '${c.name} ${c.category}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: t.spacing(5),
        end: t.spacing(3),
      ),
      child: Column(
        spacing: 16,
        children: [
          FossTextField(
            hintText: '搜尋元件名稱',
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FossListTile(
                    title: Text(entry.name),
                    semanticLabel:
                        '${entry.name}${entry.id == _selected ? '，目前選取' : ''}',
                    style: FossListTileStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        entry.id == _selected
                            ? t.colors.accent
                            : const Color(0x00000000),
                      ),
                    ),
                    onTap: () => setState(() => _selected = entry.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
