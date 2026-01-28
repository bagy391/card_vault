import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/credit_card.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();
  static const _keyParams = 'encryption_key';
  static const _dataKey = 'encrypted_cards';

  // Get or create encryption key
  Future<String> _getEncryptionKey() async {
    String? key = await _secureStorage.read(key: _keyParams);
    if (key == null) {
      key = encrypt.Key.fromSecureRandom(32).base64;
      await _secureStorage.write(key: _keyParams, value: key);
    }
    return key;
  }

  // Encrypt and Save cards
  Future<void> saveCards(List<CreditCard> cards) async {
    final keyString = await _getEncryptionKey();
    final key = encrypt.Key.fromBase64(keyString);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final jsonString = json.encode(cards.map((e) => e.toMap()).toList());
    final encrypted = encrypter.encrypt(jsonString, iv: iv);
    
    // Store IV and Encrypted date together
    final storedValue = '${iv.base64}:${encrypted.base64}';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataKey, storedValue);
  }

  // Load and Decrypt cards
  Future<List<CreditCard>> loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_dataKey);

    if (storedValue == null) return [];

    try {
      final keyString = await _getEncryptionKey();
      final key = encrypt.Key.fromBase64(keyString);
      
      final parts = storedValue.split(':');
      if (parts.length != 2) return [];

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      final List<dynamic> jsonList = json.decode(decrypted);

      return jsonList.map((e) => CreditCard.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error decrypting data: $e');
      return [];
    }
  }
}
