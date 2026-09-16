import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/matcher_service.dart';

// ── Service providers ─────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) => CloudinaryService());

// ── Auth state (stream-based, auto-persists via Supabase) ──
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final service = ref.read(authServiceProvider);
  return service.userStream;
});

// ── Actions notifier ─────────────────────────────────────
class AuthActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<String?> register(String name, String email, String password) async {
    final result = await ref
        .read(authServiceProvider)
        .register(name, email, password);
    return result['success'] ? null : result['message'] as String;
  }

  Future<String?> login(String email, String password) async {
    final result = await ref.read(authServiceProvider).login(email, password);
    return result['success'] ? null : result['message'] as String;
  }

  Future<String?> signInWithGoogle() async {
    final result = await ref.read(authServiceProvider).signInWithGoogle();
    return result['success'] ? null : result['message'] as String;
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onFailed,
  }) async {
    await ref.read(authServiceProvider).verifyPhoneNumber(
          phoneNumber: phoneNumber,
          onCodeSent: onCodeSent,
          onFailed: onFailed,
        );
  }

  Future<String?> signInWithOTP(String verificationId, String smsCode) async {
    final result = await ref
        .read(authServiceProvider)
        .signInWithOTP(verificationId, smsCode);
    return result['success'] ? null : result['message'] as String;
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).signOut();
  }

  Future<void> toggleSaveUser(String currentUserId, String targetUserId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    List<String> updatedSaved = List.from(user.savedUsers);
    if (updatedSaved.contains(targetUserId)) {
      updatedSaved.remove(targetUserId);
      await MatcherService().unsaveProfile(currentUserId, targetUserId);
    } else {
      updatedSaved.add(targetUserId);
      await MatcherService().saveProfile(currentUserId, targetUserId);
    }

    final service = ref.read(authServiceProvider);
    await service.updateProfileFields(currentUserId, {'savedUsers': updatedSaved});
  }
}

final authActionsProvider = NotifierProvider<AuthActionsNotifier, void>(
  AuthActionsNotifier.new,
);
