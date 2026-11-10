import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transient_team_ws/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp / Call / Email buttons used by the contact sheet and the
/// "unavailable" screens.
class ContactOptions extends StatelessWidget {
  const ContactOptions({
    super.key,
    required this.phone,
    required this.email,
    this.onLaunched,
  });

  /// With country code, e.g. `+919747344535`.
  final String phone;
  final String email;

  /// Called after a link is opened (e.g. to close a sheet).
  final VoidCallback? onLaunched;

  Future<void> _open(BuildContext context, Uri uri, String fallback) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    onLaunched?.call();
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: fallback));
      messenger?.showSnackBar(
        SnackBar(content: Text("Couldn't open the app. Copied $fallback")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return Row(
      children: [
        Expanded(
          child: _ContactButton(
            icon: Icons.chat_rounded,
            label: 'WhatsApp me',
            gradient: const [Color(0xFF25D366), Color(0xFF128C7E)],
            onTap: () => _open(
              context,
              Uri.parse(
                'https://wa.me/$digits?text=${Uri.encodeComponent('Hi, I need help with Coopiq Internal.')}',
              ),
              phone,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ContactButton(
            icon: Icons.call_rounded,
            label: 'Call me',
            gradient: const [BrandColors.purpleLight, BrandColors.purple],
            onTap: () =>
                _open(context, Uri(scheme: 'tel', path: '+$digits'), phone),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ContactButton(
            icon: Icons.mail_rounded,
            label: 'Email me',
            gradient: const [BrandColors.orange, BrandColors.pink],
            onTap: () => _open(
              context,
              Uri(
                scheme: 'mailto',
                path: email,
                query:
                    'subject=${Uri.encodeComponent('Coopiq Internal support')}',
              ),
              email,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
