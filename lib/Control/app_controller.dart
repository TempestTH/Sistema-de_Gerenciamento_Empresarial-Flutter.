import 'package:flutter/cupertino.dart';

class AppController extends ChangeNotifier {
  static AppController instance = AppController();

  bool Notificacao = false;
  bool Lembrete = false;
  bool atvdExt = false;
  bool JanelasFlutuantes = false;
  bool TelaBloqueio = false;
  bool teste = false;
  void changeNotificacao() {
    Notificacao = !Notificacao;
    notifyListeners();
  }

  void changeLembrete() {
    Lembrete = !Lembrete;
    notifyListeners();
  }

  void changeatvdExt() {
    atvdExt = !atvdExt;
    notifyListeners();
  }

  void changeJanelasFlutuantes() {
    JanelasFlutuantes = !JanelasFlutuantes;
    notifyListeners();
  }

  void changeTelaBloqueio() {
    TelaBloqueio = !TelaBloqueio;
    notifyListeners();
  }

  void changeTheme() {
    teste = !teste;
    notifyListeners();
  }
}
