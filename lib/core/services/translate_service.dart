import 'package:google_generative_ai/google_generative_ai.dart';

class TranslateService {
  final GenerativeModel _model;

  TranslateService() : _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
  );

  Future<String> translateToEnglish(String text) async {
    try {
      // If it looks like English, don't waste an API call
      if (RegExp(r'^[a-zA-Z0-9\s\.,!?]+$').hasMatch(text)) return text;

      final prompt = 'Translate the following text to English. Return ONLY the translated text, no extra commentary: "$text"';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? text;
    } catch (e) {
      return text; // Fallback to original
    }
  }
}
