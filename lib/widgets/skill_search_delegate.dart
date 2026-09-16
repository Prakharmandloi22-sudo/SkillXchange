import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../viewmodel/matcher_viewmodel.dart';
import '../core/theme.dart';
import '../view/user_detail_screen.dart';
import '../core/performance_utils.dart';

class SkillSearchDelegate extends SearchDelegate<UserModel?> {
  final WidgetRef ref;

  SkillSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search Skills or Experts';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded, color: Colors.white70),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSuggestionsGrid();
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<UserModel>>(
      future: ref.read(matcherServiceProvider).searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, color: Colors.white10, size: 80),
                const SizedBox(height: 16),
                Text(
                  'No results for "$query"',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UserDetailScreen(user: user))),
                contentPadding: const EdgeInsets.all(12),
                tileColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.white10),
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      PerformanceUtils.optimizeCloudinaryUrl(user.profileImage, width: 100),
                    ),
                  ),
                ),
                title: Text(
                  user.name,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  user.teachSkills.join(" • "),
                  style: GoogleFonts.inter(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSuggestionsGrid() {
    final commonSkills = ['Flutter', 'Python', 'UI Design', 'Guitar', 'Cooking', 'Yoga', 'SEO', 'Data Science'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            'POPULAR SKILLS',
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: commonSkills.map((skill) => GestureDetector(
              onTap: () => query = skill,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
