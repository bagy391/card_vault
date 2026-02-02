import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isScanBusy = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Simple initialization for capture
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.veryHigh, // Higher res for text
          enableAudio: false,
        );

        await _cameraController!.initialize();
        setState(() {});
      } else {
        setState(() => _statusText = 'No camera found');
      }
    } else {
      setState(() => _statusText = 'Camera permission denied');
    }
  }

  Future<void> _captureAndScan() async {
    if (_isScanBusy || _cameraController == null) return;
    
    setState(() => _isScanBusy = true);

    try {
      final imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);

      final recognizedText = await _textRecognizer.processImage(inputImage);
      final cardData = _extractCardData(recognizedText);

      if (cardData != null) {
        if (mounted) {
          Navigator.of(context).pop(cardData);
        }
      } else {
        // Feedback if no data found
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('No card detected, please try again.')),
           );
        }
      }
    } catch (e) {
      debugPrint('Error capturing/scanning: $e');
    } finally {
      if (mounted) setState(() => _isScanBusy = false);
    }
  }

  Map<String, String>? _extractCardData(RecognizedText text) {
    String? number;
    String? expiry;
    String? name;
    String? cvv;

    // Helper regex
    // Allow spaces like 10 / 25. Note: inside [] . is literal. Hyphen at start/end or escaped.
    final expiryRegex = RegExp(r'\b(0[1-9]|1[0-2])\s*[-./]\s*([0-9]{2,4})\b');
    final cvvRegex = RegExp(r'(?:CVV|CVC|CID|CV2)\s*[:.]?\s*([0-9]{3,4})', caseSensitive: false);
    
    // Valid Thru keywords - highest priority
    final validThruRegex = RegExp(r'(VALID\s*(?:THRU|THROUGH)|EXPIRES|GOOD\s*THRU)', caseSensitive: false);

    // Track potential dates to compare
    List<String> potentialDates = [];
    String? priorityExpiryDate;
    
    // Variables for name extraction
    List<_TextCandidate> nameCandidates = [];
    double globalMaxHeight = 0;
    
    final blocklist = {
      'VISA', 'MASTERCARD', 'AMERICAN EXPRESS', 'AMEX', 'DISCOVER', 'DINERS CLUB', 'JCB', 'UNIONPAY', 'RUPAY',
      'DEBIT', 'CREDIT', 'PREPAID', 'GIFT', 'BUSINESS', 'CORPORATE', 'PLATINUM', 'GOLD', 'TITANIUM', 'INFINITE', 
      'SIGNATURE', 'WORLD', 'ELITE', 'REWARDS', 'POINTS', 'MILES', 'CASH', 'BACK', 'CARD', 'HOLDER', 'MEMBER', 'SINCE',
      'VALID', 'FROM', 'THRU', 'EXPIRES', 'DATE', 'SECURITY', 'CODE', 'CVV', 'CVC', 'CID', 'BANK', 'FCU', 'CREDIT UNION', 
      'CHASE', 'CITI', 'WELLS', 'FARGO', 'CAPITAL', 'ONE', 'HSBC', 'BARCLAYS', 'LLOYDS', 'NATWEST', 'SANTANDER', 'RBC', 'TD', 
      'SCOTIA', 'BMO', 'CIBC', 'HDFC', 'ICICI', 'SBI', 'AXIS', 'KOTAK', 'YES', 'INDUSIND', 'IDFC', 'PNB', 'BOB', 'CANARA', 'UNION',
      'COMMERCIAL', 'ELECTRON', 'MAESTRO', 'CIRRUS', 'PLUS', 'INTERAC', 'NETWORKS', 'INTERNATIONAL', 'NATIONAL', 'TRUST'
    };

    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    for (TextBlock block in text.blocks) {
      for (TextLine line in block.lines) {
        final lineText = line.text;
        
        // 1. Check for Card Number (Priority)
        if (number == null) {
           final potentialNumber = lineText.replaceAll(RegExp(r'[^0-9]'), '');
           if (potentialNumber.length >= 13 && potentialNumber.length <= 19) {
             if (isValidLuhn(potentialNumber)) {
               number = potentialNumber;
               continue; 
             }
           }
        }

        // 2. Collect potential Expiry Dates
        // Need to loop through all matches in line, not just firstMatch, in case multiple dates exist
        final matches = expiryRegex.allMatches(lineText);
        for (final match in matches) {
          final dateStr = match.group(0)!;
          
          // STRICT VALIDATION: Check if it's a plausible expiry date
          // Valid range: Current year up to +20 years
          bool isValidDate = false;
          try {
             final parts = dateStr.split(RegExp(r'[-./\s]+')); // Split by separators
             if (parts.length >= 2) {
               int m = int.parse(parts[0]);
               int y = int.parse(parts[1]);
               
               // Normalize 2-digit year
               if (y < 100) y += 2000;
               
               // Check bounds (e.g. 2024 to 2044)
               if (y >= (currentYear - 1) && y <= (currentYear + 20)) {
                  // If current year, month must be >= current month
                  if (y > currentYear || (y == currentYear && m >= currentMonth)) {
                    isValidDate = true;
                  }
               }
             }
          } catch (e) {
            // parsing error, ignore
          }

          if (isValidDate) {
            // If explicitly labeled "Valid Thru", take it immediately as priority
            if (validThruRegex.hasMatch(lineText)) {
               priorityExpiryDate = dateStr;
            }
            
            // Avoid "Valid From" lines if explicitly labeled
            if (!lineText.toUpperCase().contains('VALID FROM') && 
                !lineText.toUpperCase().contains('MEMBER SINCE')) {
               potentialDates.add(dateStr);
            }
          }
        }
        
        // 3. Name Extraction
        if (!lineText.contains(RegExp(r'\d')) && lineText.length > 5) {
             final words = lineText.trim().split(RegExp(r'\s+'));
             if (words.length >= 2) {
                bool isBlocked = false;
                for (var word in words) {
                   if (blocklist.contains(word.toUpperCase())) { 
                      isBlocked = true;
                      break;
                   }
                }
                
                if (!isBlocked) {
                   final height = line.boundingBox.height;
                   if (height > globalMaxHeight) globalMaxHeight = height;
                   nameCandidates.add(_TextCandidate(text: lineText, height: height));
                }
             }
        }

        // 4. Check for CVV (Context Aware)
        // First check specifically for "CVC 123" patterns
        final cvvMatch = cvvRegex.firstMatch(lineText);
        if (cvvMatch != null) {
           cvv = cvvMatch.group(1);
        }
        
        // Fallback: Standalone 3-4 digits
        if (cvv == null) {
           final possibleCvv = lineText.replaceAll(RegExp(r'[^0-9]'), '');
           if ((possibleCvv.length == 3 || possibleCvv.length == 4) && lineText.length <= 5) {
             if (!lineText.contains('/')) {
                cvv = possibleCvv;
             }
           }
        }
      }
    }
    
    // Process gathered dates
    if (priorityExpiryDate != null) {
       expiry = priorityExpiryDate;
    } else if (potentialDates.isNotEmpty) {
       // Deduplicate
       final uniqueDates = potentialDates.toSet().toList();
       
       if (uniqueDates.length == 1) {
         expiry = uniqueDates.first;
       } else {
         try {
           uniqueDates.sort((a, b) {
              final cleanA = a.replaceAll(' ', '');
              final cleanB = b.replaceAll(' ', '');
              // Flexible separator split
              final partsA = cleanA.split(RegExp(r'[\/\.-]'));
              final partsB = cleanB.split(RegExp(r'[\/\.-]'));
              
              int monthA = int.parse(partsA[0]);
              int yearA = int.parse(partsA[1]);
              
              int monthB = int.parse(partsB[0]);
              int yearB = int.parse(partsB[1]);
              
              if (yearA < 100) yearA += 2000;
              if (yearB < 100) yearB += 2000;
              
              final dateA = DateTime(yearA, monthA);
              final dateB = DateTime(yearB, monthB);
              
              return dateA.compareTo(dateB);
           });
           expiry = uniqueDates.last; 
         } catch (e) {
           expiry = uniqueDates.last; 
         }
       }
    }
    
    // Process Name Candidates
    if (nameCandidates.isNotEmpty) {
       // Sort by height descending
       nameCandidates.sort((a, b) => b.height.compareTo(a.height));
       if (nameCandidates.isNotEmpty) {
          name = nameCandidates.first.text;
       }
    }

    // Relaxed condition
    if (number != null) {
      debugPrint('Card Data Found: Number=$number, Expiry=$expiry, Name=$name, CVV=$cvv');
      return {
        'cardNumber': number,
        'expiryDate': expiry ?? '',
        'cardHolderName': name ?? '',
        'cvv': cvv ?? '',
      };
    }
    
    return null;
  }
  
  bool isValidLuhn(String input) {
    int sum = 0;
    bool alternate = false;
    for (int i = input.length - 1; i >= 0; i--) {
      int n = int.parse(input[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_statusText != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text(_statusText!, style: const TextStyle(color: Colors.white))),
      );
    }
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final size = MediaQuery.of(context).size;
    var scale = 1.0;
    
    // Calculate scale to ensure BoxFit.cover behavior
    try {
      final cameraAspectRatio = _cameraController!.value.aspectRatio;
      scale = 1 / (cameraAspectRatio * size.aspectRatio);
      // Ensure we always cover
      if (scale < 1) scale = 1 / scale;
    } catch (e) {
      scale = 1.0;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Feed - Full Screen
          Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(_cameraController!),
            ),
          ),
          
          // Overlay - Darkened background with clear window
          Container(
            decoration: ShapeDecoration(
              shape: _ScannerOverlayShape(
                borderColor: Colors.white,
                borderRadius: 12,
                borderLength: 40,
                borderWidth: 4, // Thinner, cleaner border
                cutOutSize: 320, // Slightly larger window
                overlayColor: Colors.black.withValues(alpha: 0.5), // Darker overlay for better contrast
              ),
            ),
          ),
          
          // Header / Close button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          
          const Positioned(
            top: 100,
            left: 0, 
            right: 0,
            child: Text(
              'Align card within frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),

          // Shutter Button area
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_isScanBusy)
                   const CircularProgressIndicator(color: Colors.white)
                else
                  GestureDetector(
                    onTap: _captureAndScan,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withValues(alpha: 0.1), 
                      ),
                      child: Center(
                         child: Container(
                           width: 60,
                           height: 60,
                           decoration: const BoxDecoration(
                             color: Colors.white,
                             shape: BoxShape.circle,
                           ),
                         ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tap to Scan', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the cut-out overlay look
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 4.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 12,
    this.borderLength = 40,
    this.cutOutSize = 300,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize * 1.58, // Standard credit card aspect ratio ~1.58
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    var innerPath = getInnerPath(rect);
    return Path.combine(PathOperation.difference, path, innerPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = cutOutSize * 1.58;
    final height = cutOutSize;
    
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
      
    final boxRect = Rect.fromCenter(center: rect.center, width: width, height: height);

    // Draw darkened background with burnout
    canvas.drawPath(
        getOuterPath(rect),
        backgroundPaint
    );

    // Draw corners
    // Top Left
    canvas.drawLine(boxRect.topLeft, boxRect.topLeft + Offset(borderLength, 0), borderPaint);
    canvas.drawLine(boxRect.topLeft, boxRect.topLeft + Offset(0, borderLength), borderPaint);
    
    // Top Right
    canvas.drawLine(boxRect.topRight, boxRect.topRight - Offset(borderLength, 0), borderPaint);
    canvas.drawLine(boxRect.topRight, boxRect.topRight + Offset(0, borderLength), borderPaint);
    
    // Bottom Left
    canvas.drawLine(boxRect.bottomLeft, boxRect.bottomLeft + Offset(borderLength, 0), borderPaint);
    canvas.drawLine(boxRect.bottomLeft, boxRect.bottomLeft - Offset(0, borderLength), borderPaint);
    
    // Bottom Right
    canvas.drawLine(boxRect.bottomRight, boxRect.bottomRight - Offset(borderLength, 0), borderPaint);
    canvas.drawLine(boxRect.bottomRight, boxRect.bottomRight - Offset(0, borderLength), borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

class _TextCandidate {
  final String text;
  final double height;
  
  _TextCandidate({required this.text, required this.height});
}
