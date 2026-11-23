import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/qr_payload.dart';
import '../../data/models/permit.dart';
import '../../data/models/verification.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../atoms/app_text_field.dart';
import '../molecules/error_banner.dart';
import '../molecules/last_synced_label.dart';
import '../molecules/offline_banner.dart';
import '../molecules/verification_result_panel.dart';
import '../templates/scan_template.dart';

class PermitVerifierView extends StatefulWidget {
  const PermitVerifierView({
    required this.onVerify,
    required this.offline,
    super.key,
    this.lastSynced,
    this.demoPermits = const <Permit>[],
  });

  final Future<VerificationOutcome> Function({
    required String permitId,
    required String signedCode,
    required String checkpointName,
  }) onVerify;
  final bool offline;
  final DateTime? lastSynced;
  final List<Permit> demoPermits;

  @override
  State<PermitVerifierView> createState() => _PermitVerifierViewState();
}

class _PermitVerifierViewState extends State<PermitVerifierView> {
  final TextEditingController _permitId = TextEditingController();
  final TextEditingController _signedCode = TextEditingController();
  final TextEditingController _checkpoint =
      TextEditingController(text: 'San Jose Checkpoint');

  VerificationOutcome? _result;
  String? _error;
  bool _verifying = false;
  bool _handlingScan = false;

  @override
  void dispose() {
    _permitId.dispose();
    _signedCode.dispose();
    _checkpoint.dispose();
    super.dispose();
  }

  Future<void> _verify(String permitId, String signedCode) async {
    if (_verifying) return;
    if (permitId.trim().isEmpty || signedCode.trim().isEmpty) {
      setState(() => _error = 'Enter both the permit ID and the signed code.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
      _result = null;
    });
    try {
      final VerificationOutcome outcome = await widget.onVerify(
        permitId: permitId.trim(),
        signedCode: signedCode.trim(),
        checkpointName: _checkpoint.text,
      );
      if (mounted) setState(() => _result = outcome);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Verification failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _verifying = false;
          _handlingScan = false;
        });
      }
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_verifying || _handlingScan) return;
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
      setState(() {
        _handlingScan = false;
        _error = 'That QR code is not a LiveVacTrack permit.';
      });
      return;
    }

    _handlingScan = true;
    _permitId.text = payload.permitId;
    _signedCode.text = payload.signedCode;
    await _verify(payload.permitId, payload.signedCode);
  }

  void _useDemoPermit(Permit permit) {
    _permitId.text = permit.id;
    _signedCode.text = permit.signedCode;
    _verify(permit.id, permit.signedCode);
  }

  @override
  Widget build(BuildContext context) {
    return ScanTemplate(
      scanner: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: AppText(
                  'Scan permit QR',
                  variant: AppTextVariant.title,
                ),
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
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: SizedBox(
              height: 240,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  MobileScanner(
                    onDetect: _onDetect,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (BuildContext context, MobileScannerException error) {
                      return _CameraFallback(
                        message: 'Camera unavailable. Use manual entry below.',
                      );
                    },
                    placeholderBuilder: (BuildContext context) {
                      return const _CameraFallback(
                        message: 'Starting camera…',
                        icon: Icons.photo_camera_rounded,
                      );
                    },
                  ),
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 2,
                        ),
                      ),
                      margin: const EdgeInsets.all(AppSpacing.xl),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            'Point the camera at the QR on the permit. The signed code is checked against the permit record.',
            variant: AppTextVariant.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          LastSyncedLabel(
            lastSynced: widget.lastSynced,
            offline: widget.offline,
          ),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.offline) ...<Widget>[
            OfflineBanner(lastSynced: widget.lastSynced),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            controller: _checkpoint,
            label: 'Checkpoint name',
            hint: 'e.g. San Jose Checkpoint',
            prefixIcon: Icons.location_on_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const AppText(
                    'Manual verification',
                    variant: AppTextVariant.title,
                  ),
                  const SizedBox(height: 2),
                  const AppText(
                    'Use this when the camera cannot read the code.',
                    variant: AppTextVariant.caption,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    hint: 'Paste the code printed with the QR',
                    prefixIcon: Icons.password_rounded,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Verify permit',
                    onPressed: _verifying
                        ? null
                        : () => _verify(_permitId.text, _signedCode.text),
                    loading: _verifying,
                    icon: Icons.verified_user_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (widget.demoPermits.isNotEmpty && !widget.offline) ...<Widget>[
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
                  .map((Permit permit) => ActionChip(
                        label: AppText(
                          permit.id,
                          variant: AppTextVariant.caption,
                          fontWeight: FontWeight.w600,
                        ),
                        onPressed: _verifying
                            ? null
                            : () => _useDemoPermit(permit),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
      result: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_error != null) ErrorBanner(message: _error!),
          if (_error != null) const SizedBox(height: AppSpacing.lg),
          if (_result != null)
            VerificationResultPanel(outcome: _result!)
          else if (_error == null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.inkMuted),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppText(
                      'Scan a permit or enter the code manually to see the result.',
                      variant: AppTextVariant.caption,
                    ),
                  ),
                ],
              ),
            ),
          if (_result != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Scan another permit',
              onPressed: () => setState(() {
                _result = null;
                _error = null;
                _permitId.clear();
                _signedCode.clear();
              }),
              variant: AppButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback({
    required this.message,
    this.icon = Icons.no_photography_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white70, size: 34),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
