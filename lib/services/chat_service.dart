import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Local memory store used for local/demo chats
  static final Map<String, List<MessageModel>> localChatMemory = {};
  static final _localStreamController = StreamController<String>.broadcast();
  static Stream<String> get localStream => _localStreamController.stream.startWith('init');

  Stream<List<Map<String, dynamic>>> getConnections(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .map((records) {
          final connections = <Map<String, dynamic>>[];
          for (final data in records) {
            try {
              final users = List<String>.from(data['users'] ?? data['participants'] ?? []);
              if (users.contains(userId)) {
                final otherId = users.firstWhere(
                  (id) => id != userId,
                  orElse: () => '',
                );
                if (otherId.isNotEmpty) {
                  DateTime timestamp;
                  final timeRaw = data['last_message_time'] ?? data['created_at'];
                  if (timeRaw is String) {
                    timestamp = DateTime.tryParse(timeRaw) ?? DateTime.now();
                  } else {
                    timestamp = DateTime.now();
                  }

                  connections.add({
                    'matchId': data['id'],
                    'otherUserId': otherId,
                    'status': data['status'] ?? 'active',
                    'lastMessage': data['last_message'] ?? '',
                    'timestamp': timestamp,
                  });
                }
              }
            } catch (e) {
              debugPrint('Error parsing match connection: $e');
            }
          }
          connections.sort((a, b) =>
              (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
          return connections;
        });
  }

  Stream<List<MessageModel>> getMessages(String matchId) {
    if (matchId.startsWith('local_match_') || matchId.contains('demo_user_')) {
      return _localStreamController.stream
          .where((id) => id == matchId)
          .map((id) => localChatMemory[id] ?? [])
          .startWith(localChatMemory[matchId] ?? []);
    }
    
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('timestamp', ascending: false)
        .map((records) => records
            .map((rec) => MessageModel.fromJson(rec, rec['id'].toString()))
            .toList());
  }

  Future<void> sendMessage(String matchId, String senderId, String text) async {
    if (matchId.startsWith('local_match_') || matchId.contains('demo_user_')) {
      final msg = MessageModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
      );
      localChatMemory.putIfAbsent(matchId, () => []);
      localChatMemory[matchId]!.insert(0, msg);
      _localStreamController.add(matchId);
      return;
    }

    final nowIso = DateTime.now().toIso8601String();
    
    await _supabase.from('chat_messages').insert({
      'match_id': matchId,
      'sender_id': senderId,
      'text': text,
      'timestamp': nowIso,
      'type': 'MessageType.text',
    });

    await _supabase.from('matches').update({
      'last_message': text,
      'last_message_time': nowIso,
      'status': 'active',
    }).eq('id', matchId);
  }

  Future<void> logCall({
    required String matchId,
    required String senderId,
    required bool isVideo,
    required String duration,
  }) async {
    if (matchId.startsWith('local_match_')) return;
    
    final nowIso = DateTime.now().toIso8601String();
    await _supabase.from('chat_messages').insert({
      'match_id': matchId,
      'sender_id': senderId,
      'text': isVideo ? 'Video Call' : 'Audio Call',
      'timestamp': nowIso,
      'type': isVideo ? 'MessageType.videoCall' : 'MessageType.audioCall',
      'duration': duration,
    });
  }

  Future<void> deleteMatch(String matchId) async {
    if (matchId.startsWith('local_match_')) {
      localChatMemory.remove(matchId);
      return;
    }
    
    await _supabase.from('chat_messages').delete().eq('match_id', matchId);
    await _supabase.from('matches').delete().eq('id', matchId);
  }

  Future<void> removeConnection(
      String userId, String targetUserId, bool isRemoved) async {
    await _supabase.from('swipes').upsert({
      'user_id': userId,
      'target_user_id': targetUserId,
      'is_removed': isRemoved,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static void notifyLocalMatchUpdate(String matchId) {
    _localStreamController.add(matchId);
  }
}
