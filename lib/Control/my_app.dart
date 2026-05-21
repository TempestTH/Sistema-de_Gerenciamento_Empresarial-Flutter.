import 'package:flutter/material.dart';
import 'package:projeto_elifone/Control/app_controller.dart';
import 'package:projeto_elifone/pages/HomePage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:projeto_elifone/pages/menuRodape.dart';
import 'package:projeto_elifone/Control/route_observer.dart';
import 'package:projeto_elifone/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController.instance,
      builder: (context, child) {
        return MaterialApp(
          navigatorObservers: [routeObserver],
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: 'rodape',
          routes: {
            'HomePage': (context) => MyHomePage(),
            'rodape': (context) => MenuRodape(),
          },
          localizationsDelegates: [
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
        );
      },
    );
  }
}
