import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiService {
  final GenerativeModel _model;

  GeminiService() : _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
  );

  Future<Map<String, dynamic>> triageIncident(String type, String description) async {
    try {
      final prompt = 'Triage this incident. Type: $type, Desc: $description. '
          '1. Detect the language. If it is NOT English, translate the summary to English. '
          '2. Return JSON with "severity" (1-5), "suggestedTeam", and "summary" (translated to English).';
      final response = await _model.generateContent([Content.text(prompt)]);
      
      String text = response.text ?? '{}';
      // Clean up markdown code blocks if any
      text = text.replaceAll('```json', '').replaceAll('```', '');
      return jsonDecode(text);
    } catch (e) {
      return {
        'severity': 3, 
        'suggestedTeam': type == 'fire' ? 'fire_safety' : 'security', 
        'summary': description.length > 50 ? description.substring(0, 50) + '...' : description
      };
    }
  }

  Future<String> generateResponderBriefNarrative(Map<String, dynamic> data) async {
    try {
      final prompt = 'Write a responder brief narrative under 80 words for: $data';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? _fallbackNarrative(data);
    } catch (e) {
      return _fallbackNarrative(data);
    }
  }

  Future<String> generatePostIncidentReport(Map<String, dynamic> data) async {
    try {
      final prompt = 'Write a professional post-incident report under 300 words for: $data';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? _fallbackReport(data);
    } catch (e) {
      return _fallbackReport(data);
    }
  }

  String _fallbackNarrative(Map<String, dynamic> data) {
    return "URGENT: ${data['type']} reported in Room ${data['roomNumber']}. Severity ${data['severity']}/5. Guest description: ${data['description']}";
  }

  String _fallbackReport(Map<String, dynamic> data) {
    return """
POST-INCIDENT SUMMARY
Incident ID: ${data['id'] ?? 'N/A'}
Type: ${data['type']}
Room: ${data['roomNumber']}
Status: Resolved

SUMMARY:
A ${data['type']} emergency was reported. The response team was dispatched and the situation was brought under control. The incident has been marked as resolved.
""";
  }

  Future<String> generateChatReply(String userMessage, {String incidentType = 'other'}) async {
    try {
      final prompt = 'You are a calm, professional emergency responder coordinator. '
          'The guest has reported a "$incidentType" emergency. '
          'They already described the situation — DO NOT ask them to describe it again. '
          'They just sent: "$userMessage". '
          'Write a short (max 20 words), reassuring reply with clear instructions. '
          'Never ask "what happened" or "describe your situation".';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Copy that. We are monitoring the situation.';
    } catch (e) {
      // Context-aware fallback when API is unavailable
      final msg = userMessage.toLowerCase();
      if (msg.contains('help') || msg.contains('hurt') || msg.contains('pain')) {
        return 'Help is on the way. Stay still and stay calm.';
      } else if (msg.contains('smoke') || msg.contains('fire')) {
        return 'Move away from smoke. Stay low and do not use the elevator.';
      } else if (msg.contains('where') || msg.contains('room')) {
        return 'Your location is confirmed. Team is navigating to you now.';
      } else if (msg.contains('safe') || msg.contains('okay') || msg.contains('ok')) {
        return 'Good. Stay in place. Team will be with you shortly.';
      } else {
        return 'The response team is navigating to your floor now. Please stay in your room.';
      }
    }
  }
}
