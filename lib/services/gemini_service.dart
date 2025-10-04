import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEN_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  static const String _systemPrompt = '''
You are a Fire Safety AI Assistant specialized in providing guidance and suggestions related to fire safety, wildfire preparedness, and emergency response. 

Your role is to:
- Provide fire safety tips and recommendations
- Help with wildfire preparedness and evacuation planning
- Give guidance on breathing through smoke and air quality
- Suggest emergency supplies and evacuation routes
- Answer questions about fire prevention and safety measures
- Provide information about fire weather conditions and safety protocols

IMPORTANT: You must ONLY respond to questions and topics related to fire safety, wildfire preparedness, emergency response, and related safety measures. If asked about topics unrelated to fire safety, politely redirect the conversation back to fire safety topics.

Keep responses concise, helpful, and focused on practical fire safety advice.
''';

  static Future<String> generateResponse(String userMessage) async {
    try {
      // Check if the message is fire safety related
      if (!isFireSafetyRelated(userMessage)) {
        return "I'm specialized in fire safety and emergency preparedness. I can help you with questions about wildfires, evacuation planning, breathing through smoke, emergency supplies, and other fire safety topics. What fire safety question can I help you with?";
      }
      dev.log(dotenv.env['GEMINI_API_KEY'] ?? 'No API key found');

      // Prepare the request body
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': 'System: $_systemPrompt\n\nUser: $userMessage'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      // Make the HTTP request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': 'AIzaSyC1eX7WfMc2CtrwDeCjnuyrZMRLWvcqKiU',
        },
        body: jsonEncode(requestBody),
      );
      dev.log(response.body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final generatedText = responseData['candidates'][0]['content']['parts'][0]['text'];
          print('Successfully generated response with Gemini 2.5 Flash');
          return generatedText;
        } else {
          print('Unexpected response format: ${response.body}');
          return _getFallbackResponse();
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return _getFallbackResponse();
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      return _getFallbackResponse();
    }
  }

  static String _getFallbackResponse() {
    return 'I\'m currently experiencing technical difficulties with my AI service. For immediate fire safety guidance, please:\n\n• Call 911 for emergencies\n• Check local emergency services for evacuation orders\n• Use N95 masks for smoke protection\n• Stay indoors with windows closed during poor air quality\n\nI\'ll be back online soon to help with more detailed fire safety questions.';
  }

  static bool isFireSafetyRelated(String message) {
    final fireSafetyKeywords = [
      'fire', 'wildfire', 'smoke', 'evacuation', 'emergency', 'safety',
      'breathing', 'air quality', 'evacuate', 'preparedness', 'supplies',
      'route', 'weather', 'flame', 'burn', 'rescue', 'alarm', 'extinguisher',
      'shelter', 'mask', 'respirator', 'hazard', 'risk', 'danger', 'alert',
      'blaze', 'combustion', 'ignition', 'spark', 'heat', 'temperature',
      'oxygen', 'fuel', 'kindling', 'tinder', 'ash', 'ember', 'cinder'
    ];
    
    final lowerMessage = message.toLowerCase();
    return fireSafetyKeywords.any((keyword) => lowerMessage.contains(keyword));
  }
}