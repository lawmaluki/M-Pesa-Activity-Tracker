import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/share_card.dart';

/// The shareable "year in review" card, presented as a floating modal over
/// whatever screen triggered it — not a full page push — so the app
/// underneath stays visible (dimmed) behind it. Tap the backdrop or the
/// close button to dismiss.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Share',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, _) => const ShareScreen(),
      transitionBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _controller = ScreenshotController();
  bool _busy = false;

  Future<Uint8List?> _renderImage() => _controller.capture(pixelRatio: 3.0);

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final bytes = await _renderImage();
      if (bytes == null) throw Exception('Could not render card');
      await Gal.putImageBytes(bytes, name: 'mpesa_tracker_share');
      if (!mounted) return;
      _showSnack('Saved to your gallery.');
    } on GalException catch (e) {
      if (!mounted) return;
      _showSnack(e.type.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not save the image.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _renderImage();
      if (bytes == null) throw Exception('Could not render card');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: const ['mpesa_tracker_share.png'],
          text: 'My M-Pesa activity, tracked with M-Pesa Tracker.',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not share the image.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<TransactionProvider>();

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CloseButton(
                  colors: colors,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                Screenshot(
                  controller: _controller,
                  child: ShareCard(
                    year: provider.selectedYear,
                    daysTracked: provider.daysTrackedInSelectedYear,
                    dailyCounts: provider.dailyCounts,
                    transactionCount: provider.yearTransactionCount,
                    longestStreak: provider.longestStreakDays,
                    received: provider.yearReceived,
                    sent: provider.yearSpent,
                  ),
                ),
                const SizedBox(height: 22),
                Align(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PillButton(
                        icon: Icons.download_outlined,
                        label: 'Save',
                        background: colors.surface,
                        foreground: colors.textPrimary,
                        border: colors.border,
                        onPressed: _busy ? null : _save,
                      ),
                      const SizedBox(width: 12),
                      _PillButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        background: colors.brandGreen,
                        foreground: Colors.white,
                        onPressed: _busy ? null : _share,
                      ),
                    ],
                  ),
                ),
                if (_busy) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onTap;

  const _CloseButton({required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      shape: CircleBorder(side: BorderSide(color: colors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.close_outlined, color: colors.textPrimary, size: 18),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback? onPressed;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: StadiumBorder(
        side: border != null ? BorderSide(color: border!) : BorderSide.none,
      ),
      child: InkWell(
        customBorder: StadiumBorder(
          side: border != null ? BorderSide(color: border!) : BorderSide.none,
        ),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
