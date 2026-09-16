import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/matcher_service.dart';
import 'auth_viewmodel.dart';

class DiscoveryPost {
  final String id;
  final UserModel user;
  final String url;
  final String type;
  final String bio;
  final DateTime createdAt;

  DiscoveryPost({
    required this.id,
    required this.user,
    required this.url,
    required this.type,
    required this.bio,
    required this.createdAt,
  });
}

final matcherServiceProvider = Provider<MatcherService>(
  (ref) => MatcherService(),
);

final discoveryPostsProvider = StreamProvider<List<DiscoveryPost>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(matcherServiceProvider).getDiscoveryPostsStream(user);
});

final savedUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(matcherServiceProvider).getSavedUsersStream(user.id, user.savedUsers);
});

final matcherMatchesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(matcherServiceProvider).getMatchesStream(user.id);
});
