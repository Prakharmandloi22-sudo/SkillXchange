import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/user_model.dart';
import '../viewmodel/matcher_viewmodel.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../core/theme.dart';
import 'user_detail_screen.dart';
import 'chat_detail_screen.dart';
import '../services/matcher_service.dart';
import '../core/performance_utils.dart';
import '../widgets/skill_search_delegate.dart';

class ExplorePage extends ConsumerStatefulWidget {
  final UserModel currentUser;
  final VoidCallback? onNavigateToSaved;
  const ExplorePage({super.key, required this.currentUser, this.onNavigateToSaved});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final PageController _mediaController = PageController();
  final PageController _contentController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _mediaController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _syncScroll(int index) {
    setState(() => _currentIndex = index);
    _mediaController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(discoveryPostsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text('No experts found',
                  style: TextStyle(color: Colors.white38)),
            );
          }
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: PageView.builder(
                      controller: _mediaController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) =>
                          _DiscoveryMediaItem(post: posts[index]),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: AppColors.background,
                      child: PageView.builder(
                        controller: _contentController,
                        scrollDirection: Axis.vertical,
                        onPageChanged: _syncScroll,
                        itemCount: posts.length,
                        itemBuilder: (context, index) =>
                            _buildContentView(posts[index]),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _topIcon(Icons.menu_rounded,
                        onTap: () => Scaffold.of(context).openDrawer()),
                    _topIcon(Icons.search_rounded,
                        onTap: () => showSearch(
                            context: context,
                            delegate: SkillSearchDelegate(ref))),
                  ],
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.25 + 20,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingAction(
                      widget.currentUser.savedUsers.contains(posts[_currentIndex].user.id)
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      AppColors.accent,
                      () {
                        final targetId = posts[_currentIndex].user.id;
                        ref.read(authActionsProvider.notifier).toggleSaveUser(
                            widget.currentUser.id, targetId);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.currentUser.savedUsers.contains(targetId) 
                                ? 'Removed from Vault' 
                                : 'Added to Vault',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppColors.accent,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFloatingAction(
                      Icons.forum_rounded,
                      Colors.black,
                      () {
                        final otherUser = posts[_currentIndex].user;
                        final mId = MatcherService.getMatchId(widget.currentUser.id, otherUser.id);
                        
                        // Fire and forget persistence
                        ref.read(matcherServiceProvider).createChatRequest(widget.currentUser.id, otherUser.id);
                        
                        Navigator.push(context, MaterialPageRoute(
                            builder: (c) => ChatDetailScreen(
                                matchId: mId,
                                otherUser: otherUser)));
                      },
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, st) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _topIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildContentView(DiscoveryPost post) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (c) => UserDetailScreen(user: post.user)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${post.user.name}\'S IDENTITY'.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.accent, size: 10),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              post.bio,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: post.user.teachSkills
                  .map((s) => Text('#$s',
                      style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAction(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.accent
              : Colors.black.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Icon(icon, color: isPrimary ? Colors.black : color, size: 24),
      ),
    );
  }
}

class _DiscoveryMediaItem extends StatefulWidget {
  final DiscoveryPost post;
  const _DiscoveryMediaItem({required this.post});

  @override
  State<_DiscoveryMediaItem> createState() => _DiscoveryMediaItemState();
}

class _DiscoveryMediaItemState extends State<_DiscoveryMediaItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  late bool _isVideo;

  @override
  void initState() {
    super.initState();
    _isVideo = widget.post.url.toLowerCase().contains('.mp4') ||
        widget.post.url.contains('video/upload');
    if (_isVideo) {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.post.url))
            ..initialize().then((_) {
              if (mounted) {
                setState(() {
                  _initialized = true;
                  _controller?.setLooping(true);
                  _controller?.play();
                  _controller?.setVolume(0);
                });
              }
            });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (c) => UserDetailScreen(user: widget.post.user)),
      ),
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isVideo)
              _initialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  : PerformanceUtils.buildOptimizedImage(widget.post.url,
                      isVideo: true)
            else
              PerformanceUtils.buildOptimizedImage(widget.post.url,
                  isVideo: false),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
