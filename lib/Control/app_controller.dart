import 'package:flutter/cupertino.dart';

class AppController extends ChangeNotifier {
  static AppController instance = AppController();

  bool Notificacao = false;
  bool Lembrete = false;
  bool atvdExt = false;
  bool JanelasFlutuantes = false;
  bool TelaBloqueio = false;
  bool teste = false;
  changeNotificacao() {
    Notificacao = !Notificacao;
    notifyListeners();
  }

  changeLembrete() {
    Lembrete = !Lembrete;
    notifyListeners();
  }

  changeatvdExt() {
    atvdExt = !atvdExt;
    notifyListeners();
  }

  changeJanelasFlutuantes() {
    JanelasFlutuantes = !JanelasFlutuantes;
    notifyListeners();
  }

  changeTelaBloqueio() {
    TelaBloqueio = !TelaBloqueio;
    notifyListeners();
  }

  changeTheme() {
    teste = !teste;
    notifyListeners();
  }
}
