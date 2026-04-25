import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// ReceiptData — structured data extracted from a scanned receipt.
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

/// OcrService — real OCR receipt scanning using Google ML Kit Text Recognition
/// and ImagePicker for camera/gallery image selection.
class OcrService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from camera or gallery, then run OCR text extraction.
  /// Returns parsed Malaysian receipt data, or null if the user cancels.
  static Future<ReceiptData?> scanReceipt({ImageSource source = ImageSource.camera}) async {
    // 1. Pick image from the specified source
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );

    if (pickedFile == null) return null; // User cancelled

    // 2. Run ML Kit text recognition on the picked image
    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final String fullText = recognizedText.text;

      // 3. Parse the recognized text using existing regex logic
      return parseReceiptText(fullText);
    } finally {
      textRecognizer.close();
    }
  }

  /// Parse receipt text to extract total and date.
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

    // First non-empty line is usually merchant name
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      merchant = lines.first.trim();
    }

    return ReceiptData(
      date: date.isEmpty ? _todayDate() : date,
      amount: amount,
      merchant: merchant.isEmpty ? 'Unknown Merchant' : merchant,
      category: _guessCategory(text),
    );
  }

  static String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
