import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/errors/app_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../data/enums/scan_result.dart';
import '../data/models/verification.dart';
import '../ui/atoms/app_button.dart';
import '../ui/atoms/app_spinner.dart';
import '../ui/atoms/app_text.dart';
import '../ui/molecules/error_banner.dart';
import '../ui/molecules/verification_result_panel.dart';
import '../ui/status_styles.dart';

typedef PermitVerifier = Future<VerificationOutcome> Function({
  required String permitId,
  required String signedCode,
  required String checkpointName,
});

/// Second step of the checkpoint flow: verifies the scanned (or typed) permit
/// as soon as it opens and shows the result full screen.
class PermitVerifyPage extends StatefulWidget {
  const PermitVerifyPage({
    required this.permitId,
    required this.signedCode,
    required this.checkpointName,
    required this.onVerify,
    super.key,
  });

  final String permitId;
  final String signedCode;
  final String checkpointName;
  final PermitVerifier onVerify;

  @override
  State<PermitVerifyPage> createState() => _PermitVerifyPageState();
}

class _PermitVerifyPageState extends State<PermitVerifyPage> {
  VerificationOutcome? _outcome;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _run();
  }

  Future<void> _run() async {
    try {
      final VerificationOutcome outcome = await widget.onVerify(
        permitId: widget.permitId,
        signedCode: widget.signedCode,
        checkpointName: widget.checkpointName,
      );
      if (!mounted) return;
      setState(() => _outcome = outcome);
      if (outcome.result == ScanResult.valid) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Verification failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final VerificationOutcome? outcome = _outcome;

    final Widget body;
    if (_loading) {
      body = _Checking(permitId: widget.permitId);
    } else if (outcome != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ResultBanner(outcome: outcome),
          const SizedBox(height: AppSpacing.lg),
          VerificationResultPanel(outcome: outcome, showHeader: false),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ErrorBanner(message: _error ?? 'Verification failed.'),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Try again',
            onPressed: _retry,
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.secondary,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verify permit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.lg,
          AppSpacing.pagePadding,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          body,
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppText(
                  widget.checkpointName,
                  variant: AppTextVariant.caption,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            label: 'Scan another permit',
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            icon: Icons.qr_code_scanner_rounded,
          ),
        ),
      ),
    );
  }
}

class _Checking extends StatelessWidget {
  const _Checking({required this.permitId});

  final String permitId;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
        child: Column(
          children: <Widget>[
            const AppSpinner(size: 40),
            const SizedBox(height: AppSpacing.lg),
            AppText(
              'Checking permit $permitId…',
              variant: AppTextVariant.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Comparing the signed code with the permit record.',
              variant: AppTextVariant.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width, colour-coded verdict the inspector can read at a glance.
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.outcome});

  final VerificationOutcome outcome;

  String get _guidance {
    switch (outcome.result) {
      case ScanResult.valid:
        return 'Allow passage';
      case ScanResult.expired:
        return 'Do not allow passage. The permit has expired.';
      case ScanResult.revoked:
        return 'Do not allow passage. The permit was revoked.';
      case ScanResult.invalid:
        return 'Do not allow passage. This is not a genuine permit.';
      case ScanResult.unverified:
        return 'Hold. The permit could not be checked with the server.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = scanColor(outcome.result);
    return Semantics(
      liveRegion: true,
      container: true,
      label: '${outcome.result.label}. $_guidance',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            children: <Widget>[
              Icon(scanIcon(outcome.result), color: Colors.white, size: 56),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                outcome.result.label,
                variant: AppTextVariant.display,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                _guidance,
                variant: AppTextVariant.body,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
