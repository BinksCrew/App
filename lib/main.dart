import 'dart:async';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'screens/welcome_screen.dart';
import 'services/api_service.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    _handleError(details.exception, details.stack);
  };

  runZonedGuarded(() {
    runApp(const MainApp());
  }, (error, stackTrace) {
    _handleError(error, stackTrace);
  });
}

void _handleError(Object error, StackTrace? stackTrace) {
  final apiService = ApiService();
  final errorMessage = '''
**Error en Binkscrew**

*Tipo:* ${error.runtimeType}
*Mensaje:* $error
*Stack Trace:*
```
$stackTrace
```

*Fecha:* ${DateTime.now()}
''';

  // Send to Telegram
  apiService.sendTelegramMessage(errorMessage);

  // Show toast
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text('Ocurrió un error inesperado. Se ha reportado automáticamente.'),
      backgroundColor: Colors.red,
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Binkscrew',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      themeMode: ThemeMode.light,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: UpgradeAlert(
        child: const WelcomeScreen(),
      ),
    );
  }
}
