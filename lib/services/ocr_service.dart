/// OcrService — web-compatible abstraction layer for OCR receipt scanning.
/// On web: returns simulated Malaysian receipt data.
/// On mobile: ready to wire into `google_mlkit_text_recognition` plugin.

class ReceiptData {
  final String date;
  final double amount;
  final String merchant;
  final String category;

  const ReceiptData({
    required this.date,
    required this.amount,
    required this.merchant,
    required this.category,
  });
}

class OcrService {
  /// Simulate OCR text extraction from a receipt image.
  /// Returns parsed Malaysian receipt data.
  static Future<ReceiptData> scanReceipt() async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 2500));

    // For mobile integration, replace with:
    // final inputImage = InputImage.fromFile(file);
    // final recognizer = TextRecognizer();
    // final result = await recognizer.processImage(inputImage);
    // return _parseReceiptText(result.text);

    return const ReceiptData(
      date: '2026-04-25',
      amount: 245.50,
      merchant: 'Grab Malaysia',
      category: 'Travel',
    );
  }

  /// Parse receipt text to extract total and date (for real ML Kit integration).
  /// Handles Malaysian receipt formats with RM currency.
  static ReceiptData parseReceiptText(String text) {
    double amount = 0;
    String date = '';
    String merchant = '';

    // Find RM amount (e.g., "RM 245.50", "RM245.50", "TOTAL: RM 245.50")
    final amountRegex = RegExp(r'RM\s*(\d+\.?\d*)', caseSensitive: false);
    final amountMatches = amountRegex.allMatches(text);
    if (amountMatches.isNotEmpty) {
      // Take the last (usually total) amount
      amount = double.tryParse(amountMatches.last.group(1)!) ?? 0;
    }

    // Find date (dd/MM/yyyy or dd-MM-yyyy)
    final dateRegex = RegExp(r'(\d{2})[/\-](\d{2})[/\-](\d{4})');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      date = '${dateMatch.group(3)}-${dateMatch.group(2)}-${dateMatch.group(1)}';
    }

    // First line is usually merchant name
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      merchant = lines.first.trim();
    }

    return ReceiptData(
      date: date.isEmpty ? '2026-04-25' : date,
      amount: amount,
      merchant: merchant.isEmpty ? 'Unknown Merchant' : merchant,
      category: _guessCategory(text),
    );
  }

  static String _guessCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('grab') || lower.contains('taxi') || lower.contains('flight') || lower.contains('petrol')) return 'Travel';
    if (lower.contains('restaurant') || lower.contains('food') || lower.contains('nasi') || lower.contains('cafe')) return 'Meals';
    if (lower.contains('hospital') || lower.contains('clinic') || lower.contains('pharmacy')) return 'Medical';
    if (lower.contains('laptop') || lower.contains('monitor') || lower.contains('keyboard')) return 'Equipment';
    return 'Travel';
  }
}
