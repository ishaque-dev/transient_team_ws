import 'package:flutter/material.dart';

/// Semantic colors for task state.
///
/// Status hues are a categorical set validated for color-vision deficiency in
/// the order To Do → In Progress → On Hold → Completed (the order used by the
/// status breakdown bar). Dark mode uses the dark steps of the same hues.
/// Priority uses the severity scale. Every use pairs the color with an icon and
/// a text label, so color never carries meaning on its own.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.todo,
    required this.inProgress,
    required this.onHold,
    required this.completed,
    required this.priorityLow,
    required this.priorityMedium,
    required this.priorityHigh,
    required this.priorityUrgent,
    required this.critical,
    required this.meterTrack,
    required this.meterFill,
  });

  static const light = AppPalette(
    todo: Color(0xFF2A78D6),
    inProgress: Color(0xFFEB6834),
    onHold: Color(0xFF6250D6),
    completed: Color(0xFF1BAF7A),
    priorityLow: Color(0xFF898781),
    priorityMedium: Color(0xFFFAB219),
    priorityHigh: Color(0xFFEC835A),
    priorityUrgent: Color(0xFFD03B3B),
    critical: Color(0xFFD03B3B),
    meterTrack: Color(0xFFCDE2FB),
    meterFill: Color(0xFF2A78D6),
  );

  static const dark = AppPalette(
    todo: Color(0xFF3987E5),
    inProgress: Color(0xFFD95926),
    onHold: Color(0xFF9085E9),
    completed: Color(0xFF199E70),
    priorityLow: Color(0xFF898781),
    priorityMedium: Color(0xFFFAB219),
    priorityHigh: Color(0xFFEC835A),
    priorityUrgent: Color(0xFFD03B3B),
    critical: Color(0xFFE66767),
    meterTrack: Color(0xFF184F95),
    meterFill: Color(0xFF6DA7EC),
  );

  final Color todo;
  final Color inProgress;
  final Color onHold;
  final Color completed;
  final Color priorityLow;
  final Color priorityMedium;
  final Color priorityHigh;
  final Color priorityUrgent;
  final Color critical;
  final Color meterTrack;
  final Color meterFill;

  @override
  AppPalette copyWith({
    Color? todo,
    Color? inProgress,
    Color? onHold,
    Color? completed,
    Color? priorityLow,
    Color? priorityMedium,
    Color? priorityHigh,
    Color? priorityUrgent,
    Color? critical,
    Color? meterTrack,
    Color? meterFill,
  }) {
    return AppPalette(
      todo: todo ?? this.todo,
      inProgress: inProgress ?? this.inProgress,
      onHold: onHold ?? this.onHold,
      completed: completed ?? this.completed,
      priorityLow: priorityLow ?? this.priorityLow,
      priorityMedium: priorityMedium ?? this.priorityMedium,
      priorityHigh: priorityHigh ?? this.priorityHigh,
      priorityUrgent: priorityUrgent ?? this.priorityUrgent,
      critical: critical ?? this.critical,
      meterTrack: meterTrack ?? this.meterTrack,
      meterFill: meterFill ?? this.meterFill,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      todo: mix(todo, other.todo),
      inProgress: mix(inProgress, other.inProgress),
      onHold: mix(onHold, other.onHold),
      completed: mix(completed, other.completed),
      priorityLow: mix(priorityLow, other.priorityLow),
      priorityMedium: mix(priorityMedium, other.priorityMedium),
      priorityHigh: mix(priorityHigh, other.priorityHigh),
      priorityUrgent: mix(priorityUrgent, other.priorityUrgent),
      critical: mix(critical, other.critical),
      meterTrack: mix(meterTrack, other.meterTrack),
      meterFill: mix(meterFill, other.meterFill),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
