import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SeedService {
  final SupabaseClient _supabase = Supabase.instance.client;

  final List<Map<String, dynamic>> _demoUsers = [
    {
      'name': 'Alex Rivera',
      'email': 'alex@skillx.com',
      'bio': 'Full-stack developer. I love exploring new frameworks and teaching clean code architecture.',
      'teachSkills': ['Flutter', 'Node.js', 'Go'],
      'learnSkills': ['UI Design', '3D Modeling'],
      'profileImage': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=640&auto=format&fit=crop',
      'rating': 4.8,
    },
    {
      'name': 'Sarah Jenkins',
      'email': 'sarah@skillx.com',
      'bio': 'Digital artist and illustrator. Can teach you Procreate and color theory!',
      'teachSkills': ['Digital Art', 'Procreate', 'Illustration'],
      'learnSkills': ['Python', 'Automation'],
      'profileImage': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=640&auto=format&fit=crop',
      'rating': 4.9,
    },
    {
      'name': 'Marcus Thorne',
      'email': 'marcus@skillx.com',
      'bio': 'Marketing expert with 5+ years experience. Let\'s grow your brand together.',
      'teachSkills': ['Marketing', 'SEO', 'Ads'],
      'learnSkills': ['React', 'Next.js'],
      'profileImage': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=640&auto=format&fit=crop',
      'rating': 4.5,
    },
    {
      'name': 'Isabella Moon',
      'email': 'isabella@skillx.com',
      'bio': 'Yoga instructor and wellness coach. Looking to learn photography for my social media.',
      'teachSkills': ['Yoga', 'Meditation', 'Wellness'],
      'learnSkills': ['Photography', 'Editing'],
      'profileImage': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?q=80&w=640&auto=format&fit=crop',
      'rating': 4.7,
    },
    {
      'name': 'Daniel Park',
      'email': 'daniel@skillx.com',
      'bio': 'Data Scientist. Expert in Python and SQL. Want to learn guitar or piano.',
      'teachSkills': ['Data Science', 'Python', 'SQL'],
      'learnSkills': ['Guitar', 'Piano'],
      'profileImage': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=640&auto=format&fit=crop',
      'rating': 4.6,
    },
  ];

  Future<void> seedDemoData(String currentUserId) async {
    try {
      for (var userData in _demoUsers) {
        final existing = await _supabase
            .from('users')
            .select()
            .eq('email', userData['email'])
            .maybeSingle();

        String demoId;
        if (existing == null) {
          demoId = 'demo_user_${userData['name'].toString().toLowerCase().replaceAll(' ', '_')}';
          final user = UserModel(
            id: demoId,
            name: userData['name'],
            email: userData['email'],
            bio: userData['bio'],
            teachSkills: List<String>.from(userData['teachSkills']),
            learnSkills: List<String>.from(userData['learnSkills']),
            rating: userData['rating'],
            profileImage: userData['profileImage'],
            onboardingCompleted: true,
            preferences: const {'isDemo': true},
          );
          await _supabase.from('users').upsert({
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'bio': user.bio,
            'teach_skills': user.teachSkills,
            'learn_skills': user.learnSkills,
            'rating': user.rating,
            'profile_image': user.profileImage,
            'onboarding_completed': true,
            'preferences': user.preferences,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else {
          demoId = existing['id'].toString();
        }

        await _supabase.from('swipes').upsert({
          'user_id': demoId,
          'target_user_id': currentUserId,
          'action': 'like',
          'is_removed': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('SEED_DEMO_DATA_ERROR: $e');
    }
  }
}
