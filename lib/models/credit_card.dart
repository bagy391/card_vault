import 'dart:convert';

class CreditCard {
  final String id;
  final String bankName;
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final String cardHolderName;
  final int colorIndex;

  CreditCard({
    required this.id,
    required this.bankName,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    required this.cardHolderName,
    required this.colorIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardHolderName': cardHolderName,
      'colorIndex': colorIndex,
    };
  }

  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'],
      bankName: map['bankName'],
      cardNumber: map['cardNumber'],
      expiryDate: map['expiryDate'],
      cvv: map['cvv'],
      cardHolderName: map['cardHolderName'],
      colorIndex: map['colorIndex'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CreditCard.fromJson(String source) => CreditCard.fromMap(json.decode(source));
  
  // Helper to verify expiry
  bool get isExpired {
    if (expiryDate.isEmpty || !expiryDate.contains('/')) return false;
    final parts = expiryDate.split('/');
    if (parts.length != 2) return false;
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse('20${parts[1]}') ?? 0; // Assuming YY format
    if (year == 0 || month == 0) return false;
    
    final now = DateTime.now();
    final expiry = DateTime(year, month + 1, 0); // End of the month
    return now.isAfter(expiry);
  }
}
