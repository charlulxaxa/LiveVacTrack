import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    this.color = AppColors.success,
    this.size = 8,
    this.pulse = false,
  });

  final Color color;
  final double size;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: pulse
            ? <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }
}
