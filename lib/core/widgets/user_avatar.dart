import 'package:flutter/material.dart';

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'[\s@._-]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pairs = [
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    ];
    final (background, foreground) =
        pairs[name.codeUnits.fold<int>(0, (a, b) => a + b) % pairs.length];

    return Semantics(
      label: name,
      excludeSemantics: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: background,
        child: Text(
          initialsOf(name),
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}
