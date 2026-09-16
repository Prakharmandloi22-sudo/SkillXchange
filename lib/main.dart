import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/supabase_config.dart';
import 'view/home_screen.dart';
import 'view/onboarding_screen.dart';
import 'view/login_screen.dart';
import 'viewmodel/auth_viewmodel.dart';
import 'core/theme.dart';
import 'services/notification_service.dart';
import 'widgets/animated_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    await NotificationService().init();
  } catch (e) {
    debugPrint('BOOTSTRAP_ERROR: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillXchange',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

// Authentication entry point with persistence support
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        if (!user.onboardingCompleted) return const OnboardingScreen();
        return HomeScreen(currentUser: user);
      },
      loading: () => authAsync.hasValue ? (authAsync.value == null ? const LoginScreen() : HomeScreen(currentUser: authAsync.value!)) : const _SplashScreen(),
      error: (e, st) {
        debugPrint('AUTH_ERROR: $e');
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            decoration: const BoxDecoration(gradient: AppColors.cosmicGradient),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_update_warning_rounded, color: AppColors.accent, size: 80),
                const SizedBox(height: 32),
                const Text('CONNECTION RECOVERY', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('We encountered a temporary issue with your session security: $e', 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => ref.read(authActionsProvider.notifier).logout(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('SIGN OUT & RESET', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('RETRY CONNECTION', style: TextStyle(color: Colors.white38)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shown while Supabase checks the persisted auth session.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.cosmicGradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Logo Container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(40),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: AppColors.solarGold.withAlpha(20),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: const AnimatedGradientLogo(
                  text: '',
                  fontSize: 0,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2.seconds, color: AppColors.accent.withAlpha(100))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), curve: Curves.easeInOutSine),
              
              const SizedBox(height: 48),
              // Animated title
              Text(
                'SkillXchange',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 12),
              Text(
                'THE FUTURE OF SKILL SHARING',
                style: GoogleFonts.outfit(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              
              const SizedBox(height: 60),
              // Modern loader
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                  backgroundColor: AppColors.accent.withAlpha(30),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
