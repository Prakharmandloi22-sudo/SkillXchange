import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/backend_config.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Auth state stream (Reactive to Supabase session & user updates) ──
  Stream<UserModel?> get userStream {
    final currentSession = _supabase.auth.currentSession;
    return _supabase.auth.onAuthStateChange
        .startWith(AuthState(AuthChangeEvent.initialSession, currentSession))
        .switchMap((data) {
      final session = data.session ?? _supabase.auth.currentSession;
      final user = session?.user ?? _supabase.auth.currentUser;
      if (user == null) return Stream.value(null);

      final subject = BehaviorSubject<UserModel?>();
      _loadLocalUserAndSupabase(user, subject);
      return subject.stream.doOnCancel(() => subject.close());
    });
  }

  void _loadLocalUserAndSupabase(User supabaseUser, BehaviorSubject<UserModel?> subject) async {
    final prefs = await SharedPreferences.getInstance();
    final localOnboard = prefs.getBool('onboarded_${supabaseUser.id}') ?? false;
    
    // 1. Immediate Fallback for responsive UI
    final fallback = _fallbackUser(supabaseUser).copyWith(onboardingCompleted: localOnboard);
    subject.add(fallback);

    // 2. Query Supabase users table and subscribe to updates
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', supabaseUser.id)
          .maybeSingle();

      if (response != null) {
        final userModel = UserModel.fromJson({...response, 'id': supabaseUser.id});
        if (userModel.onboardingCompleted) {
          prefs.setBool('onboarded_${supabaseUser.id}', true);
        }
        subject.add(userModel);
      }
    } catch (e) {
      debugPrint('SUPABASE_USER_LOAD_ERROR: $e');
      final backup = await fetchUserFromBackend(uid: supabaseUser.id);
      if (backup != null) {
        if (backup.onboardingCompleted) {
          prefs.setBool('onboarded_${supabaseUser.id}', true);
        }
        subject.add(backup);
      }
    }
  }

  Future<UserModel?> fetchUserFromBackend({String? email, String? uid}) async {
    try {
      final queryParams = email != null ? 'email=$email' : 'uid=$uid';
      final response = await http.get(
        Uri.parse('${BackendConfig.baseUrl}/auth/profile?$queryParams'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson({...data, 'id': uid ?? data['_id'] ?? ''});
      }
    } catch (e) {
      debugPrint('EMERGENCY_BACKEND_FETCH_FAILED: $e');
    }
    return null;
  }

  UserModel _fallbackUser(User supabaseUser) {
    final name = (supabaseUser.userMetadata?['full_name'] as String?) ??
        (supabaseUser.userMetadata?['name'] as String?) ??
        supabaseUser.email?.split('@').first ??
        'New User';
    return UserModel(
      id: supabaseUser.id,
      name: name,
      email: supabaseUser.email ?? '',
      bio: 'Expert swapper',
      teachSkills: [],
      learnSkills: [],
      rating: 4.8,
      profileImage: 'https://api.dicebear.com/7.x/initials/png?seed=${Uri.encodeComponent(name)}&backgroundColor=131313&textColor=E3B873',
      onboardingCompleted: false,
    );
  }

  // ── Email / Password Register ─────────────────────────
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim()},
      );

      final user = response.user;
      if (user == null) {
        return {'success': false, 'message': 'Registration failed. Try again.'};
      }

      final userModel = UserModel(
        id: user.id,
        name: name.trim(),
        email: email.trim(),
        bio: '',
        teachSkills: [],
        learnSkills: [],
        rating: 0.0,
        profileImage: '',
        provider: 'email',
        onboardingCompleted: false,
      );

      await _saveUserToSupabase(userModel);
      return {'success': true, 'user': userModel};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong. Try again.'};
    }
  }

  // ── Email / Password Login ────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return {'success': false, 'message': 'Login failed.'};
      }

      final userModel = await _fetchOrCreateUserModel(user);
      return {'success': true, 'user': userModel};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong. Try again.'};
    }
  }

  // ── Google Sign-In ────────────────────────────────────
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'message': 'Cancelled.'};

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return {'success': false, 'message': 'No ID token found.'};
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user == null) {
        return {'success': false, 'message': 'Google Sign-In failed.'};
      }

      final userModel = await _fetchOrCreateUserModel(user);
      return {'success': true, 'user': userModel};
    } catch (e) {
      return {'success': false, 'message': 'Google sign-in failed.'};
    }
  }

  // ── Phone (OTP) Authentication ────────────────────────
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onFailed,
  }) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
      onCodeSent(phoneNumber);
    } catch (e) {
      onFailed(e.toString());
    }
  }

  Future<Map<String, dynamic>> signInWithOTP(String phoneNumber, String smsCode) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: smsCode,
        type: OtpType.sms,
      );
      final user = response.user;
      if (user == null) return {'success': false, 'message': 'OTP verification failed.'};
      final userModel = await _fetchOrCreateUserModel(user);
      return {'success': true, 'user': userModel};
    } catch (e) {
      return {'success': false, 'message': 'OTP verification failed.'};
    }
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  // ── Onboarding ────────────────────────────────────────
  Future<void> completeOnboarding({
    required String uid,
    required String bio,
    required List<String> teachSkills,
    required List<String> learnSkills,
    required Map<String, dynamic> preferences,
    String? name,
    String? profileImage,
  }) async {
    final Map<String, dynamic> data = {
      'id': uid,
      'bio': bio,
      'teach_skills': teachSkills,
      'learn_skills': learnSkills,
      'preferences': preferences,
      'profile_image': profileImage ?? '',
      'onboarding_completed': true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) {
      data['name'] = name;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded_$uid', true);

    try {
      await _supabase.from('users').upsert(data);
    } catch (e) {
      debugPrint('SUPABASE_WRITE_ERROR: $e. Relying on Backend Sync.');
    }

    final email = _supabase.auth.currentUser?.email;
    await _syncFullProfileToBackend(email ?? 'no_email_$uid', {
      'uid': uid,
      'name': name ?? _supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'User',
      'bio': bio,
      'teachSkills': teachSkills,
      'learnSkills': learnSkills,
      'profileImage': profileImage ?? '',
      'onboardingCompleted': true,
    });
  }

  Future<void> _syncFullProfileToBackend(String email, Map<String, dynamic> profileData) async {
    try {
      final url = '${BackendConfig.baseUrl}/auth/profile';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          ...profileData,
        }),
      ).timeout(const Duration(seconds: 5));

      debugPrint('BACKEND_SYNC_COMPLETE: status=${response.statusCode}');
    } catch (e) {
      debugPrint('BACKEND_SYNC_FAILURE: $e');
    }
  }

  Future<void> updateProfileFields(String uid, Map<String, dynamic> fields) async {
    try {
      final Map<String, dynamic> supabaseData = {};
      fields.forEach((key, value) {
        if (key == 'teachSkills') {
          supabaseData['teach_skills'] = value;
        } else if (key == 'learnSkills') {
          supabaseData['learn_skills'] = value;
        } else if (key == 'profileImage') {
          supabaseData['profile_image'] = value;
        } else if (key == 'onboardingCompleted') {
          supabaseData['onboarding_completed'] = value;
        } else if (key == 'fcmToken') {
          supabaseData['fcm_token'] = value;
        } else if (key == 'savedUsers') {
          supabaseData['saved_users'] = value;
        } else if (key != 'updatedAt') {
          supabaseData[key] = value;
        }
      });
      supabaseData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('users').update(supabaseData).eq('id', uid);
    } catch (e) {
      debugPrint('SUPABASE_FIELD_UPDATE_ERROR: $e');
    }
  }

  Future<UserModel> _fetchOrCreateUserModel(User supabaseUser) async {
    try {
      final doc = await _supabase.from('users').select().eq('id', supabaseUser.id).maybeSingle();
      if (doc != null) {
        return UserModel.fromJson({...doc, 'id': supabaseUser.id});
      }
    } catch (e) {
      debugPrint('FETCH_USER_ERROR: $e');
    }

    final newUser = _fallbackUser(supabaseUser);
    try {
      await _saveUserToSupabase(newUser);
    } catch (_) {
      final email = supabaseUser.email;
      if (email != null) {
        await _syncFullProfileToBackend(email, {
          ...newUser.toJson(),
          'uid': supabaseUser.id,
        });
      }
    }
    return newUser;
  }

  Future<void> _saveUserToSupabase(UserModel user) async {
    await _supabase.from('users').upsert({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'bio': user.bio,
      'teach_skills': user.teachSkills,
      'learn_skills': user.learnSkills,
      'rating': user.rating,
      'profile_image': user.profileImage,
      'provider': user.provider,
      'onboarding_completed': user.onboardingCompleted,
      'preferences': user.preferences,
      'age': user.age,
      'video_url': user.videoUrl,
      'saved_users': user.savedUsers,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
