import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'post_preview_screen.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/matcher_viewmodel.dart';
import '../core/theme.dart';
import '../core/performance_utils.dart';
import '../services/matcher_service.dart';
import 'chat_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'user_detail_screen.dart';
import 'explore_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserModel currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _inboxSearchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) { return const Center(child: CircularProgressIndicator()); }
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          appBar: _buildDynamicAppBar(user),
          drawer: _buildAppDrawer(user),
          body: _buildPage(user),
          bottomNavigationBar: _buildOriginalBottomNav(),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _topIcon(IconData icon, {VoidCallback? onTap, double size = 22}) =>
      Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: Colors.white, size: size),
          onPressed: onTap,
          splashColor: AppColors.accent.withValues(alpha: 0.2),
          highlightColor: AppColors.solarGold.withValues(alpha: 0.1),
        ),
      ).animate().scale(duration: 200.ms, curve: Curves.easeOut);

  PreferredSizeWidget? _buildDynamicAppBar(UserModel user) {
    switch (_currentIndex) {
      case 0:
        return null; // ExplorePage has its own header scroll management
      case 1:
        return _buildInboxTopBar();
      case 2:
        return null;
      default:
        return null;
    }
  }

  Widget _buildPage(UserModel user) {
    switch (_currentIndex) {
      case 0:
        return ExplorePage(
          currentUser: user,
          onNavigateToSaved: () => setState(() => _currentIndex = 2),
        );
      case 1:
        return _buildInboxSection(user);
      case 2:
        return _buildSavedSection(user);
      case 3:
        return _buildProfileSection(user);
      default:
        return ExplorePage(
          currentUser: user,
          onNavigateToSaved: () => setState(() => _currentIndex = 2),
        );
    }
  }

  Widget _buildSavedSection(UserModel user) {
    final savedAsync = ref.watch(savedUsersProvider);

    return Column(
      children: [
        _buildTopHeader('Vault', 'Your curated list of experts'),
        Expanded(
          child: savedAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return _buildEmptyState(
                  'Empty Vault',
                  'Bookmarked experts will appear here',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final expert = users[index];
                  return _buildSavedRectangleCard(expert);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (e, st) => _buildEmptyState(
              'Connection Issue',
              'Check your network and try again',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedRectangleCard(UserModel user) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => UserDetailScreen(user: user)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            PerformanceUtils.buildOptimizedImage(
              user.profileImage,
              fit: BoxFit.cover,
            ),
            // Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.4, 0.9],
                ),
              ),
            ),
            // Profile Info
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.teachSkills.join(" • "),
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Quick Chat Button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.black,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Discovery and Explore sections are now handled by DiscoveryPage and ExplorePage

  PreferredSizeWidget _buildInboxTopBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.only(left: 8),
      child: _topIcon(
        Icons.menu_rounded,
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        size: 22,
      ),
    ),
    titleSpacing: 0,
    title: Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(1.5), // The border width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          colors: [AppColors.accent, Colors.transparent, AppColors.solarGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _inboxSearchController,
                onChanged: (v) => setState(() {}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'COMMAND / SEARCH',
                  hintStyle: TextStyle(
                    color: Colors.white10,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 20,
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.tune_rounded, color: Colors.white24, size: 18),
            ),
          ],
        ),
      ),
    ),
    actions: [
      _topIcon(Icons.mode_comment_outlined, onTap: () {}, size: 20),
      const SizedBox(width: 8),
    ],
  );

  Widget _buildAppDrawer(UserModel user) => Drawer(
    backgroundColor: const Color(0xFF0D0D0D),
    child: SafeArea(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            onDetailsPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
            decoration: const BoxDecoration(color: Colors.transparent),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.profileImage),
              ),
            ),
            accountName: Text(
              user.name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user.email,
              style: const TextStyle(color: Colors.white38),
            ),
          ),
          _drawerItem(
            Icons.person_add_outlined,
            'Request Users',
            'Pending swap requests',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => _buildRequestScreen(user)),
              );
            },
          ),
          _drawerItem(
            Icons.delete_outline_rounded,
            'Deleted Users',
            'Users you removed',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => _buildUserManagementScreen('Deleted Users'),
                ),
              );
            },
          ),
          const Divider(
            color: Colors.white10,
            indent: 20,
            endIndent: 20,
            height: 40,
          ),
          _drawerItem(
            Icons.qr_code_scanner_rounded,
            'Connect with ID',
            'Scan or enter user ID',
            () {
              Navigator.pop(context);
              _showConnectByIDDialog();
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'SkillXchange v2.4.0',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.1),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _drawerItem(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon, color: AppColors.accent, size: 22),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(
      sub,
      style: const TextStyle(color: Colors.white38, fontSize: 11),
    ),
    onTap: onTap,
  );

  void _showConnectByIDDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Connect with ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the User ID of the person you want to connect with.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. user_123',
                prefixIcon: const Icon(
                  Icons.perm_identity,
                  color: AppColors.accent,
                ),
                fillColor: Colors.black.withValues(alpha: 0.2),
              ),
              onSubmitted: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                await ref
                    .read(matcherServiceProvider)
                    .createChatRequest(widget.currentUser.id, v);
                if (!c.mounted) return;
                Navigator.pop(c);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Connecting...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestScreen(UserModel user) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Swap Requests'),
      backgroundColor: Colors.transparent,
    ),
    body: _buildEmptyState(
      'No pending requests',
      'New experts will appear here when they want to swap',
    ),
  );

  Widget _buildUserManagementScreen(String title) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent),
    body: _buildEmptyState('Empty list', 'No users found in $title'),
  );

  // ── INBOX SECTION ──────────────────────────────────────────
  Widget _buildInboxSection(UserModel currentUser) {
    final chatsAsync = ref.watch(matcherMatchesProvider);
    return Column(
      children: [
        _buildNotesBar(currentUser),
        Expanded(
          child: chatsAsync.when(
            data: (matches) {
              final query = _inboxSearchController.text.toLowerCase();
              final filtered = matches.where((m) {
                final other = m['otherUser'] as UserModel?;
                if (other == null) return false;
                return other.name.toLowerCase().contains(query);
              }).toList();

              if (filtered.isEmpty) {
                if (query.isNotEmpty) {
                  return _buildEmptyState(
                    'No results',
                    'Try searching for a different name',
                  );
                }
                return _buildEmptyState(
                  'Quiet Inbox',
                  'Fresh opportunities await in Explore',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final match = filtered[i];
                  final otherUser = match['otherUser'] as UserModel;
                  final isSuggested = match['isSuggested'] ?? false;
                  
                  return _modernChatTile(
                    name: otherUser.name,
                    message: match['lastMessage'] ?? 'Potential Swap Match',
                    imageUrl: otherUser.profileImage,
                    isSuggested: isSuggested,
                    timestamp: match['lastMessageTime'] is DateTime ? match['lastMessageTime'] as DateTime : DateTime.now(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ChatDetailScreen(
                          matchId: match['id'],
                          otherUser: otherUser,
                        ),
                      ),
                    ),
                    onImageTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => UserDetailScreen(user: otherUser),
                      ),
                    ),
                  ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (e, st) {
              debugPrint('INBOX_SILENT_ERROR: $e');
              return _buildEmptyState(
                'Securing Connection',
                'Your messages are being synchronized...',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _modernChatTile({
    required String name,
    required String message,
    required String imageUrl,
    required VoidCallback onTap,
    required DateTime timestamp,
    bool isSuggested = false,
    VoidCallback? onImageTap,
  }) {
    final timeStr = DateFormat('jm').format(timestamp);
    final isDemo = name.contains('Arjun') || name.contains('Sanya') || name.contains('Vikram'); // Simple heuristic for mock online status

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSuggested ? AppColors.accent.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSuggested ? AppColors.accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: GestureDetector(
          onTap: onImageTap,
          child: Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSuggested ? AppColors.accent : Colors.white10,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: AppColors.cardBackground,
                  backgroundImage: imageUrl.isNotEmpty 
                    ? CachedNetworkImageProvider(PerformanceUtils.optimizeCloudinaryUrl(imageUrl, width: 120))
                    : null,
                ),
              ),
              if (isDemo || !isSuggested)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E), // Online Green
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              timeStr,
              style: GoogleFonts.inter(
                color: Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: isSuggested ? AppColors.accent.withValues(alpha: 0.7) : Colors.white38,
                    fontSize: 13,
                    fontWeight: isSuggested ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSuggested)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'PROMPT',
                    style: GoogleFonts.outfit(
                      color: AppColors.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PROFILE SECTION ───────────────────────────────────────────
  Widget _buildProfileSection(UserModel user) {
    final isMe = user.id == widget.currentUser.id;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopHeader(
            'Profile',
            'How you appear to others',
            actionWidget: isMe
                ? IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: () => _showAccountManagement(user),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          // Avatar
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.2),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(70),
            child: PerformanceUtils.buildOptimizedImage(
              user.profileImage,
              targetWidth: 280,
              placeholder: Container(color: AppColors.cardBackground),
            ),
          ),
        ),
          const SizedBox(height: 24),
          Text(
            user.name,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.bio,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          ).animate().fadeIn(),
          const SizedBox(height: 32),
          // Interaction Bar
          if (isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _profileActionButton(
                      'EDIT PROFILE',
                      Icons.edit_note_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _profileActionButton(
                      'NEW POST',
                      Icons.add_circle_outline_rounded,
                      () => _handleCreatePostAction(),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 48),
          // Grid
          _buildProfileGrid(user),
        ],
      ),
    );
  }

  Widget _profileActionButton(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) => ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.cardBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
    ),
  );

  Widget _buildProfileGrid(UserModel user) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('discovery_posts')
          .stream(primaryKey: ['id'])
          .order('server_timestamp', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final docs = snapshot.data ?? [];
        final posts = docs
            .where((d) => (d['user_id'] ?? d['userId']) == user.id)
            .toList();

        if (posts.isEmpty) {
          return _buildEmptyState('No posts yet', 'Share your skills with a post');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final post = posts[i];
            final isVideo = (post['type'] ?? 'image') == 'video';
            return GestureDetector(
              onLongPress: () => _showPostOptions(user, post['id'].toString(), post),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PerformanceUtils.buildOptimizedImage(
                      post['url'],
                      isVideo: isVideo,
                    ),
                    if (isVideo)
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                        child: Text(
                          post['bio'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPostOptions(UserModel user, String postId, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _postOptionItem(Icons.edit_rounded, 'Edit Caption', () {
              Navigator.pop(c);
              _showEditPostDialog(user, postId, post);
            }),
            _postOptionItem(Icons.archive_outlined, 'Archive Post', () {
              Navigator.pop(c);
              _handlePostAction(user, postId, 'archived');
            }),
            _postOptionItem(Icons.delete_outline_rounded, 'Delete Post', () {
              Navigator.pop(c);
              _handlePostAction(user, postId, 'deleted');
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _postOptionItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) => ListTile(
    leading: Icon(
      icon,
      color: isDestructive ? Colors.redAccent : Colors.white70,
    ),
    title: Text(
      title,
      style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white),
    ),
    onTap: onTap,
  );

  void _handlePostAction(UserModel user, String postId, String action) async {
    try {
      if (action == 'deleted') {
        await Supabase.instance.client.from('discovery_posts').delete().eq('id', postId);
      } else {
        await Supabase.instance.client.from('discovery_posts').update({'bio': action}).eq('id', postId);
      }

      if (mounted) {
        final statusMessage = action == 'restore' ? 'restored' : '${action}d';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post $statusMessage!'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      debugPrint('POST_ACTION_ERROR: $e');
    }
  }

  void _showEditPostDialog(UserModel user, String postId, Map<String, dynamic> post) {
    final TextEditingController editController = TextEditingController(
      text: post['bio'] ?? '',
    );
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Text(
          'Edit Caption',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('discovery_posts')
                    .update({'bio': editController.text})
                    .eq('id', postId);
                
                if (c.mounted) Navigator.pop(c);
              } catch (e) {
                debugPrint('EDIT_POST_ERROR: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showAccountManagement(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.archive_outlined,
                color: Colors.white70,
              ),
              title: const Text(
                'Expert Archive',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Quickly restore or hide your posts',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(context);
                _showPostManagementScreen(user, 'archived');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.white70,
              ),
              title: const Text(
                'Recycle Bin',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Posts deleted from your profile',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(context);
                _showPostManagementScreen(user, 'deleted');
              },
            ),
            const Divider(
              color: Colors.white12,
              indent: 20,
              endIndent: 20,
              height: 32,
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(authActionsProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPostManagementScreen(UserModel user, String mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (sc, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    mode == 'archived'
                        ? Icons.archive_outlined
                        : Icons.delete_sweep_rounded,
                    color: AppColors.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    mode == 'archived' ? 'Archive' : 'Recycle Bin',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer(
                builder: (ctx, ref, _) {
                  final liveUser = ref.watch(authStateProvider).value;
                  if (liveUser == null) return const SizedBox.shrink();
                  final posts = liveUser.posts
                      .where((p) => p['status'] == mode)
                      .toList();

                  if (posts.isEmpty) {
                    return _buildEmptyState(
                      'Empty section',
                      'No posts found in ${mode == "archived" ? "archive" : "bin"}',
                    );
                  }
                  return GridView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: posts.length,
                    itemBuilder: (ctx, i) {
                      final post = posts[i];
                      final isVideo = post['type'] == 'video';
                      final originalIndex = liveUser.posts.indexOf(post);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PerformanceUtils.buildOptimizedImage(
                              post['url'],
                              isVideo: isVideo,
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: ElevatedButton(
                                onPressed: () => _handlePostAction(
                                  liveUser,
                                  originalIndex.toString(),
                                  'restore',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(0, 36),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'RESTORE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildSavedSection removed

  // ── COMMON WIDGETS ───────────────────────────────────────────

  Widget _buildTopHeader(
    String title,
    String subtitle, {
    Widget? actionWidget,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
        if (actionWidget != null) ...[const SizedBox(width: 12), actionWidget],
      ],
    ),
  );
  Widget _buildEmptyState(String t, String s) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(s, style: const TextStyle(color: Colors.white38)),
      ],
    ),
  );
  Widget _buildNotesBar(UserModel currentUser) {
    final virtuals = MatcherService.generateVirtualUsers(5);

    return Container(
      height: 130, // Increased height for better clearance
      padding: const EdgeInsets.only(left: 24),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none, // Allow note bubbles to float outside slightly
        children: [
          _buildNoteItem(
            currentUser.name,
            currentUser.profileImage,
            isMe: true,
            noteText: "Add note",
          ),
          ...virtuals.map(
            (u) => _buildNoteItem(
              u.name,
              u.profileImage,
              noteText: u.teachSkills.first,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(
    String name,
    String img, {
    bool isMe = false,
    String noteText = "",
  }) => Padding(
    padding: const EdgeInsets.only(
      right: 20,
      top: 10,
    ), // Added top padding for bubble
    child: Column(
      children: [
        GestureDetector(
          onTap: () {
            if (isMe) {
              _handleCreatePostAction();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$name shared a note: "Learning $noteText today!"',
                  ),
                  backgroundColor: AppColors.cardBackground,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMe ? AppColors.accent : Colors.white12,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    PerformanceUtils.optimizeCloudinaryUrl(img, width: 132),
                  ),
                ),
              ),
              if (isMe)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 12, color: Colors.black),
                  ),
                ),
              // Note Bubble
              Positioned(
                top: -15,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    noteText,
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name.split(' ')[0],
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  void _handleCreatePostAction() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final isVideo = pickedFile.path.toLowerCase().endsWith('.mp4');

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostPreviewScreen(
          file: file,
          isVideo: isVideo,
          onConfirm: (bio) async {
            _uploadAndSavePost(file, isVideo, bio);
          },
        ),
      ),
    );
  }

  void _uploadAndSavePost(File file, bool isVideo, String bio) async {
    // Show uploading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(isVideo ? 'Transcoding video...' : 'Compressing photo...'),
          ],
        ),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final url = await ref
          .read(cloudinaryServiceProvider)
          .uploadPostMedia(file, isVideo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      _saveExpertPost(url, isVideo, bio);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully posted to your Pulse!'),
          backgroundColor: Colors.greenAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _saveExpertPost(String url, bool isVideo, String bio) async {
    // Publish to Global Discovery Feed in Supabase
    try {
      await Supabase.instance.client.from('discovery_posts').insert({
        'user_id': widget.currentUser.id,
        'user_name': widget.currentUser.name,
        'user_image': widget.currentUser.profileImage,
        'user_skills': widget.currentUser.teachSkills,
        'url': url,
        'type': isVideo ? 'video' : 'image',
        'bio': bio,
        'rating': widget.currentUser.rating,
        'server_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('DISCOVERY_SYNC_ERROR: $e');
    }

    ref.read(authServiceProvider).updateProfileFields(
      widget.currentUser.id,
      {'updatedAt': DateTime.now().toIso8601String()},
    );

    ref.invalidate(authStateProvider);
  }

  Widget _buildOriginalBottomNav() => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: const BoxDecoration(
      color: Color(0xFF0D0D0D),
      border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _originalNavItem(0, Icons.explore_rounded, 'Explore'),
        _originalNavItem(1, Icons.chat_bubble_rounded, 'Main'),
        // Center + button
        GestureDetector(
          onTap: () => _handleCreatePostAction(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
        _originalNavItem(2, Icons.bookmark_rounded, 'Saved'),
      ],
    ),
  );

  Widget _originalNavItem(int idx, IconData icon, String label) {
    final isSel = _currentIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSel ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSel ? Colors.white : Colors.white38,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSel ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
