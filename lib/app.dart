import 'package:material_ui/material_ui.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'ui/pages/auth_gate.dart';

class LiveVacTrackApp extends StatelessWidget {
  const LiveVacTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
