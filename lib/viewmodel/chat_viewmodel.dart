import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import 'auth_viewmodel.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final matchesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(chatServiceProvider).getConnections(user.id);
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  matchId,
) {
  return ref.read(chatServiceProvider).getMessages(matchId);
});
