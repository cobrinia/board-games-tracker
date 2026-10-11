import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

//import 'package:flutter/rendering.dart'; //файли для дебагу

// Project structure:
//   core/      - theme, reusable widgets, mock data, validators, formatters
//   features/  - one folder per app section (auth, home, catalog, sessions,
//                players, settings)

void main() {
  //debugPaintSizeEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameShelf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
