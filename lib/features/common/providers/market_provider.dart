import 'package:flutter/material.dart';

class MarketProvider extends ChangeNotifier {
  String _marketName = "Carregando...";
  String _marketId = "";

  String get marketName => _marketName;
  String get marketId => _marketId;

  void updateMarket(String name, String id) {
    _marketName = name;
    _marketId = id;
    notifyListeners();
  }
}
