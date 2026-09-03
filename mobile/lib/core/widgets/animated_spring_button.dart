import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedSpringButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double height;
  final double borderRadius;

  const AnimatedSpringButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.arrow_forward_rounded,
    this.backgroundColor = const Color(0xFF047857),
    this.foregroundColor = Colors.white,
    this.height = 52,
    this.borderRadius = 14,
  });

  @override
  State<AnimatedSpringButton> createState() => _AnimatedSpringButtonState();
}

class _AnimatedSpringButtonState extends State<AnimatedSpringButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic, reverseCurve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          if (isEnabled) {
            widget.onPressed!();
          }
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  gradient: LinearGradient(
                    colors: _isHovered
                        ? [
                            const Color(0xFF065F46),
                            const Color(0xFF047857),
                          ]
                        : [
                            const Color(0xFF047857),
                            const Color(0xFF064E3B),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.withOpacity(_isHovered ? 0.45 : 0.28),
                      blurRadius: _isHovered ? 18 : 12,
                      offset: Offset(0, _isHovered ? 6 : 4),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: widget.isLoading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: widget.foregroundColor,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Row(
                            key: const ValueKey('content'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.text,
                                style: GoogleFonts.inter(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: widget.foregroundColor,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              if (widget.icon != null) ...[
                                const SizedBox(width: 8),
                                AnimatedSlide(
                                  duration: const Duration(milliseconds: 200),
                                  offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                                  child: Icon(
                                    widget.icon,
                                    color: widget.foregroundColor,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
