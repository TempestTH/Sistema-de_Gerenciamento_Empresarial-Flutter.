import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_elifone/model/material_model.dart';
import 'package:projeto_elifone/pages/HomePage.dart';

void main() {
  testWidgets('dashboard renders dynamic inventory data', (tester) async {
    final now = DateTime.now();

    await tester.pumpWidget(
      MaterialApp(
        home: MyHomePage(
          loadMateriais: () async => [
            MaterialModel(
              nome: 'Cabo UTP',
              quantidade: 8,
              valor: 12,
              metro: true,
            ),
            MaterialModel(
              nome: 'Conector RJ45',
              quantidade: 35,
              valor: 1.5,
              metro: false,
            ),
          ],
          loadEstoque: () async => [
            {
              'created_at': now.toIso8601String(),
              'Quantidade': 10,
              'Entrada': true,
              'Saida': false,
              'Material': {'nome': 'Cabo UTP'},
            },
            {
              'created_at': now.toIso8601String(),
              'Quantidade': 2,
              'Entrada': false,
              'Saida': true,
              'Material': {'nome': 'Conector RJ45'},
            },
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Visao Geral do Sistema'), findsOneWidget);
    expect(find.text('43'), findsOneWidget);
    expect(find.text('Cabo UTP'), findsWidgets);
    expect(find.text('Conector RJ45'), findsWidgets);
    expect(find.text('Entrada'), findsWidgets);
    expect(find.text('Saida'), findsWidgets);
  });
}
