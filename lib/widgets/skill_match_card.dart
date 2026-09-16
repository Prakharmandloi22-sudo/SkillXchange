import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../view/user_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SkillMatchCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onSwap;
  final VoidCallback? onSkip;

  const SkillMatchCard({
    super.key,
    required this.user,
    this.onSwap,
    this.onSkip,
  });

  @override
  State<SkillMatchCard> createState() => _SkillMatchCardState();
}

class _SkillMatchCardState extends State<SkillMatchCard> {
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  void _onHover(PointerEvent details, Size size) {
    setState(() {
      _tiltY = (details.localPosition.dx / size.width - 0.5) * 0.2;
      _tiltX = (details.localPosition.dy / size.height - 0.5) * -0.2;
    });
  }

  void _onExit(PointerEvent details) {
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) =>
          _onHover(e, const Size(400, 600)), // Approximate card size
      onExit: _onExit,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(user: widget.user),
            ),
          );
        },
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 200),
          turns: 0,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateX(_tiltX)
              ..rotateY(_tiltY),
            alignment: FractionalOffset.center,
            child: _buildCardContent(),
          ),
        ),
      ),
    );
  }

  String get _cleanName {
    // Fixes the "LUCAS 35" leak - removes any numbers from the end of the name
    return widget.user.name.replaceAll(RegExp(r'\s*\d+$'), '').toUpperCase();
  }

  Widget _buildCardContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-Screen Immersive Portrait (Ultra-HD 1024px) ──
          widget.user.profileImage.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: widget.user.profileImage.contains('dicebear.com') && !widget.user.profileImage.contains('size=')
                      ? '${widget.user.profileImage}&size=1024'
                      : widget.user.profileImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.high,
                  placeholder: (context, url) => Container(
                    decoration: const BoxDecoration(gradient: AppColors.cosmicGradient),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              : Container(
                  decoration: const BoxDecoration(gradient: AppColors.cosmicGradient),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 140,
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                ),

          // ── Progressive Identity Scrim ───────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.85), // Deeper bottom for text
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // ── Info Overlay (Name, User ID, Age at Down Side) ──
          Positioned(
            left: 20,
            right: 20,
            bottom: 100, // Balanced anchor
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _cleanName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28, // Compact, high-end
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${widget.user.age}",
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 22, // Balanced
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Text(
                  "USER ID: ${widget.user.id.toUpperCase()}",
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (widget.user.teachSkills.length > 3 
                      ? widget.user.teachSkills.take(3) 
                      : widget.user.teachSkills)
                      .map((skill) => _modernSkillChip(skill))
                      .toList(),
                ),
              ],
            ),
          ),

          // ── Floating Action Cluster (Dual-Action Clean) ──
          Positioned(
            left: 40,
            right: 40,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: widget.onSkip,
                  child: _circularAction(Icons.close_rounded, Colors.white, Colors.redAccent.withValues(alpha: 0.2)),
                ),
                GestureDetector(
                  onTap: widget.onSwap,
                  child: _circularAction(Icons.favorite_rounded, Colors.black87, AppColors.accent, isPrimary: true),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _modernSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        skill,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _circularAction(IconData icon, Color iconColor, Color bgColor, {bool isPrimary = false}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: isPrimary ? [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: Icon(icon, color: iconColor, size: 30),
    );
  }
}
