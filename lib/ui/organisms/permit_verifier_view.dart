import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/checkpoint_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/qr_payload.dart';
import '../../data/models/permit.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../atoms/app_text_field.dart';
import '../molecules/error_banner.dart';
import '../molecules/last_synced_label.dart';
import '../molecules/offline_banner.dart';
import '../molecules/scan_success_dialog.dart';
import '../templates/scan_template.dart';
import 'app_shell.dart';

/// Opens the verify step for a permit and completes when the inspector comes
/// back to the scanner.
typedef OpenPermitVerification = Future<void> Function({
  required String permitId,
  required String signedCode,
  required String checkpointName,
});

/// Checkpoint scan screen. Reading a permit QR shows a "Permit scanned"
/// popup; Continue calls [PermitVerifierView.onOpenVerification], which opens
/// the page that runs the check.
///
/// The camera only runs while it is needed. It is switched off (the
/// [MobileScanner] is removed, which stops and releases the camera) while
/// manual entry is open, while a scan is being handled, and while another
/// tab of the shell is showing.
class PermitVerifierView extends StatefulWidget {
  const PermitVerifierView({
    required this.onOpenVerification,
    required this.offline,
    super.key,
    this.lastSynced,
    this.demoPermits = const <Permit>[],
  });

  final OpenPermitVerification onOpenVerification;
  final bool offline;
  final DateTime? lastSynced;
  final List<Permit> demoPermits;

  @override
  State<PermitVerifierView> createState() => _PermitVerifierViewState();
}

class _PermitVerifierViewState extends State<PermitVerifierView> {
  final TextEditingController _permitId = TextEditingController();
  final TextEditingController _signedCode = TextEditingController();

  String _checkpoint = CheckpointStore.defaultName;
  bool _manualOpen = false;
  String? _manualError;

  /// True from the moment a permit QR is read until the inspector is back on
  /// this screen. Also guards against handling the same QR twice.
  bool _handlingScan = false;

  String? _lastRejected;
  DateTime? _lastRejectedAt;

  @override
  void initState() {
    super.initState();
    CheckpointStore.load().then((String name) {
      if (mounted) setState(() => _checkpoint = name);
    });
  }

  @override
  void dispose() {
    _permitId.dispose();
    _signedCode.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingScan || _manualOpen) return;
    String? raw;
    for (final Barcode barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        raw = barcode.rawValue;
        break;
      }
    }
    if (raw == null) return;

    final PermitQrPayload? payload = PermitQrPayload.tryParse(raw);
    if (payload == null) {
      _rejectForeignQr(raw);
      return;
    }

    // Set before any await so frames that arrive meanwhile are ignored.
    _handlingScan = true;
    setState(() {});
    HapticFeedback.lightImpact();

    final bool proceed = await ScanSuccessDialog.show(
      context,
      permitId: payload.permitId,
      checkpointName: _checkpoint,
    );
    if (proceed && mounted) {
      await _openVerifyPage(payload.permitId, payload.signedCode);
    }
    if (mounted) setState(() => _handlingScan = false);
  }

  /// A QR that is not a permit stays in view for many frames; tell the
  /// inspector once rather than on every frame.
  void _rejectForeignQr(String raw) {
    final DateTime now = DateTime.now();
    final bool repeat =
        raw == _lastRejected &&
        _lastRejectedAt != null &&
        now.difference(_lastRejectedAt!) < const Duration(seconds: 4);
    if (repeat) return;
    _lastRejected = raw;
    _lastRejectedAt = now;
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('That QR code is not a LiveVacTrack permit.'),
        ),
      );
  }

  Future<void> _openVerifyPage(String permitId, String signedCode) {
    return widget.onOpenVerification(
      permitId: permitId,
      signedCode: signedCode,
      checkpointName: _checkpoint,
    );
  }

  void _setManualOpen(bool open) {
    FocusScope.of(context).unfocus();
    setState(() {
      _manualOpen = open;
      _manualError = null;
    });
  }

  Future<void> _submitManual() async {
    final String permitId = _permitId.text.trim();
    final String signedCode = _signedCode.text.trim();
    if (permitId.isEmpty || signedCode.isEmpty) {
      setState(
        () => _manualError = 'Enter both the permit ID and the signed code.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _manualError = null);
    await _openVerifyPage(permitId, signedCode);
    if (!mounted) return;
    _permitId.clear();
    _signedCode.clear();
  }

  Future<void> _useDemoPermit(Permit permit) async {
    _permitId.text = permit.id;
    _signedCode.text = permit.signedCode;
    await _submitManual();
  }

  Future<void> _editCheckpoint() async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _CheckpointDialog(initial: _checkpoint),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    setState(() => _checkpoint = name.trim());
    await CheckpointStore.save(name);
  }

  @override
  Widget build(BuildContext context) {
    final bool tabVisible = ShellTabScope.isActive(context);
    final bool cameraOn = tabVisible && !_manualOpen && !_handlingScan;

    final Widget viewport;
    if (cameraOn) {
      viewport = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            onDetect: _onDetect,
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, MobileScannerException error) {
              return const _CameraFallback(
                message: 'Camera unavailable. Enter the code manually below.',
              );
            },
            placeholderBuilder: (BuildContext context) {
              return const _CameraFallback(
                message: 'Starting camera…',
                icon: Icons.photo_camera_rounded,
              );
            },
          ),
          const IgnorePointer(child: _ScanFrame()),
        ],
      );
    } else if (_handlingScan) {
      viewport = const _CameraFallback(
        message: 'Permit scanned',
        icon: Icons.check_circle_rounded,
      );
    } else if (_manualOpen) {
      viewport = _CameraFallback(
        message: 'Camera off while you enter a code',
        icon: Icons.no_photography_outlined,
        actionLabel: 'Use camera',
        onAction: () => _setManualOpen(false),
      );
    } else {
      viewport = const _CameraFallback(
        message: 'Camera paused',
        icon: Icons.photo_camera_outlined,
      );
    }

    return ScanTemplate(
      scanner: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: AppText('Scan permit QR', variant: AppTextVariant.title),
              ),
              AppBadge(
                label: widget.offline ? 'Offline' : 'Online',
                tone: widget.offline ? BadgeTone.warning : BadgeTone.success,
                icon: widget.offline
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: _CheckpointChip(name: _checkpoint, onTap: _editCheckpoint),
          ),
          if (widget.offline) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            OfflineBanner(lastSynced: widget.lastSynced),
          ],
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: SizedBox(height: 280, child: viewport),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            'Point the camera at the QR code on the permit.',
            variant: AppTextVariant.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ManualEntryCard(
            open: _manualOpen,
            onToggle: () => _setManualOpen(!_manualOpen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _permitId,
                  label: 'Permit ID',
                  hint: 'e.g. PMT-1001',
                  prefixIcon: Icons.description_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _signedCode,
                  label: 'Signed code',
                  hint: 'The code printed under the QR',
                  prefixIcon: Icons.password_rounded,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitManual(),
                ),
                if (_manualError != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  ErrorBanner(message: _manualError!),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Verify permit',
                  onPressed: _submitManual,
                  icon: Icons.verified_user_rounded,
                ),
                if (widget.demoPermits.isNotEmpty &&
                    !widget.offline) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  AppText(
                    'DEMO PERMITS',
                    variant: AppTextVariant.caption,
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.demoPermits
                        .take(6)
                        .map(
                          (Permit permit) => ActionChip(
                            label: AppText(
                              permit.id,
                              variant: AppTextVariant.caption,
                              fontWeight: FontWeight.w600,
                            ),
                            onPressed: () => _useDemoPermit(permit),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LastSyncedLabel(
            lastSynced: widget.lastSynced,
            offline: widget.offline,
          ),
        ],
      ),
    );
  }
}

/// Shows where scans are logged; tap to change it.
class _CheckpointChip extends StatelessWidget {
  const _CheckpointChip({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Checkpoint location: $name. Tap to change.',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: AppText(
                    'At $name',
                    variant: AppTextVariant.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckpointDialog extends StatefulWidget {
  const _CheckpointDialog({required this.initial});

  final String initial;

  @override
  State<_CheckpointDialog> createState() => _CheckpointDialogState();
}

class _CheckpointDialogState extends State<_CheckpointDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_name.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText('Checkpoint location', variant: AppTextVariant.title),
      content: AppTextField(
        controller: _name,
        hint: 'e.g. San Jose Checkpoint',
        prefixIcon: Icons.location_on_outlined,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _save(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Collapsed by default. Opening it switches the camera off.
class _ManualEntryCard extends StatelessWidget {
  const _ManualEntryCard({
    required this.open,
    required this.onToggle,
    required this.child,
  });

  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.keyboard_alt_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppText(
                            'Enter code manually',
                            variant: AppTextVariant.label,
                          ),
                          AppText(
                            open
                                ? 'Camera is off. Close this to scan again.'
                                : 'For when the camera cannot read the QR.',
                            variant: AppTextVariant.caption,
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Corner brackets marking where to hold the QR.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 190,
        height: 190,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const double arm = 28;
    final double w = size.width;
    final double h = size.height;
    final Path path = Path()
      ..moveTo(0, arm)
      ..lineTo(0, 0)
      ..lineTo(arm, 0)
      ..moveTo(w - arm, 0)
      ..lineTo(w, 0)
      ..lineTo(w, arm)
      ..moveTo(w, h - arm)
      ..lineTo(w, h)
      ..lineTo(w - arm, h)
      ..moveTo(arm, h)
      ..lineTo(0, h)
      ..lineTo(0, h - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback({
    required this.message,
    this.icon = Icons.no_photography_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white70, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.photo_camera_rounded, size: 18),
              label: Text(actionLabel!),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                minimumSize: const Size(0, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
