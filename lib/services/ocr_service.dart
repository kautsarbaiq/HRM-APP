import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// ReceiptData — structured data extracted from a scanned receipt.
class ReceiptData {
  final String date;
  final double amount;
  final String merchant;
  final String category;
  final String? imagePath;

  const ReceiptData({
    required this.date,
    required this.amount,
    required this.merchant,
    required this.category,
    this.imagePath,
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
      return parseReceiptText(fullText, pickedFile.path);
    } finally {
      textRecognizer.close();
    }
  }

  /// Parse receipt text to extract total and date.
  /// Handles Malaysian receipt formats with RM currency.
  static ReceiptData parseReceiptText(String text, [String? imagePath]) {
    double amount = 0;
    String date = '';
    String merchant = '';

    // Find Amount: Look for keywords like TOTAL, AMOUNT DUE, GRAND TOTAL
    final keywordTotalRegex = RegExp(r'(?:TOTAL|AMOUNT DUE|GRAND TOTAL|NET TOTAL|BALANCE|AMT).*\s(?:RM)?\s*(\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2})', caseSensitive: false);
    final keywordMatch = keywordTotalRegex.firstMatch(text);
    if (keywordMatch != null) {
      amount = double.tryParse(keywordMatch.group(1)!.replaceAll(',', '')) ?? 0;
    } else {
      // Fallback: Find RM amount (e.g., "RM 245.50", "RM 1,250.00")
      final amountRegex = RegExp(r'RM\s*(\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2})', caseSensitive: false);
      final amountMatches = amountRegex.allMatches(text);
      if (amountMatches.isNotEmpty) {
        amount = double.tryParse(amountMatches.last.group(1)!.replaceAll(',', '')) ?? 0;
      }
    }

    // Find Date: Support dd/MM/yyyy, dd-MM-yyyy, dd.MM.yy
    final dateRegex = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      String y = dateMatch.group(3)!;
      if (y.length == 2) y = '20$y'; // Assuming 2000s for 2-digit years
      date = '$y-${dateMatch.group(2)!.padLeft(2, '0')}-${dateMatch.group(1)!.padLeft(2, '0')}';
    } else {
      // Try text dates like 12 Jan 2024
      final txtDateRegex = RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})', caseSensitive: false);
      final txtDateMatch = txtDateRegex.firstMatch(text);
      if (txtDateMatch != null) {
        final d = txtDateMatch.group(1)!.padLeft(2, '0');
        final mStr = txtDateMatch.group(2)!.toLowerCase();
        final y = txtDateMatch.group(3)!;
        const months = {'jan':'01','feb':'02','mar':'03','apr':'04','may':'05','jun':'06','jul':'07','aug':'08','sep':'09','oct':'10','nov':'11','dec':'12'};
        final m = months[mStr] ?? '01';
        date = '$y-$m-$d';
      }
    }

    // Find Merchant: Skip generic headers
    final blacklist = ['TAX INVOICE', 'RECEIPT', 'CASH BILL', 'INVOICE', 'SIMPLIFIED TAX INVOICE', 'ORIGINAL', 'DUPLICATE', 'COPY'];
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    for (final line in lines) {
      bool isGeneric = false;
      for (final word in blacklist) {
        if (line.toUpperCase().contains(word)) {
          isGeneric = true;
          break;
        }
      }
      if (!isGeneric && line.length > 3) {
        merchant = line;
        break;
      }
    }

    return ReceiptData(
      date: date.isEmpty ? _todayDate() : date,
      amount: amount,
      merchant: merchant.isEmpty ? 'Unknown Merchant' : merchant,
      category: _guessCategory(text),
      imagePath: imagePath,
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
