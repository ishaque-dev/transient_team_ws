import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:transient_team_ws/core/theme/app_theme.dart';

const _logoAsset = 'assets/logo.jpeg';

/// The Coopiq wordmark. The source image has a brand-purple background, so
/// place it on [BrandColors.purple] for a seamless look.
class CoopiqLogo extends StatelessWidget {
  const CoopiqLogo({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    // The wordmark spans roughly the middle half of the square image.
    return Semantics(
      label: 'Coopiq',
      image: true,
      child: SizedBox(
        width: width,
        height: width * 0.3,
        child: ClipRect(
          child: OverflowBox(
            maxWidth: width * 2.05,
            maxHeight: width * 2.05,
            child: Image.asset(
              _logoAsset,
              width: width * 2.05,
              height: width * 2.05,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact app mark: rounded purple tile with the wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: BrandColors.purple,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: BrandColors.pink.withValues(alpha: 0.25),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: CoopiqLogo(width: size * 0.86),
    );
  }
}

/// Brand-purple backdrop with soft orange and pink glows.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BrandColors.purple,
      child: Stack(
        children: [
          // Glows stay in the lower half so the logo (whose image has a
          // flat purple background) sits on plain brand purple.
          Positioned(
            bottom: 80,
            right: -140,
            child: _Glow(color: BrandColors.pink, size: 320),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _Glow(color: BrandColors.orange, size: 340),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Header band used on home screens: brand-purple card with a greeting.
class GradientBanner extends StatelessWidget {
  const GradientBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.purple, BrandColors.purpleLight],
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.purple.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -40,
            top: -60,
            child: _Glow(color: BrandColors.pink, size: 180),
          ),
          const Positioned(
            left: -50,
            bottom: -80,
            child: _Glow(color: BrandColors.orange, size: 170),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(gradient: BrandColors.wordmark),
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

/// Multi-color "G" drawn in code, so no image asset is needed.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double rad(double degrees) => degrees * math.pi / 180;

    canvas
      ..drawArc(rect, rad(-40), rad(85), false, arc(_blue))
      ..drawArc(rect, rad(45), rad(90), false, arc(_green))
      ..drawArc(rect, rad(135), rad(85), false, arc(_yellow))
      ..drawArc(rect, rad(220), rad(95), false, arc(_red));

    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2,
        size.height / 2 - stroke / 2,
        size.width / 2,
        stroke,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
