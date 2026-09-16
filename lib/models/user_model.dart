class UserModel {
  final String id;
  final String name;
  final String email;
  final String bio;
  final List<String> teachSkills;
  final List<String> learnSkills;
  final double rating;
  final String profileImage;
  final String provider; // 'email' | 'google.com'

  final bool onboardingCompleted;
  final Map<String, dynamic> preferences;
  final int age;
  final String videoUrl;
  final List<Map<String, dynamic>> posts; // List of Expert Posts
  final List<String> savedUsers; // List of Bookmarked User IDs

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.teachSkills,
    required this.learnSkills,
    required this.rating,
    required this.profileImage,
    this.provider = 'email',
    this.onboardingCompleted = false,
    this.preferences = const {},
    this.age = 24,
    this.videoUrl = '',
    this.posts = const [],
    this.savedUsers = const [],
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
    List<String>? teachSkills,
    List<String>? learnSkills,
    double? rating,
    String? profileImage,
    String? provider,
    bool? onboardingCompleted,
    Map<String, dynamic>? preferences,
    int? age,
    String? videoUrl,
    List<Map<String, dynamic>>? posts,
    List<String>? savedUsers,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      teachSkills: teachSkills ?? this.teachSkills,
      learnSkills: learnSkills ?? this.learnSkills,
      rating: rating ?? this.rating,
      profileImage: profileImage ?? this.profileImage,
      provider: provider ?? this.provider,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      preferences: preferences ?? this.preferences,
      age: age ?? this.age,
      videoUrl: videoUrl ?? this.videoUrl,
      posts: posts ?? this.posts,
      savedUsers: savedUsers ?? this.savedUsers,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String parsedImage = (json['profileImage'] ?? '').toString();
    final nameStr = (json['name'] ?? '').toString();
    final idStr = (json['_id'] ?? json['id'] ?? '').toString();

    if (parsedImage.isEmpty) {
      // The image of the users comes to their own name. Fix it.
      parsedImage = 'https://api.dicebear.com/7.x/initials/png?seed=${Uri.encodeComponent(nameStr)}&backgroundColor=131313&textColor=E3B873';
    } else if (parsedImage.contains('unsplash.com')) {
      parsedImage = 'https://randomuser.me/api/portraits/${idStr.hashCode.abs() % 2 == 0 ? "women" : "men"}/${idStr.hashCode.abs() % 15 + 1}.jpg';
    }

    return UserModel(
      id: idStr,
      name: nameStr,
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      teachSkills: List<String>.from(json['teachSkills'] ?? []),
      learnSkills: List<String>.from(json['learnSkills'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      profileImage: parsedImage,
      provider: json['provider'] ?? 'email',
      onboardingCompleted: json['onboardingCompleted'] ?? false,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      age: json['age'] ?? 24,
      videoUrl: json['videoUrl'] ?? 'https://assets.mixkit.co/videos/preview/mixkit-girl-in-neon-lighting-dancing-40040-large.mp4',
      posts: List<Map<String, dynamic>>.from(json['posts'] ?? []),
      savedUsers: List<String>.from(json['savedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'bio': bio,
      'teachSkills': teachSkills,
      'learnSkills': learnSkills,
      'rating': rating,
      'profileImage': profileImage,
      'provider': provider,
      'onboardingCompleted': onboardingCompleted,
      'preferences': preferences,
      'age': age,
      'videoUrl': videoUrl,
      'posts': posts,
      'savedUsers': savedUsers,
    };
  }
}
