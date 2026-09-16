import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

/// A minimal, stylish logo for SkillXchange featuring a big 'S' monogram.
class AnimatedGradientLogo extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const AnimatedGradientLogo({
    super.key,
    this.text = '',
    this.fontSize = 42,
    this.fontWeight = FontWeight.w900,
  });

  @override
  State<AnimatedGradientLogo> createState() => _AnimatedGradientLogoState();
}

class _AnimatedGradientLogoState extends State<AnimatedGradientLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ScaleTransition(
          scale: _pulseAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient soft glow behind logo
              Container(
                width: widget.fontSize * 1.8,
                height: widget.fontSize * 1.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: AppColors.solarGold.withValues(alpha: 0.08),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              
              if (widget.text.isEmpty)
                _buildBigSLogo()
              else
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.accent, AppColors.solarGold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    widget.text,
                    style: GoogleFonts.outfit(
                      fontSize: widget.fontSize,
                      fontWeight: widget.fontWeight,
                      letterSpacing: -1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBigSLogo() {
    final size = widget.fontSize > 0 ? widget.fontSize * 2.2 : 80.0;
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: _MinimalSMonogramPainter(),
      ),
    );
  }
}

/// Paints a big, bold, ultra-minimal & stylish 'S' monogram logo
class _MinimalSMonogramPainter extends CustomPainter {
  const _MinimalSMonogramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokeWidth = w * 0.12;

    // Gradient Paint: Electric Cyan to Solar Gold
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppColors.accent,
          AppColors.solarGold,
          AppColors.coral,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Smooth minimal 'S' path
    final path = Path();

    // Top loop curve of 'S'
    path.moveTo(w * 0.72, h * 0.28);
    path.cubicTo(
      w * 0.72, h * 0.15,
      w * 0.30, h * 0.15,
      w * 0.30, h * 0.35,
    );

    // Diagonal middle transition curve of 'S'
    path.cubicTo(
      w * 0.30, h * 0.52,
      w * 0.70, h * 0.48,
      w * 0.70, h * 0.65,
    );

    // Bottom loop curve of 'S'
    path.cubicTo(
      w * 0.70, h * 0.85,
      w * 0.28, h * 0.85,
      w * 0.28, h * 0.72,
    );

    canvas.drawPath(path, strokePaint);

    // Minimal accent dots on terminals for extra polish
    final dotPaint1 = Paint()..color = AppColors.accent;
    final dotPaint2 = Paint()..color = AppColors.coral;

    canvas.drawCircle(Offset(w * 0.72, h * 0.28), strokeWidth * 0.25, dotPaint1);
    canvas.drawCircle(Offset(w * 0.28, h * 0.72), strokeWidth * 0.25, dotPaint2);
  }

  @override
  bool shouldRepaint(covariant _MinimalSMonogramPainter oldDelegate) => false;
}
