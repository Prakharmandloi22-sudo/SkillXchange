import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_model.dart';
import '../core/theme.dart';

class ExploreVideoCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onProfileTap;
  final VoidCallback onChatTap;
  final VoidCallback onSaveTap;

  const ExploreVideoCard({
    super.key,
    required this.user,
    required this.onProfileTap,
    required this.onChatTap,
    required this.onSaveTap,
  });

  @override
  State<ExploreVideoCard> createState() => _ExploreVideoCardState();
}

class _ExploreVideoCardState extends State<ExploreVideoCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isVideo = true;

  @override
  void initState() {
    super.initState();
    final url = widget.user.videoUrl.toLowerCase();
    _isVideo = url.contains('.mp4') || url.contains('video/upload');

    if (_isVideo) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.user.videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _initialized = true;
              _controller?.setLooping(true);
            });
          }
        });
    } else {
      setState(() {
         _initialized = true;
      });
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.user.id),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          if (_initialized && _isVideo) _controller?.play();
        } else {
          if (_initialized && _isVideo) _controller?.pause();
        }
      },
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // ── Top 3/4: Fixed Media Content ─────────────────
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: _initialized
                            ? (_isVideo 
                              ? FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _controller!.value.size.width,
                                    height: _controller!.value.size.height,
                                    child: VideoPlayer(_controller!),
                                  ),
                                )
                              : Image.network(widget.user.videoUrl, fit: BoxFit.cover))
                            : const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                      ),
                    ),
                    // Fixed Action Pillar (Save / Chat)
                    Positioned(
                      bottom: 20,
                      right: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFloatingAction(
                            Icons.bookmark_border_rounded, 
                            AppColors.accent, 
                            widget.onSaveTap
                          ),
                          const SizedBox(height: 16),
                          _buildFloatingAction(
                            Icons.forum_rounded, 
                            Colors.black, 
                            widget.onChatTap,
                            isPrimary: true
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Half: Scrollable Creative Context ─────────
            Expanded(
              flex: 1,
              child: Container(
                color: AppColors.background,
                child: GestureDetector(
                  // Intercept vertical drag to prevent parent PageView from scrolling
                  // while the user is interacting with the content area.
                  onVerticalDragUpdate: (details) {
                    _scrollController.position.moveTo(
                      _scrollController.offset - details.delta.dy,
                    );
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const NeverScrollableScrollPhysics(), // Managed by GestureDetector
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.user.name}\'S IDENTITY'.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Learn ${widget.user.teachSkills.join(", ")}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          'THE CONTEXT',
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.user.bio,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            height: 1.7,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          'EXPERTISE TAGS',
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildTag('#${widget.user.teachSkills.first}'),
                            _buildTag('#SkillXchangeMentor'),
                            _buildTag('#ExpertStatus'),
                          ],
                        ).animate().fadeIn(delay: 400.ms),
                        
                        const SizedBox(height: 48),
                        _buildIdentityMetric('PLATFORM RATING', '4.9 / 5.0', Icons.star_rounded),
                        _buildIdentityMetric('TOTAL SWAPS', '120+ Completed', Icons.bolt_rounded),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAction(IconData icon, Color color, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accent : Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
          boxShadow: isPrimary ? [
            BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), spreadRadius: 2)
          ] : null,
        ),
        child: Icon(icon, color: isPrimary ? Colors.black : color, size: 22),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIdentityMetric(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
