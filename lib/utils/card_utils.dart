import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum CardType {
  visa,
  mastercard,
  amex,
  dinersClub,
  rupay,
  discover,
  jcb,
  unionPay,
  maestro,
  other,
}

class CardUtils {
  static CardType getCardTypeFromNumber(String input) {
    if (input.isEmpty) {
      return CardType.other;
    }

    String number = input.replaceAll(RegExp(r'\D'), '');

    // 1. RuPay
    // 60 (exclude 6011 for Discover), 652, 81, 82, 508
    if (RegExp(r'^(508|60(?!11)|652|81|82)').hasMatch(number)) {
      return CardType.rupay;
    }

    // 2. Visa
    if (number.startsWith('4')) {
      return CardType.visa;
    } 
    
    // 3. Mastercard
    // 51-55 or 2221-2720
    if (RegExp(r'^(5[1-5]|2(22[1-9]|2[3-9]|[3-6]|7[0-1]|720))').hasMatch(number)) {
      return CardType.mastercard;
    }
    
    // 4. Amex
    // 34, 37
    if (RegExp(r'^3[47]').hasMatch(number)) {
      return CardType.amex;
    }
    
    // 5. Diners Club
    // 300-305, 309, 36, 38, 39
    if (RegExp(r'^3(0[0-5]|09|6|8|9)').hasMatch(number)) {
      return CardType.dinersClub;
    }

    // 6. Discover
    // 6011, 65, 644-649, 622
    if (RegExp(r'^6(011|5|4[4-9]|22)').hasMatch(number)) {
      return CardType.discover;
    }
    
    // 7. JCB
    // 3528-3589
    if (RegExp(r'^35(2[8-9]|[3-8])').hasMatch(number)) {
      return CardType.jcb;
    }
    
    // 8. UnionPay
    if (number.startsWith('62')) {
      return CardType.unionPay;
    }
    
    // 9. Maestro
    // 50, 56-69
    // Note: 508 is RuPay, so we check 50 after RuPay.
    if (RegExp(r'^(5[06-9]|6)').hasMatch(number)) {
      return CardType.maestro;
    }

    return CardType.other;
  }

  static const List<List<Color>> cardGradients = [
    [Color(0xFF4A00E0), Color(0xFF8E2DE2)], // Purple
    [Color(0xFF000428), Color(0xFF004e92)], // Blue
    [Color(0xFF11998e), Color(0xFF38ef7d)], // Green
    [Color(0xFFcb2d3e), Color(0xFFef473a)], // Red
    [Color(0xFF232526), Color(0xFF414345)], // Black
    [Color(0xFFFF512F), Color(0xFFDD2476)], // Sunset
    [Color(0xFF2193b0), Color(0xFF6dd5ed)], // Sea
    [Color(0xFFF2994A), Color(0xFFF2C94C)], // Gold
    [Color(0xFF36D1DC), Color(0xFF5B86E5)], // Cosmic
  ];

  static Widget getCardIcon(CardType type) {
    switch (type) {
      case CardType.visa:
        return const Icon(FontAwesomeIcons.ccVisa, size: 32, color: Colors.white);
      case CardType.mastercard:
        return const Icon(FontAwesomeIcons.ccMastercard, size: 32, color: Colors.white);
      case CardType.amex:
        return const Icon(FontAwesomeIcons.ccAmex, size: 32, color: Colors.white);
      case CardType.dinersClub:
        return const Icon(FontAwesomeIcons.ccDinersClub, size: 32, color: Colors.white);
      case CardType.discover:
        return const Icon(FontAwesomeIcons.ccDiscover, size: 32, color: Colors.white);
      case CardType.rupay:
        // RuPay icon doesn't exist in FontAwesome free usually.
        // Returning a stylized Text widget.
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'RuPay',
            style: TextStyle(
              color: Colors.blue, // RuPay brand colors usually orange/green/blue arrows, blue text common.
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      case CardType.jcb:
        return const Icon(FontAwesomeIcons.ccJcb, size: 32, color: Colors.white);
      case CardType.unionPay:
        // FontAwesome might not have UnionPay free.
        return const Icon(FontAwesomeIcons.solidCreditCard, size: 32, color: Colors.white);
      case CardType.maestro:
        // Check availability, usually included.
        return const Icon(FontAwesomeIcons.ccMastercard, size: 32, color: Colors.white); // Fallback if no specific maestro
        // Actually, let's use Stripe or just Generic for now if not sure, 
        // but user expects specific. 
        // FontAwesome has cc-jcb. 
        // UnionPay is often not in free.
        // Maestro often grouped with Master.
      case CardType.other:
        return const Icon(Icons.credit_card, size: 32, color: Colors.white70);
    }
  }
}
