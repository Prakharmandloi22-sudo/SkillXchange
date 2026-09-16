import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../core/theme.dart';
import '../core/performance_utils.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/matcher_viewmodel.dart';
import 'chat_detail_screen.dart';
import '../services/matcher_service.dart';

class UserDetailScreen extends ConsumerWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background Mesh Blobs ──────────────────
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.deepAurora.withValues(alpha: 0.15),
              ),
            ).animate(onPlay: (c) => c.repeat()).move(begin: Offset.zero, end: const Offset(-50.0, 50.0), duration: 4.seconds, curve: Curves.easeInOut).fadeIn(),
          ),
          
          CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 450,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      user.profileImage.isNotEmpty
                          ? Image(
                              image: CachedNetworkImageProvider(
                                user.profileImage.contains('dicebear.com') && !user.profileImage.contains('size=')
                                    ? '${user.profileImage}&size=640'
                                    : PerformanceUtils.optimizeCloudinaryUrl(user.profileImage, width: 800)
                              ),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.auroraGradient,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 140,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                      // Bottom gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.7),
                              AppColors.background,
                            ],
                            stops: const [0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: user.name,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ", ${user.age}",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (currentUser == null) return;
                              // Generate ID syncly for instant navigation
                              final mId = MatcherService.getMatchId(currentUser.id, user.id);
                              
                              // Trigger persistence in background (fire and forget)
                              ref.read(matcherServiceProvider).createChatRequest(currentUser.id, user.id);
                              
                              Navigator.push(context, MaterialPageRoute(
                                builder: (c) => ChatDetailScreen(matchId: mId, otherUser: user)
                              ));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), spreadRadius: 2)
                                ],
                              ),
                              child: const Icon(Icons.forum_rounded, color: Colors.white, size: 28),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds).animate().scale(delay: 500.ms),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      if (user.bio.isNotEmpty)
                        Text(
                          user.bio,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 17,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                      const SizedBox(height: 40),

                      // Skills Section
                      _sectionTitle('MASTERS IN'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: user.teachSkills
                            .map((s) => _skillTag(s, true))
                            .toList(),
                      ),

                      const SizedBox(height: 32),
                      _sectionTitle('CURIOUS ABOUT'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: user.learnSkills
                            .map((s) => _skillTag(s, false))
                            .toList(),
                      ),

                      const SizedBox(height: 40),

                       // Preferences Selection
                      _sectionTitle('MISSION DETAILS'),
                      const SizedBox(height: 20),
                      _preferenceItem(
                        Icons.insights_rounded,
                        'EXPERIENCE LEVEL',
                        user.preferences['experience'] ?? 'Intermidiate',
                      ),
                      _preferenceItem(
                        Icons.hub_rounded,
                        'INTERACTION MODE',
                        user.preferences['method'] ?? 'Collaborative',
                      ),

                      const SizedBox(height: 40),

                      // Expert Gallery
                      if (user.posts.isNotEmpty) ...[
                        _sectionTitle('EXPERT GALLERY'),
                        const SizedBox(height: 20),
                        GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: user.posts.length,
                          itemBuilder: (context, index) {
                            final post = user.posts[index];
                            final isVideo = (post['type'] ?? 'image') == 'video';
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  PerformanceUtils.buildOptimizedImage(
                                    post['url'], 
                                    targetWidth: 400,
                                    isVideo: isVideo,
                                  ),
                                  if (isVideo)
                                    const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40)),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.transparent, Colors.black87],
                                        ),
                                      ),
                                      child: Text(
                                        post['bio'] ?? '',
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 140), // Space for bottom
                    ],
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.05),
                ),
              ),
            ],
          ),
          
          // ── Float Action Button (Connect) ───────────
          // Bottom button removed as per request - using Chat Icon instead
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 3.0,
      ),
    );
  }

  Widget _skillTag(String skill, bool isTeach) {
    final color = isTeach ? AppColors.accent : AppColors.neonCyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        skill,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _preferenceItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

