import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Extracted data from a Milwaukee parking citation image
class TicketOcrResult {
  const TicketOcrResult({
    this.citationNumber,
    this.amount,
    this.licensePlate,
    this.violationType,
    this.location,
    this.issuedDate,
    this.issuedTime,
    this.meterNumber,
    this.officerBadge,
    this.rawText,
    this.confidence = 0.0,
  });

  /// Citation/ticket number (e.g., "12345678")
  final String? citationNumber;

  /// Fine amount in dollars
  final double? amount;

  /// License plate number
  final String? licensePlate;

  /// Type of violation
  final String? violationType;

  /// Street address or intersection
  final String? location;

  /// Date the ticket was issued
  final DateTime? issuedDate;

  /// Time the ticket was issued (as string, e.g., "2:30 PM")
  final String? issuedTime;

  /// Parking meter number if applicable
  final String? meterNumber;

  /// Officer badge number
  final String? officerBadge;

  /// Raw OCR text for debugging
  final String? rawText;

  /// Overall confidence score (0.0 - 1.0)
  final double confidence;

  /// Check if any useful data was extracted
  bool get hasData =>
      citationNumber != null ||
      amount != null ||
      licensePlate != null ||
      violationType != null ||
      location != null;

  /// Number of fields successfully extracted
  int get fieldsExtracted {
    int count = 0;
    if (citationNumber != null) count++;
    if (amount != null) count++;
    if (licensePlate != null) count++;
    if (violationType != null) count++;
    if (location != null) count++;
    if (issuedDate != null) count++;
    if (meterNumber != null) count++;
    return count;
  }

  @override
  String toString() =>
      'TicketOcrResult(citation: $citationNumber, amount: $amount, plate: $licensePlate, '
      'violation: $violationType, location: $location, date: $issuedDate, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Service for extracting ticket data from photos using OCR
class TicketOcrService {
  static final TicketOcrService _instance = TicketOcrService._internal();
  factory TicketOcrService() => _instance;
  TicketOcrService._internal();

  static TicketOcrService get instance => _instance;

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Known Milwaukee violation types for matching
  static const _violationKeywords = <String, String>{
    'NIGHT PARKING': 'NIGHT PARKING',
    'NIGHT PRKG': 'NIGHT PARKING',
    'WINTER RESTRICTED': 'NIGHT PARKING - WINTER RESTRICTED',
    'WRONG SIDE': 'NIGHT PARKING - WRONG SIDE',
    'METER VIOLATION': 'METER PARKING VIOLATION',
    'METER': 'METER PARKING VIOLATION',
    'EXPIRED METER': 'METER PARKING VIOLATION',
    'OVERTIME': 'PARKED IN EXCESS OF 2 HOURS PROHIBITED',
    '2 HOUR': 'PARKED IN EXCESS OF 2 HOURS PROHIBITED',
    'EXCESS': 'PARKED IN EXCESS OF 2 HOURS PROHIBITED',
    'OFFICIAL SIGN': 'PARKING PROHIBITED BY OFFICIAL SIGN',
    'NO PARKING': 'PARKING PROHIBITED BY OFFICIAL SIGN',
    'PROHIBITED': 'PARKING PROHIBITED BY OFFICIAL SIGN',
    'REGISTRATION': 'FAILURE TO DISPLAY CURRENT REGISTRATION',
    'EXPIRED REG': 'FAILURE TO DISPLAY CURRENT REGISTRATION',
    'FIRE HYDRANT': 'FIRE HYDRANT VIOLATION',
    'HYDRANT': 'FIRE HYDRANT VIOLATION',
    'CROSSWALK': 'CROSSWALK VIOLATION',
    'BUS STOP': 'PARKED IN BUS STOP/ZONE',
    'BUS ZONE': 'PARKED IN BUS STOP/ZONE',
    'HANDICAP': 'HANDICAPPED ZONE VIOLATION',
    'DISABLED': 'HANDICAPPED ZONE VIOLATION',
    'LOADING ZONE': 'LOADING ZONE VIOLATION',
    'DOUBLE PARK': 'DOUBLE PARKING',
    'STREET CLEANING': 'STREET CLEANING VIOLATION',
    'SWEEPING': 'STREET CLEANING VIOLATION',
    'ALTERNATE SIDE': 'ALTERNATE SIDE PARKING VIOLATION',
  };

  /// Extract ticket data from an image file
  Future<TicketOcrResult> scanTicket(File imageFile) async {
    try {
      debugPrint('🔍 Starting OCR scan on: ${imageFile.path}');

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;
      debugPrint('📝 OCR raw text (${rawText.length} chars):\n$rawText');

      if (rawText.isEmpty) {
        debugPrint('⚠️ No text detected in image');
        return const TicketOcrResult(confidence: 0.0);
      }

      // Parse the recognized text
      final result = _parseTicketText(rawText);
      debugPrint('✅ OCR result: $result');

      return result;
    } catch (e, stack) {
      debugPrint('❌ OCR scan failed: $e\n$stack');
      return const TicketOcrResult(confidence: 0.0);
    }
  }

  /// Parse raw OCR text into structured ticket data
  TicketOcrResult _parseTicketText(String rawText) {
    final text = rawText.toUpperCase();
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // Extract citation number (usually 8 digits)
    final citationNumber = _extractCitationNumber(text);

    // Extract fine amount
    final amount = _extractAmount(text);

    // Extract license plate
    final licensePlate = _extractLicensePlate(text);

    // Extract violation type
    final violationType = _extractViolationType(text);

    // Extract location/address
    final location = _extractLocation(lines);

    // Extract date
    final issuedDate = _extractDate(text);

    // Extract time
    final issuedTime = _extractTime(text);

    // Extract meter number
    final meterNumber = _extractMeterNumber(text);

    // Extract officer badge
    final officerBadge = _extractOfficerBadge(text);

    // Calculate confidence based on fields extracted
    int fieldsFound = 0;
    if (citationNumber != null) fieldsFound++;
    if (amount != null) fieldsFound++;
    if (licensePlate != null) fieldsFound++;
    if (violationType != null) fieldsFound++;
    if (location != null) fieldsFound++;
    if (issuedDate != null) fieldsFound++;

    // Confidence: fields found / important fields (6 main ones)
    final confidence = fieldsFound / 6.0;

    return TicketOcrResult(
      citationNumber: citationNumber,
      amount: amount,
      licensePlate: licensePlate,
      violationType: violationType,
      location: location,
      issuedDate: issuedDate,
      issuedTime: issuedTime,
      meterNumber: meterNumber,
      officerBadge: officerBadge,
      rawText: rawText,
      confidence: confidence,
    );
  }

  /// Extract citation number (usually 8 digits, sometimes with prefix)
  String? _extractCitationNumber(String text) {
    // Milwaukee citations are typically 8 digit numbers
    // Sometimes prefixed with letters like "V" or "P"
    final patterns = [
      RegExp(r'CITATION\s*#?\s*:?\s*([A-Z]?\d{7,8})', caseSensitive: false),
      RegExp(r'TICKET\s*#?\s*:?\s*([A-Z]?\d{7,8})', caseSensitive: false),
      RegExp(r'NO\.?\s*:?\s*([A-Z]?\d{7,8})', caseSensitive: false),
      RegExp(r'\b([A-Z]?\d{8})\b'), // Standalone 8 digit number
      RegExp(r'\b(\d{7,8})\b'), // 7-8 digit number
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final number = match.group(1);
        if (number != null && number.length >= 7) {
          return number;
        }
      }
    }
    return null;
  }

  /// Extract fine amount (look for $ followed by digits)
  double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'\$\s*(\d{1,3}(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'FINE\s*:?\s*\$?\s*(\d{1,3}(?:\.\d{2})?)', caseSensitive: false),
      RegExp(
        r'AMOUNT\s*:?\s*\$?\s*(\d{1,3}(?:\.\d{2})?)',
        caseSensitive: false,
      ),
      RegExp(r'DUE\s*:?\s*\$?\s*(\d{1,3}(?:\.\d{2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          // Milwaukee fines typically range from $15 to $200
          if (amount != null && amount >= 10 && amount <= 300) {
            return amount;
          }
        }
      }
    }
    return null;
  }

  /// Extract license plate number
  String? _extractLicensePlate(String text) {
    final patterns = [
      RegExp(r'PLATE\s*#?\s*:?\s*([A-Z0-9]{3,8})', caseSensitive: false),
      RegExp(r'LICENSE\s*:?\s*([A-Z0-9]{3,8})', caseSensitive: false),
      RegExp(r'LIC\s*#?\s*:?\s*([A-Z0-9]{3,8})', caseSensitive: false),
      RegExp(r'REG\s*#?\s*:?\s*([A-Z0-9]{3,8})', caseSensitive: false),
      // Wisconsin plates are typically 3 letters + 4 numbers or variants
      RegExp(r'\b([A-Z]{2,3}[-\s]?[0-9]{3,4})\b'),
      RegExp(r'\b([0-9]{3,4}[-\s]?[A-Z]{2,3})\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final plate = match.group(1)?.replaceAll(RegExp(r'[\s-]'), '');
        if (plate != null && plate.length >= 5 && plate.length <= 8) {
          return plate;
        }
      }
    }
    return null;
  }

  /// Extract violation type by matching keywords
  String? _extractViolationType(String text) {
    // First try exact matches for common violations
    for (final entry in _violationKeywords.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try to find violation section
    final violationPatterns = [
      RegExp(r'VIOLATION\s*:?\s*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'OFFENSE\s*:?\s*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'CHARGE\s*:?\s*(.+?)(?:\n|$)', caseSensitive: false),
    ];

    for (final pattern in violationPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final violation = match.group(1)?.trim();
        if (violation != null && violation.length >= 5) {
          // Try to match to our known list
          for (final entry in _violationKeywords.entries) {
            if (violation.contains(entry.key)) {
              return entry.value;
            }
          }
          // Return raw violation if no match
          return violation.length > 50 ? violation.substring(0, 50) : violation;
        }
      }
    }
    return null;
  }

  /// Extract location/address from lines
  String? _extractLocation(List<String> lines) {
    // Look for location indicators
    final locationPatterns = [
      RegExp(r'LOCATION\s*:?\s*(.+)', caseSensitive: false),
      RegExp(r'ADDRESS\s*:?\s*(.+)', caseSensitive: false),
      RegExp(r'AT\s*:?\s*(.+)', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in locationPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final loc = match.group(1)?.trim();
          if (loc != null && loc.length >= 5) {
            return loc;
          }
        }
      }
    }

    // Look for street patterns (N/S/E/W followed by street name)
    final streetPattern = RegExp(
      r'\b(\d{1,5}\s+[NSEW]\.?\s+[\w\s]+(?:ST|AVE|BLVD|DR|RD|WAY|CT|PL|LN))\b',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = streetPattern.firstMatch(line);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    // Look for intersection format (Street & Street)
    final intersectionPattern = RegExp(
      r'\b([\w\s]+)\s*[&@]\s*([\w\s]+(?:ST|AVE|BLVD|DR|RD))\b',
      caseSensitive: false,
    );
    final text = lines.join(' ');
    final match = intersectionPattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)?.trim()} & ${match.group(2)?.trim()}';
    }

    return null;
  }

  /// Extract date from text
  DateTime? _extractDate(String text) {
    final patterns = [
      // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
      // Month DD, YYYY
      RegExp(
        r'\b(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\.?\s*(\d{1,2}),?\s*(\d{2,4})\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (pattern.pattern.contains('JAN')) {
            // Month name format
            final monthStr = match.group(1)?.toUpperCase();
            final day = int.tryParse(match.group(2) ?? '') ?? 1;
            var year = int.tryParse(match.group(3) ?? '') ?? 2026;
            if (year < 100) year += 2000;

            final monthMap = {
              'JAN': 1,
              'FEB': 2,
              'MAR': 3,
              'APR': 4,
              'MAY': 5,
              'JUN': 6,
              'JUL': 7,
              'AUG': 8,
              'SEP': 9,
              'OCT': 10,
              'NOV': 11,
              'DEC': 12,
            };
            final month = monthMap[monthStr?.substring(0, 3)] ?? 1;
            return DateTime(year, month, day);
          } else {
            // Numeric format
            final month = int.tryParse(match.group(1) ?? '') ?? 1;
            final day = int.tryParse(match.group(2) ?? '') ?? 1;
            var year = int.tryParse(match.group(3) ?? '') ?? 2026;
            if (year < 100) year += 2000;
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
              return DateTime(year, month, day);
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Extract time from text
  String? _extractTime(String text) {
    final patterns = [
      RegExp(r'\b(\d{1,2}:\d{2}\s*[AP]\.?M\.?)\b', caseSensitive: false),
      RegExp(r'\b(\d{1,2}:\d{2})\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Extract parking meter number
  String? _extractMeterNumber(String text) {
    final patterns = [
      RegExp(r'METER\s*#?\s*:?\s*(\d{3,6})', caseSensitive: false),
      RegExp(r'METER\s*NO\.?\s*:?\s*(\d{3,6})', caseSensitive: false),
      RegExp(r'#?\s*(\d{4,6})\s*METER', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Extract officer badge number
  String? _extractOfficerBadge(String text) {
    final patterns = [
      RegExp(r'BADGE\s*#?\s*:?\s*(\d{3,6})', caseSensitive: false),
      RegExp(r'OFFICER\s*#?\s*:?\s*(\d{3,6})', caseSensitive: false),
      RegExp(r'OFC\s*#?\s*:?\s*(\d{3,6})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
