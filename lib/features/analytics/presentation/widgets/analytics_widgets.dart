import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transient_team_ws/core/theme/app_palette.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/features/analytics/domain/performance_summary.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_visuals.dart';

/// KPI tile: label, value, optional caption. The value stays in regular ink;
/// the tinted icon carries the accent.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(Icons.chevron_right_rounded, size: 18, color: muted),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: muted),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive grid of [StatTile]s: 2 columns on phones, 4 on wide screens.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Thin segmented bar showing how tasks split across statuses, followed by
/// a legend that doubles as the data table (name + count + share).
class StatusBreakdown extends StatelessWidget {
  const StatusBreakdown({super.key, required this.summary});

  final PerformanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;
    final total = summary.total;
    final parts = [
      for (final status in TaskStatus.values)
        if (summary.count(status) > 0) (status, summary.count(status)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: parts.map((p) => '${p.$1.label} ${p.$2}').join(', '),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: total == 0
                  ? Container(color: theme.colorScheme.surfaceContainerHighest)
                  : Row(
                      children: [
                        for (var i = 0; i < parts.length; i++) ...[
                          if (i > 0) Container(width: 2, color: surface),
                          Expanded(
                            flex: parts[i].$2,
                            child: Container(color: parts[i].$1.color(context)),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            for (final status in TaskStatus.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(status.icon, size: 16, color: status.color(context)),
                  const SizedBox(width: 6),
                  Text(status.label, style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 6),
                  Text(
                    '${summary.count(status)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (total > 0)
                    Text(
                      '  ${Formatters.percent(summary.count(status) / total)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Completed tasks per week. Single series, so no legend: the card title names
/// it. Tap (or hover) a bar for its exact value.
class WeeklyCompletionChart extends StatelessWidget {
  const WeeklyCompletionChart({
    super.key,
    required this.weeks,
    this.height = 150,
  });

  final List<WeeklyCount> weeks;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = context.palette;
    final maxCount = weeks.fold<int>(0, (m, w) => w.count > m ? w.count : m);
    final label = DateFormat('d MMM');
    final muted = scheme.onSurfaceVariant;

    return Semantics(
      label:
          'Completed tasks per week: ${weeks.map((w) => 'week of ${label.format(w.weekStart)}, ${w.count}').join('; ')}',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final plotHeight = constraints.maxHeight - 20;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < weeks.length; i++)
                        Expanded(
                          child: Tooltip(
                            triggerMode: TooltipTriggerMode.tap,
                            message:
                                'Week of ${label.format(weeks[i].weekStart)}: '
                                '${weeks[i].count} completed',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Direct labels only on the current week and
                                // the peak, to keep the chart quiet.
                                SizedBox(
                                  height: 20,
                                  child:
                                      (i == weeks.length - 1 ||
                                          (weeks[i].count == maxCount &&
                                              maxCount > 0))
                                      ? Text(
                                          '${weeks[i].count}',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        )
                                      : null,
                                ),
                                Container(
                                  width: 22,
                                  height: maxCount == 0
                                      ? 0
                                      : plotHeight * weeks[i].count / maxCount,
                                  decoration: BoxDecoration(
                                    color: i == weeks.length - 1
                                        ? palette.meterFill
                                        : palette.meterFill.withValues(
                                            alpha: 0.45,
                                          ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Container(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < weeks.length; i++)
                  Expanded(
                    child: Text(
                      i == weeks.length - 1
                          ? 'This wk'
                          : label.format(weeks[i].weekStart),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 0-100 performance score as a ring (blue fill on a lighter blue track).
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 84,
    this.onDark = false,
  });

  final int? score;
  final double size;

  /// Use white ink, for placement on the gradient banner.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final value = score;
    return Semantics(
      label: value == null ? 'No score yet' : 'Performance score $value of 100',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: (value ?? 0) / 100,
              strokeWidth: size * 0.1,
              strokeCap: StrokeCap.round,
              color: onDark ? Colors.white : palette.meterFill,
              backgroundColor: onDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : palette.meterTrack,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value?.toString() ?? '–',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: onDark ? Colors.white : null,
                    ),
                  ),
                  Text(
                    'score',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: onDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const scoreExplanation =
    'Score (0–100) blends deadline achievement (40%), admin ratings (40%) '
    'and completion rate (20%).';

String percentOrDash(double? ratio) =>
    ratio == null ? '–' : Formatters.percent(ratio);

String ratingOrDash(double? rating) =>
    rating == null ? '–' : '${rating.toStringAsFixed(1)} ★';
