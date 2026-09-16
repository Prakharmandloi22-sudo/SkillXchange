import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../services/bot_responder_service.dart';
import 'user_detail_screen.dart';
import 'call_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/performance_utils.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String matchId;
  final UserModel otherUser;

  const ChatDetailScreen({
    super.key,
    required this.matchId,
    required this.otherUser,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _botResponder = BotResponderService();

  @override
  void initState() {
    super.initState();
    _checkFirstVisit();
  }

  void _checkFirstVisit() {
    final isDemo = widget.otherUser.id.startsWith('demo_') ||
        widget.otherUser.preferences['isDemo'] == true;
    
    if (isDemo) {
      // Small delay to let the UI settle before the bot pounces
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _botResponder.triggerAIResponse(widget.matchId, widget.otherUser, "INITIAL_GREETING");
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  UserModel _getMockUser() => UserModel(
        id: 'mock_user_123',
        name: 'Prakhar',
        email: 'prakhar@example.com',
        bio: 'Passionate developer & UI enthusiast.',
        teachSkills: const ['Flutter', 'Node.js', 'UI Design'],
        learnSkills: const ['Machine Learning', 'Public Speaking'],
        rating: 4.8,
        profileImage: '',
        onboardingCompleted: true,
      );

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait, syncing your profile...')),
      );
      return;
    }

    ref.read(chatServiceProvider).sendMessage(widget.matchId, user.id, text);
    _messageController.clear();

    final isDemo = widget.otherUser.id.startsWith('demo_') ||
        widget.otherUser.preferences['isDemo'] == true ||
        widget.otherUser.preferences['isDemo'] == 'true';

    if (isDemo) {
      _botResponder.triggerAIResponse(widget.matchId, widget.otherUser, text);
    }
  }

  void _startCall(bool isVideo) {
    final startTime = DateTime.now();
    final isDemo = widget.otherUser.id.startsWith('demo_') ||
        widget.otherUser.preferences['isDemo'] == true;

    if (isDemo) {
      bool isMuted = false;
      bool isCameraOff = false;
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => Container(
            color: AppColors.background.withValues(alpha: 0.98),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'profile_${widget.otherUser.id}',
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                    backgroundImage: widget.otherUser.profileImage.isNotEmpty
                        ? CachedNetworkImageProvider(
                            PerformanceUtils.optimizeCloudinaryUrl(
                                widget.otherUser.profileImage,
                                width: 200))
                        : null,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  widget.otherUser.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isVideo
                          ? 'COGNITIVE VIDEO LINK ACTIVE'
                          : 'COGNITIVE AUDIO LINK ACTIVE',
                      style: GoogleFonts.outfit(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _callActionButton(
                      isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      isMuted
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : Colors.white10,
                      () => setDialogState(() => isMuted = !isMuted),
                      iconColor: isMuted ? Colors.redAccent : Colors.white,
                    ),
                    const SizedBox(width: 32),
                    _callActionButton(
                      Icons.call_end_rounded,
                      Colors.redAccent,
                      () {
                        Navigator.pop(ctx);
                        _logCall(isVideo, startTime);
                      },
                      size: 80,
                    ),
                    const SizedBox(width: 32),
                    if (isVideo)
                      _callActionButton(
                        isCameraOff
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded,
                        isCameraOff
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : Colors.white10,
                        () =>
                            setDialogState(() => isCameraOff = !isCameraOff),
                        iconColor:
                            isCameraOff ? Colors.redAccent : Colors.white,
                      )
                    else
                      const SizedBox(width: 60),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            otherUser: widget.otherUser,
            isVideo: isVideo,
            channelId: widget.matchId,
          ),
        ),
      ).then((_) => _logCall(isVideo, startTime));
    }
  }

  void _logCall(bool isVideo, DateTime start) {
    final end = DateTime.now();
    final diff = end.difference(start);
    final duration =
        '${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
    final timeRange =
        '${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(end)}';
    final currentUser = ref.read(authStateProvider).value ?? _getMockUser();
    ref.read(chatServiceProvider).logCall(
          matchId: widget.matchId,
          senderId: currentUser.id,
          isVideo: isVideo,
          duration: '$timeRange ($duration)',
        );
  }

  Widget _callActionButton(
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    double size = 60,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.matchId));
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 40,
        title: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => UserDetailScreen(user: widget.otherUser)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.cardBackground,
                backgroundImage: widget.otherUser.profileImage.isNotEmpty
                    ? CachedNetworkImageProvider(
                        PerformanceUtils.optimizeCloudinaryUrl(
                            widget.otherUser.profileImage,
                            width: 100))
                    : null,
                child: widget.otherUser.profileImage.isEmpty
                    ? Text(widget.otherUser.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.otherUser.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        if (widget.otherUser.id == 'sx_team_0') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.verified_rounded, size: 10, color: Colors.black),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      widget.otherUser.id == 'sx_team_0' ? 'Official Support' : 'Partner Found',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.white),
            onPressed: () => _startCall(false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.white),
            onPressed: () => _startCall(true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.accent.withValues(alpha: 0.05),
              AppColors.solarGold.withValues(alpha: 0.02),
              AppColors.background,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  final myId = userAsync.value?.id ?? 'syncing';
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: Colors.white.withValues(alpha: 0.1),
                              size: 64),
                          const SizedBox(height: 16),
                          Text('No messages yet',
                              style: GoogleFonts.outfit(
                                  color: Colors.white24, fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == myId;
                      return _buildMessageBubble(msg, isMe)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2);
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent)),
                error: (e, _) {
                  debugPrint('CHAT_MESSAGES_ERROR: $e');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sync_problem_rounded,
                            color: Colors.white24, size: 40),
                        const SizedBox(height: 12),
                        Text('Securing Connection...',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildQuickActions(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    const suggestions = [
      'Hi! 👋',
      'Swap skills?',
      'Love your work!',
      'When can we talk?',
      "Let's swap!",
    ];
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActionChip(
            label: Text(suggestions[i],
                style: GoogleFonts.outfit(
                    color: i == 4 ? Colors.black : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
            backgroundColor: i == 4 ? AppColors.solarGold : Colors.white.withValues(alpha: 0.1),
            side: BorderSide(color: i == 4 ? AppColors.solarGold : Colors.white24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onPressed: () {
              _messageController.text = suggestions[i];
              _sendMessage();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    if (msg.type != MessageType.text) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      msg.type == MessageType.videoCall
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(msg.text,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${DateFormat('MMM d').format(msg.timestamp)} • ${msg.duration}',
                  style: GoogleFonts.outfit(
                      color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe
                ? [AppColors.accent, AppColors.solarGold]
                : [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.08)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isMe ? 24 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 24),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.outfit(
                color: isMe ? Colors.black : Colors.white,
                fontSize: 15,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('hh:mm a').format(msg.timestamp),
              style: GoogleFonts.outfit(
                color: isMe
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle:
                          GoogleFonts.outfit(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.accent,
                      blurRadius: 10,
                      spreadRadius: -2)
                ],
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
