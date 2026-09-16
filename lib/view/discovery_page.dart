import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../viewmodel/matcher_viewmodel.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../core/theme.dart';
import '../widgets/explore_video_card.dart';
import 'user_detail_screen.dart';
import 'chat_detail_screen.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  final UserModel currentUser;
  const DiscoveryPage({super.key, required this.currentUser});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(discoveryPostsProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, color: Colors.white24, size: 64),
                const SizedBox(height: 16),
                Text('NO EXPERTS FOUND', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                Text('Check back later for new skill swaps', 
                  style: TextStyle(color: Colors.white38)),
              ],
            ),
          );
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final post = posts[i];
            return ExploreVideoCard(
              user: post.user,
              onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UserDetailScreen(user: post.user))),
              onChatTap: () async {
                final mId = await ref.read(matcherServiceProvider).createChatRequest(widget.currentUser.id, post.user.id);
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(matchId: mId, otherUser: post.user)));
              },
              onSaveTap: () => ref.read(authActionsProvider.notifier).toggleSaveUser(widget.currentUser.id, post.user.id),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
    );
  }
}
