import 'package:flutter/material.dart';

const _starColor = Color(0xFFF5A524);

/// Read-only 0-5 star display with half-star precision.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.size = 16});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.outlineVariant;
    return Semantics(
      label: '${value.toStringAsFixed(1)} out of 5 stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              value >= i
                  ? Icons.star_rounded
                  : value >= i - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: value >= i - 0.5 ? _starColor : muted,
            ),
        ],
      ),
    );
  }
}

/// Tappable 1-5 star picker.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 34,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i star${i == 1 ? '' : 's'}',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i <= value ? _starColor : muted,
            ),
          ),
      ],
    );
  }
}
