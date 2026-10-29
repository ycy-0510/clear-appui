import 'package:flutter/cupertino.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/app_ui_showcase.dart';
import 'package:fossui_example/upstream_gallery.dart' as upstream;

/// Starts the same course flow used by Widget Preview and widget tests.
void main() => runApp(const AppUIExampleApp());

/// A minimal app shell for AppUI; no platform plugin initialization required.
class AppUIExampleApp extends StatelessWidget {
  /// Creates the example app.
  const AppUIExampleApp({super.key});
  @override
  Widget build(BuildContext context) => WidgetsApp(
    debugShowCheckedModeBanner: false,
    title: 'Clear AppUI Lab',
    color: const Color(0xFFFFFFFF),
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
    home: const _DemoLauncher(),
  );
}

class _DemoLauncher extends StatefulWidget {
  const _DemoLauncher();
  @override
  State<_DemoLauncher> createState() => _DemoLauncherState();
}

class _DemoLauncherState extends State<_DemoLauncher> {
  bool _gallery = true;
  @override
  Widget build(BuildContext context) => AppTheme(
    child: Builder(
      builder: (context) {
        final t = context.appTheme.tokens;
        return ColoredBox(
          color: t.colors.background,
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: AppConstrainedContent(
                  maxWidth: 1040,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      spacing: 16,
                      children: [
                        Expanded(
                          child: Text(
                            'Clear AppUI',
                            style: t.typography.sm.copyWith(
                              color: t.colors.mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        CupertinoSlidingSegmentedControl<bool>(
                          groupValue: _gallery,
                          backgroundColor: t.colors.secondary,
                          thumbColor: t.colors.card,
                          onValueChanged: (value) {
                            if (value != null) setState(() => _gallery = value);
                          },
                          children: {
                            for (final (value, label) in [
                              (true, '完整元件庫'),
                              (false, '課程互動'),
                            ])
                              value: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                child: Text(
                                  label,
                                  style: t.typography.xs.copyWith(
                                    color: t.colors.foreground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _gallery
                    ? const upstream.ExampleApp()
                    : const AppCourseDemo(),
              ),
            ],
          ),
        );
      },
    ),
  );
}
