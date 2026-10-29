@Tags(['golden'])
library;

// goldenTest manages the registered test future.
// ignore_for_file: discarded_futures

import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

void main() {
  for (final (name, theme) in [
    ('light', AppThemeData.light),
    ('dark', AppThemeData.dark),
  ]) {
    goldenTest(
      'AppUI states ($name)',
      fileName: 'app_ui_$name',
      builder: () => GoldenTestGroup(
        columns: 1,
        children: [
          GoldenTestScenario(
            name: 'product actions, statuses and validation',
            child: AppTheme(
              data: theme,
              child: ColoredBox(
                color: theme.tokens.colors.background,
                child: SizedBox(
                  width: 440,
                  child: Padding(
                    padding: theme.tokens.spacing.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTopBar(
                          leading: AppTopBarAction(
                            icon: const Text('‹'),
                            label: 'Back',
                            onPressed: () {},
                          ),
                          actions: [
                            AppTopBarAction(
                              icon: const Text('✎'),
                              label: 'Edit',
                              onPressed: () {},
                            ),
                            AppTopBarAction(
                              icon: const Text('⋯'),
                              label: 'More',
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const AppText(
                          'Course Library',
                          role: AppTextRole.heading,
                        ),
                        Wrap(
                          spacing: theme.tokens.spacing(2),
                          children: [
                            for (final variant in AppButtonVariant.values)
                              AppButton(
                                variant: variant,
                                onPressed: () {},
                                child: Text(variant.name),
                              ),
                            const AppButton(child: Text('Disabled')),
                          ],
                        ),
                        Wrap(
                          spacing: theme.tokens.spacing(2),
                          children: [
                            for (final status in AppStatus.values)
                              AppBadge(label: status.name, status: status),
                          ],
                        ),
                        const AppTextField(
                          label: 'Course',
                          errorText: 'Required',
                        ),
                        const AppCard(child: AppText('Composable content')),
                        AppListGroup(
                          children: [
                            AppCheckbox(
                              value: true,
                              label: 'Selected vocabulary',
                              onChanged: (_) {},
                            ),
                            AppCheckbox(
                              value: false,
                              label: 'Another vocabulary entry',
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
