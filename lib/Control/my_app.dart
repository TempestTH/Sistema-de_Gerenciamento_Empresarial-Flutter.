import 'package:flutter/material.dart';
import 'package:projeto_elifone/Control/app_controller.dart';
import 'package:projeto_elifone/pages/HomePage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:projeto_elifone/pages/menuRodape.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController.instance,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: 'rodape',
          routes: {
            'HomePage': (context) => MyHomePage(title: 'Elifone: HomePage',),
            'rodape': (context) => MenuRodape()
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
