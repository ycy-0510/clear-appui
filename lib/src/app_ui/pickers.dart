import 'package:flutter/widgets.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui/src/app_ui/components.dart';
import 'package:fossui/src/app_ui/foundation.dart';
import 'package:fossui/src/app_ui/presentation.dart';

/// Controlled date selection with compact-sheet and wide-popover presentation.
class AppDatePicker extends StatelessWidget {
  /// Creates an adaptive date picker.
  const AppDatePicker({
    required this.selected,
    required this.onChanged,
    this.minDate,
    this.maxDate,
    this.isDateEnabled,
    this.firstDayOfWeek = DateTime.monday,
    super.key,
  });

  /// Selected date, or null before selection.
  final DateTime? selected;

  /// Called when an enabled day is chosen.
  final ValueChanged<DateTime> onChanged;

  /// Earliest enabled date.
  final DateTime? minDate;

  /// Latest enabled date.
  final DateTime? maxDate;

  /// Additional business-specific date availability.
  final bool Function(DateTime)? isDateEnabled;

  /// First weekday in the calendar.
  final int firstDayOfWeek;
  @override
  Widget build(BuildContext context) => AppPopover(
    title: const AppText('選擇日期', role: AppTextRole.title),
    builder: (context) => FossCalendar.single(
      selected: selected,
      initialMonth: selected,
      minDate: minDate,
      maxDate: maxDate,
      isDateEnabled: isDateEnabled,
      firstDayOfWeek: firstDayOfWeek,
      onSelected: (date) {
        onChanged(date);
        AppPopover.close(context);
      },
    ),
    child: Container(
      constraints: BoxConstraints(
        minHeight: context.appTheme.dimensions.touchTarget,
      ),
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: context.appTheme.tokens.colors.secondary,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(
            context.appTheme.tokens.radii.md,
          ),
        ),
      ),
      child: Text(
        selected == null
            ? '選擇日期'
            : '${selected!.year}/${selected!.month.toString().padLeft(2, '0')}/${selected!.day.toString().padLeft(2, '0')}',
        style: context.appTheme.tokens.typography.sm.copyWith(
          color: context.appTheme.tokens.colors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
