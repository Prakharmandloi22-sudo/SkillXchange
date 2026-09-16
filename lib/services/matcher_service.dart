import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../viewmodel/matcher_viewmodel.dart';
import 'chat_service.dart';

class MatcherService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static String getMatchId(String id1, String id2) {
    return id1.hashCode <= id2.hashCode 
        ? '${id1}_$id2' 
        : '${id2}_$id1';
  }

  Stream<List<DiscoveryPost>> getDiscoveryPostsStream(UserModel currentUser) {
    return _supabase
        .from('discovery_posts')
        .stream(primaryKey: ['id'])
        .order('server_timestamp', ascending: false)
        .handleError((e) => debugPrint('MATCHER_STREAM_ERROR: $e'))
        .map((records) {
          final List<DiscoveryPost> posts = [];
          for (final data in records) {
            try {
              final uid = data['user_id'] ?? data['id'];
              if (uid == currentUser.id) continue;

              DateTime createdAt;
              final rawTime = data['server_timestamp'] ?? data['created_at'];
              if (rawTime is String) {
                createdAt = DateTime.tryParse(rawTime) ?? DateTime.now();
              } else {
                createdAt = DateTime.now();
              }

              posts.add(DiscoveryPost(
                id: data['id'].toString(),
                user: UserModel(
                  id: uid.toString(),
                  name: data['user_name'] ?? 'Expert',
                  email: '',
                  bio: data['bio'] ?? '',
                  teachSkills: List<String>.from(data['user_skills'] ?? []),
                  learnSkills: const [],
                  rating: (data['rating'] ?? 4.8).toDouble(),
                  profileImage: data['user_image'] ?? '',
                  videoUrl: data['type'] == 'video' ? (data['url'] ?? '') : '',
                  onboardingCompleted: true,
                ),
                url: data['url'] ?? '',
                type: data['type'] ?? 'image',
                bio: data['bio'] ?? '',
                createdAt: createdAt,
              ));
            } catch (e) {
              debugPrint('MATCHER_MAP_ERROR: $e');
            }
          }

          if (posts.length < 5) {
            final virtuals = generateVirtualUsers(5);
            for (int i = 0; i < virtuals.length; i++) {
              final v = virtuals[i];
              posts.add(DiscoveryPost(
                id: '${v.id}_photo',
                user: v,
                url: v.profileImage,
                type: 'image',
                bio: 'Master of ${v.teachSkills.join(" & ")}. ${v.bio}',
                createdAt: DateTime.now().subtract(Duration(minutes: i * 5)),
              ));
              posts.add(DiscoveryPost(
                id: '${v.id}_primary',
                user: v,
                url: v.videoUrl,
                type: 'video',
                bio: 'Live expertise in ${v.teachSkills.first}. Connect to start swapping!',
                createdAt: DateTime.now().subtract(Duration(minutes: i * 5 + 1)),
              ));
            }
          }

          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }

  Future<String> createChatRequest(String senderId, String recipientId) async {
    final matchId = getMatchId(senderId, recipientId);
    
    if (recipientId.startsWith('demo_user_') || senderId.startsWith('demo_user_')) {
      if (!ChatService.localChatMemory.containsKey(matchId)) {
        ChatService.localChatMemory[matchId] = [];
        ChatService.notifyLocalMatchUpdate(matchId);
      }
      return matchId;
    }

    try {
      final existing = await _supabase.from('matches').select().eq('id', matchId).maybeSingle();
      if (existing == null) {
        final nowIso = DateTime.now().toIso8601String();
        await _supabase.from('matches').insert({
          'id': matchId,
          'participants': [senderId, recipientId],
          'users': [senderId, recipientId],
          'last_message': 'Conversation started',
          'last_message_time': nowIso,
          'status': 'active',
          'created_at': nowIso,
        });
      }
    } catch (e) {
      debugPrint('CREATE_CHAT_REQUEST_ERROR: $e');
    }
    
    return matchId;
  }

  Stream<List<Map<String, dynamic>>> getMatchesStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return Rx.combineLatest2(
      _supabase.from('matches').stream(primaryKey: ['id']).handleError((e) {
        debugPrint('MATCHES_SUPABASE_ERROR: $e');
        return const Stream.empty();
      }),
      ChatService.localStream.startWith('initial'),
      (records, _) => records,
    ).asyncMap((records) async {
      final List<Map<String, dynamic>> matches = [];
      
      for (final data in records) {
        try {
          final mId = data['id'].toString();
          final allParticipants = List<String>.from(data['users'] ?? data['participants'] ?? []);
          if (!allParticipants.contains(userId)) continue;
          
          final otherId = allParticipants.firstWhere((id) => id != userId, orElse: () => '');
          if (otherId.isNotEmpty) {
            UserModel? other;
            if (otherId.startsWith('demo_user_')) {
              other = getVirtualUserById(otherId);
            } else {
              final otherDoc = await _supabase.from('users').select().eq('id', otherId).maybeSingle();
              if (otherDoc != null) {
                other = UserModel.fromJson({...otherDoc, 'id': otherId});
              }
            }

            if (other != null) {
              DateTime lastMsgTime;
              final rawTime = data['last_message_time'] ?? data['created_at'];
              if (rawTime is String) {
                lastMsgTime = DateTime.tryParse(rawTime) ?? DateTime.now();
              } else {
                lastMsgTime = DateTime.now();
              }

              matches.add({
                'id': mId,
                'otherUser': other,
                'otherUserId': otherId,
                'lastMessage': data['last_message'] ?? 'Conversation started',
                'lastMessageTime': lastMsgTime,
                'isDemo': otherId.startsWith('demo_user_'),
              });
            }
          }
        } catch (e) {
          debugPrint('MATCH_ITERATION_ERROR ($userId): $e');
        }
      }
      
      // Process Local Memory Matches
      try {
        final localKeys = ChatService.localChatMemory.keys.toList();
        for (final lId in localKeys) {
          if (lId.contains(userId)) {
            if (matches.any((m) => m['id'] == lId)) continue;
            
            final parts = lId.split('_');
            final otherId = parts.last == userId ? parts[parts.length - 2] : parts.last;
            
            UserModel? other;
            if (otherId.startsWith('demo_user_')) {
              other = getVirtualUserById(otherId);
            } else {
              final uDoc = await _supabase.from('users').select().eq('id', otherId).maybeSingle();
              if (uDoc != null) {
                other = UserModel.fromJson({...uDoc, 'id': otherId});
              }
            }
            
            if (other != null) {
              final localMsgs = ChatService.localChatMemory[lId] ?? [];
              matches.add({
                'id': lId,
                'otherUser': other,
                'lastMessage': localMsgs.isNotEmpty ? localMsgs.first.text : 'New message request',
                'lastMessageTime': localMsgs.isNotEmpty 
                    ? localMsgs.first.timestamp 
                    : DateTime.now(),
                'isDemo': otherId.startsWith('demo_user_'),
              });
            }
          }
        }
      } catch (e) {
        debugPrint('LOCAL_MATCH_ERROR: $e');
      }

      // Inject Suggested/Welcome for New Users
      if (matches.length < 5) {
        if (!matches.any((m) => m['id'] == 'local_match_welcome')) {
          matches.add({
            'id': 'local_match_welcome',
            'otherUser': UserModel(
              id: 'sx_team_0',
              name: 'SkillXchange Team',
              email: 'support@skillxchange.com',
              bio: 'Official onboarding & support',
              teachSkills: const ['App Navigation', 'Best Practices'],
              learnSkills: const [],
              rating: 5.0,
              profileImage: 'https://images.pexels.com/photos/3183183/pexels-photo-3183183.jpeg',
              onboardingCompleted: true,
            ),
            'lastMessage': 'Welcome to the community! Ready to swap your first skill?',
            'lastMessageTime': DateTime.now(),
            'isDemo': true,
            'isSuggested': false,
          });
        }

        final demoIds = [
          'demo_user_welcome',
          'demo_user_sarah',
          'demo_user_alex',
          'demo_user_priya'
        ];
        
        for (final dId in demoIds) {
          final mId = getMatchId(userId, dId);
          if (!matches.any((m) => m['otherUserId'] == dId || m['id'] == mId)) {
            final other = getVirtualUserById(dId);
            matches.add({
              'id': mId,
              'otherUser': other,
              'otherUserId': dId,
              'status': 'active',
              'lastMessage': 'Ready to start swapping?',
              'lastMessageTime': DateTime.now().subtract(const Duration(hours: 1)),
              'isDemo': true,
            });
          }
        }
      }
      
      matches.sort((a, b) => (b['lastMessageTime'] as DateTime).compareTo(a['lastMessageTime'] as DateTime));
      return matches;
    });
  }

  Stream<List<UserModel>> getSavedUsersStream(String userId, List<String> savedIds) {
    if (savedIds.isEmpty) {
      return _supabase
          .from('saved_users')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .asyncMap((records) async {
            final List<UserModel> users = [];
            for (var rec in records) {
              final targetId = rec['saved_user_id']?.toString();
              if (targetId != null) {
                final userDoc = await _supabase.from('users').select().eq('id', targetId).maybeSingle();
                if (userDoc != null) {
                  users.add(UserModel.fromJson({...userDoc, 'id': targetId}));
                }
              }
            }
            return users;
          });
    }
    
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .map((records) => records
            .where((rec) => savedIds.contains(rec['id'].toString()))
            .map((doc) => UserModel.fromJson({...doc, 'id': doc['id'].toString()}))
            .toList());
  }

  Future<void> saveProfile(String userId, String targetId) async {
    await _supabase.from('saved_users').insert({
      'user_id': userId,
      'saved_user_id': targetId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unsaveProfile(String userId, String targetId) async {
    await _supabase
        .from('saved_users')
        .delete()
        .eq('user_id', userId)
        .eq('saved_user_id', targetId);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final records = await _supabase
          .from('users')
          .select()
          .eq('onboarding_completed', true)
          .limit(20);
      final results = (records as List)
          .map((doc) => UserModel.fromJson({...doc, 'id': doc['id'].toString()}))
          .where((u) =>
              u.name.toLowerCase().contains(query.toLowerCase()) ||
              u.teachSkills.any((s) => s.toLowerCase().contains(query.toLowerCase())))
          .toList();
      results.addAll(generateVirtualUsers(20).where((u) =>
          u.name.toLowerCase().contains(query.toLowerCase()) ||
          u.teachSkills.any((s) => s.toLowerCase().contains(query.toLowerCase()))));
      return results;
    } catch (e) {
      debugPrint('SEARCH_USERS_ERROR: $e');
      return generateVirtualUsers(20).where((u) =>
          u.name.toLowerCase().contains(query.toLowerCase()) ||
          u.teachSkills.any((s) => s.toLowerCase().contains(query.toLowerCase()))).toList();
    }
  }

  static List<UserModel> _virtualCache = [];

  static List<UserModel> generateVirtualUsers(int count) {
    if (_virtualCache.length >= count) return _virtualCache.sublist(0, count);

    const names = [
      'Arjun Mehra', 'Sanya Iyer', 'Vikram Singh', 'Ananya Roy', 'Rohan Das',
      'Ishani Verma', 'Zayn Malik', 'Maya Sharma', 'Leo Das', 'Zara Khan',
    ];
    const videos = [
      'https://assets.mixkit.co/videos/preview/mixkit-software-developer-working-on-his-laptop-34448-large.mp4',
      'https://assets.mixkit.co/videos/preview/mixkit-man-working-on-his-laptop-in-a-coffee-shop-32684-large.mp4',
      'https://assets.mixkit.co/videos/preview/mixkit-hands-of-a-man-playing-the-guitar-close-up-4421-large.mp4',
      'https://assets.mixkit.co/videos/preview/mixkit-woman-practicing-yoga-in-a-studio-40348-large.mp4',
      'https://assets.mixkit.co/videos/preview/mixkit-chef-preparing-a-meal-in-a-professional-kitchen-34531-large.mp4',
    ];
    const images = [
      'https://images.pexels.com/photos/3183150/pexels-photo-3183150.jpeg',
      'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg',
      'https://images.pexels.com/photos/4348401/pexels-photo-4348401.jpeg',
      'https://images.pexels.com/photos/4050291/pexels-photo-4050291.jpeg',
      'https://images.pexels.com/photos/3823488/pexels-photo-3823488.jpeg',
    ];
    const skillSets = [
      ['Flutter', 'Supabase', 'Clean Architecture'],
      ['UI Design', 'Figma', 'Prototyping'],
      ['Python', 'Machine Learning', 'Data Science'],
      ['Guitar', 'Music Theory', 'Songwriting'],
      ['Cooking', 'Italian Cuisine', 'Baking'],
      ['Yoga', 'Meditation', 'Wellness'],
      ['Digital Marketing', 'SEO', 'Content Strategy'],
      ['Photography', 'Lightroom', 'Cinematography'],
      ['Public Speaking', 'Confidence', 'Leadership'],
      ['Crypto', 'Blockchain', 'Solidity'],
    ];
    const bios = [
      'Building the future of mobile apps. Let\'s swap code for design!',
      'Design enthusiast. I can teach you Figma if you teach me Guitar.',
      'Data scientist by day, amateur chef by night. Swap Python for Cooking?',
      'Music is my life. Want to learn chords? I want to learn Marketing.',
      'Healthy mind, healthy body. Teach me SQL and I\'ll teach you Yoga.',
      'Capturing moments through my lens. Teach me SEO and I\'ll teach you Photo.',
      'Growth hacker. Swap Marketing strategies for Flutter development.',
      'Public speaking is a superpower. Swap leadership tips for Web Dev.',
      'Blockchain developer. Curious about everything tech. Let\'s talk!',
      'Culinary arts expert. Swap a secret recipe for some UI tips.',
    ];

    final virtuals = List.generate(count, (i) {
      final id = 'demo_user_$i';
      final si = i % skillSets.length;
      return UserModel(
        id: id,
        name: names[i % names.length],
        email: 'user_$id@example.com',
        bio: bios[si],
        teachSkills: skillSets[si],
        learnSkills: skillSets[(si + 1) % skillSets.length],
        rating: 4.5 + (i % 5) * 0.1,
        profileImage:
            'https://randomuser.me/api/portraits/${i % 2 == 0 ? "men" : "women"}/${(i % 50) + 1}.jpg',
        videoUrl: videos[i % videos.length],
        onboardingCompleted: true,
        posts: [
          {
            'id': '${id}_post_1',
            'url': images[i % images.length],
            'type': 'image',
            'bio': 'Project highlight: ${skillSets[si][0]} project complete!',
            'createdAt': DateTime.now().subtract(Duration(days: i + 1)).toIso8601String(),
          },
          {
            'id': '${id}_post_2',
            'url': videos[(i + 1) % videos.length],
            'type': 'video',
            'bio': 'Learning ${skillSets[si][1]} in action.',
            'createdAt': DateTime.now().subtract(Duration(days: i)).toIso8601String(),
          },
        ],
        preferences: const {'isDemo': true, 'experienceLevel': 'Expert'},
      );
    });

    _virtualCache = virtuals;
    return virtuals;
  }

  static UserModel? getVirtualUserById(String id) {
    if (!id.startsWith('demo_user_')) return null;
    final index = int.tryParse(id.split('_').last) ?? 0;
    return generateVirtualUsers(index + 1).last;
  }
}
