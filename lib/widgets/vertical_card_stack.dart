import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import 'credit_card_widget.dart';

class VerticalCardStack extends StatefulWidget {
  final List<CreditCard> cards;
  final Function(CreditCard) onCardTap;

  const VerticalCardStack({
    super.key,
    required this.cards,
    required this.onCardTap,
  });

  @override
  State<VerticalCardStack> createState() => _VerticalCardStackState();
}

class _VerticalCardStackState extends State<VerticalCardStack> {
  String? _expandedCardId;
  // Constants for layout
  final double _cardHeight = 200.0;
  final double _collapsedOffset = 70.0;
  final double _expandedGap = 150.0;

  void _toggleCard(CreditCard card) {
    setState(() {
      if (_expandedCardId == card.id) {
        _expandedCardId = null;
      } else {
        _expandedCardId = card.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total height
    double totalHeight = (widget.cards.length - 1) * _collapsedOffset + 
                        _cardHeight + 
                        100.0;
    
    if (_expandedCardId != null) {
      totalHeight += _expandedGap;
    }

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: List.generate(widget.cards.length, (index) {
          final card = widget.cards[index];
          
          // Calculate position
          bool isBelowExpanded = false;
          if (_expandedCardId != null) {
            final expandedIndex = widget.cards
                .indexWhere((c) => c.id == _expandedCardId);
            isBelowExpanded = index > expandedIndex;
          }

          double topPos = index * _collapsedOffset;
          if (isBelowExpanded) {
            topPos += _expandedGap;
          }

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            top: topPos + 40,
            left: 0,
            right: 0,
            height: _cardHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Hero(
                tag: card.id,
                child: CreditCardWidget(
                  card: card,
                  onTap: () => _toggleCard(card),
                  onLongPress: () => widget.onCardTap(card),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}