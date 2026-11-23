import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/enums/permit_status.dart';
import '../data/enums/quarantine_status.dart';
import '../data/enums/scan_result.dart';
import '../data/enums/vax_status.dart';
import 'atoms/app_badge.dart';

BadgeTone vaxTone(VaxStatus status) {
  switch (status) {
    case VaxStatus.valid:
      return BadgeTone.success;
    case VaxStatus.expired:
      return BadgeTone.warning;
    case VaxStatus.none:
      return BadgeTone.neutral;
  }
}

BadgeTone permitTone(PermitStatus status) {
  switch (status) {
    case PermitStatus.issued:
      return BadgeTone.success;
    case PermitStatus.revoked:
      return BadgeTone.danger;
    case PermitStatus.expired:
      return BadgeTone.warning;
  }
}

BadgeTone scanTone(ScanResult result) {
  switch (result) {
    case ScanResult.valid:
      return BadgeTone.success;
    case ScanResult.expired:
    case ScanResult.unverified:
      return BadgeTone.warning;
    case ScanResult.revoked:
    case ScanResult.invalid:
      return BadgeTone.danger;
  }
}

BadgeTone quarantineTone(QuarantineStatus status) {
  return status == QuarantineStatus.active
      ? BadgeTone.danger
      : BadgeTone.neutral;
}

Color scanColor(ScanResult result) {
  switch (result) {
    case ScanResult.valid:
      return AppColors.success;
    case ScanResult.expired:
    case ScanResult.unverified:
      return AppColors.warning;
    case ScanResult.revoked:
    case ScanResult.invalid:
      return AppColors.danger;
  }
}

Color scanSoftColor(ScanResult result) {
  switch (result) {
    case ScanResult.valid:
      return AppColors.successSoft;
    case ScanResult.expired:
    case ScanResult.unverified:
      return AppColors.warningSoft;
    case ScanResult.revoked:
    case ScanResult.invalid:
      return AppColors.dangerSoft;
  }
}

IconData scanIcon(ScanResult result) {
  switch (result) {
    case ScanResult.valid:
      return Icons.verified_rounded;
    case ScanResult.expired:
      return Icons.schedule_rounded;
    case ScanResult.revoked:
      return Icons.block_rounded;
    case ScanResult.invalid:
      return Icons.gpp_bad_rounded;
    case ScanResult.unverified:
      return Icons.cloud_off_rounded;
  }
}
