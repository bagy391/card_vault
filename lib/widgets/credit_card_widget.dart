import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../utils/card_utils.dart';

class CreditCardWidget extends StatefulWidget {
  final CreditCard card;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CreditCardWidget({super.key, required this.card, this.onTap, this.onLongPress});

  @override
  State<CreditCardWidget> createState() => _CreditCardWidgetState();
}

class _CreditCardWidgetState extends State<CreditCardWidget> {
  bool _showCvv = false;

  void _toggleCvv() {
    setState(() {
      _showCvv = !_showCvv;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine color based on index
    final List<List<Color>> gradients = [
      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], // Purple
      [const Color(0xFF000428), const Color(0xFF004e92)], // Blue
      [const Color(0xFF11998e), const Color(0xFF38ef7d)], // Green
      [const Color(0xFFcb2d3e), const Color(0xFFef473a)], // Red
      [const Color(0xFF232526), const Color(0xFF414345)], // Black
    ];

    final gradientColors = gradients[widget.card.colorIndex % gradients.length];

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background patterns (Circles)
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
               Positioned(
                left: -50,
                bottom: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              
              Padding(
              padding: const EdgeInsets.all(16.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 64, // Estimate width constraints inside FittedBox
                  height: 168, // 200 - 32 padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Bank Name and Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.card.bankName.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CardUtils.getCardIcon(CardUtils.getCardTypeFromNumber(widget.card.cardNumber)),
                        ],
                      ),
    
                      // Chip Mockup
                      Container(
                        width: 50,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
    
                      // Card Number
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatCardNumber(widget.card.cardNumber),
                                style: GoogleFonts.sourceCodePro(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: widget.card.cardNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Card number copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.copy,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
    
                      // Bottom Row: Name and Expiry
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CARD HOLDER',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  widget.card.cardHolderName.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPIRES',
                                style: GoogleFonts.inter(
                                  color: widget.card.isExpired ? Colors.redAccent : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: widget.card.isExpired ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                widget.card.expiryDate,
                                style: GoogleFonts.inter(
                                  color: widget.card.isExpired ? Colors.redAccent : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: widget.card.isExpired ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24), // Added spacing
                          GestureDetector(
                            onTap: _toggleCvv,
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'CVV',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _showCvv ? widget.card.cvv : '***',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _showCvv ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
              
              if (widget.card.isExpired)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red, width: 4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'EXPIRED',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCardNumber(String number) {
    number = number.replaceAll(RegExp(r'\s+\b|\b\s'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      buffer.write(number[i]);
      final index = i + 1;
      if (index % 4 == 0 && index != number.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}
