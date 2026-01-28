import 'package:flutter/foundation.dart';
import '../models/credit_card.dart';
import '../services/storage_service.dart';

class CardProvider with ChangeNotifier {
  List<CreditCard> _cards = [];
  final StorageService _storageService = StorageService();
  bool _isLoading = true;

  List<CreditCard> get cards => _cards;
  bool get isLoading => _isLoading;

  Future<void> loadCards() async {
    _isLoading = true;
    notifyListeners();
    _cards = await _storageService.loadCards();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCard(CreditCard card) async {
    _cards.add(card);
    notifyListeners();
    await _storageService.saveCards(_cards);
  }

  Future<void> updateCard(CreditCard updatedCard) async {
    final index = _cards.indexWhere((c) => c.id == updatedCard.id);
    if (index != -1) {
      _cards[index] = updatedCard;
      notifyListeners();
      await _storageService.saveCards(_cards);
    }
  }

  Future<void> deleteCard(String id) async {
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
    await _storageService.saveCards(_cards);
  }
}
