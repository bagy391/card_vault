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

    if (number.startsWith('4')) {
      return CardType.visa;
    } 
    
    // Macbook: 51-55 or 2221-2720
    if (RegExp(r'^(5[1-5]|2(22[1-9]|2[3-9]|[3-6]|7[0-1]|720))').hasMatch(number)) {
      return CardType.mastercard;
    }
    
    // Amex: 34, 37
    if (RegExp(r'^3[47]').hasMatch(number)) {
      return CardType.amex;
    }
    
    // JCB: 3528-3589
    if (RegExp(r'^35(2[8-9]|[3-8])').hasMatch(number)) {
      return CardType.jcb;
    }
    
    // UnionPay: 62
    if (number.startsWith('62')) {
      return CardType.unionPay;
    }
    
    // Diners Club: 300-305, 309, 36, 38, 39
    if (RegExp(r'^3(0[0-5]|09|6|8|9)').hasMatch(number)) {
      return CardType.dinersClub;
    }
    
    // Discover: 6011, 65, 644-649, 622
    // Note: 65 is also shared with RuPay broad range, but often treated as Discover/RuPay.
    if (RegExp(r'^6(011|5|4[4-9]|22)').hasMatch(number)) {
      return CardType.discover;
    }
    
    // RuPay: 60, 65, 81, 50, 35
    // 35 is handled by JCB above (overlaps). 50 handled here. 60/65 handled by Discover?
    // User provided broad RuPay regex: 60, 65, 81, 50, 35.
    // Since 6011 is Discover, but 60 is RuPay... 
    // And 65 is Discover and RuPay.
    // I will check for generic RuPay prefixes here.
    if (RegExp(r'^(60|65|81|50|35)').hasMatch(number)) {
      return CardType.rupay;
    }
    
    // Maestro: 50, 56-69, 6
    // 50 overlaps RuPay. 
    // catch-all for 6... might be Maestro.
    if (RegExp(r'^(5[06-9]|6)').hasMatch(number)) {
      return CardType.maestro;
    }

    return CardType.other;
  }

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
