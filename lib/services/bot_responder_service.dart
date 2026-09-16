import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class BotResponderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  void triggerAIResponse(String matchId, UserModel bot, String userText) {
    _generateAIResponse(matchId, bot, userText);
  }

  Future<void> _generateAIResponse(String matchId, UserModel bot, String userText) async {
    final isDemoBot = bot.id.startsWith('demo_user_') || 
                      bot.preferences['isDemo'] == true || 
                      matchId.startsWith('local_match_');

    if (isDemoBot) {
      final greeting = "Hi! I'm ${bot.name}. I'd love to help you with ${bot.teachSkills.join(", ")}! What would you like to know first?";
      await Future.delayed(const Duration(milliseconds: 600));
      await _saveResponse(matchId, bot.id, greeting);
      return;
    }

    try {
      final historyRecords = await _supabase
          .from('chat_messages')
          .select()
          .eq('match_id', matchId)
          .order('timestamp', ascending: false)
          .limit(5);

      final messages = (historyRecords as List).reversed
          .map((rec) {
        return {
          'role': rec['sender_id'] == bot.id ? 'assistant' : 'user',
          'content': rec['text'] ?? '',
        };
      }).toList();

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.openRouterKey}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://skillxchange.com',
          'X-Title': 'SkillXchange',
        },
        body: jsonEncode({
          'model': 'openai/gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are ${bot.name}, an expert in ${bot.teachSkills}. You are helping someone learn your skill in exchange for ${bot.learnSkills}. Keep replies helpful and professional.'},
            ...messages,
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'];
        await _saveResponse(matchId, bot.id, aiText);
      }
    } catch (e) {
      debugPrint('AI_BOT_ERROR: $e');
    }
  }

  Future<void> _saveResponse(String matchId, String botId, String text) async {
    final isLocal = matchId.startsWith('local_match_');
    
    if (isLocal) {
      final msg = MessageModel(
        id: 'bot_reply_${DateTime.now().millisecondsSinceEpoch}',
        senderId: botId,
        text: text,
        timestamp: DateTime.now(),
      );
      
      ChatService.localChatMemory.putIfAbsent(matchId, () => []);
      ChatService.localChatMemory[matchId]!.insert(0, msg);
      ChatService.notifyLocalMatchUpdate(matchId);
      return;
    }

    final nowIso = DateTime.now().toIso8601String();
    await _supabase.from('chat_messages').insert({
      'match_id': matchId,
      'sender_id': botId,
      'text': text,
      'timestamp': nowIso,
      'type': 'MessageType.text',
    });

    await _supabase.from('matches').update({
      'last_message': text,
      'last_message_time': nowIso,
    }).eq('id', matchId);
  }
}
