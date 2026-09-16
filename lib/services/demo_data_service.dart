import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/theme.dart';

class DemoDataService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();

  final List<String> _names = [
    'Arjun', 'Sanya', 'Vikram', 'Ananya', 'Rohan', 'Ishani', 'Rahul', 'Kavya', 
    'Zayn', 'Maya', 'Leo', 'Zara', 'Ethan', 'Chloe', 'Noah', 'Mia', 'Liam', 
    'Emma', 'Aiden', 'Sophia', 'James', 'Olivia', 'Benjamin', 'Isabella',
    'Lucas', 'Ava', 'Mason', 'Amelia', 'Logan', 'Harper', 'Alexander', 'Evelyn',
    'Jack', 'Abigail', 'Oliver', 'Emily', 'Daniel', 'Elizabeth', 'Matthew', 'Sofia',
    'Henry', 'Aria', 'Sebastian', 'Scarlett', 'Joseph', 'Victoria', 'Samuel', 'Luna'
  ];

  final List<String> _skills = [
    'Flutter', 'React Native', 'Node.js', 'Python', 'UI Design', 'Figma', 
    'Marketing', 'Public Speaking', 'Guitar', 'Cooking', 'Yoga', 'Machine Learning',
    'SQL', 'Dart', 'Go', 'AWS', 'Cybersecurity', 'Photography', 'Piano', 'Data Science',
    'Blockchain', 'Unity', 'Copywriting', 'SEO', 'Spanish', 'French', 'Public Relations'
  ];

  final List<String> _bios = [
    'Always looking to expand my horizons through skill swapping.',
    'I love building things and teaching others how to do it.',
    'Passionate about design and code. Let\'s build something together.',
    'I believe everyone has something unique to teach.',
    'Tech enthusiast by day, amateur chef by night.',
    'Looking for a long-term learning partner!',
    'Minimalist vibes. Quality over quantity.',
    'Code, Coffee, and Creativity.'
  ];

  Future<void> generateDemoUsers({int count = 20}) async {
    try {
      final List<Map<String, dynamic>> records = [];
      for (int i = 0; i < count; i++) {
        final id = 'demo_${DateTime.now().millisecondsSinceEpoch}_$i';
        final name = _names[_random.nextInt(_names.length)];
        final age = 18 + _random.nextInt(27);
        final avatar = AppColors.realPersonPhotos[_random.nextInt(AppColors.realPersonPhotos.length)];
        final teach = _getRandomSkills(2);
        final learn = _getRandomSkills(2);
        
        final user = UserModel(
          id: id,
          name: name,
          age: age,
          email: '${name.toLowerCase()}${_random.nextInt(100)}@demo.com',
          bio: _bios[_random.nextInt(_bios.length)],
          teachSkills: teach,
          learnSkills: learn,
          rating: 4.0 + (_random.nextDouble() * 1.0),
          profileImage: avatar,
          onboardingCompleted: true,
          preferences: {
            'experienceLevel': ['Beginner', 'Intermediate', 'Expert'][_random.nextInt(3)],
            'preferredMethod': ['Remote', 'In-Person', 'Hybrid'][_random.nextInt(3)],
            'isDemo': true,
          },
        );

        records.add({
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
          'age': user.age,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      await _supabase.from('users').upsert(records);
    } catch (e) {
      debugPrint('GENERATE_DEMO_USERS_ERROR: $e');
    }
  }

  List<String> _getRandomSkills(int count) {
    final List<String> result = [];
    final available = List<String>.from(_skills);
    for (int i = 0; i < count; i++) {
      final index = _random.nextInt(available.length);
      result.add(available.removeAt(index));
    }
    return result;
  }
}
