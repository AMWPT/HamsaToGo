import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

enum HamsaButtonStyle { primary, secondary, ghost, gold }

class HamsaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final HamsaButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const HamsaButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = HamsaButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 54,
  });

  @override
  State<HamsaButton> createState() => _HamsaButtonState();
}

class _HamsaButtonState extends State<HamsaButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  void _onTapDown(_) {
    setState(() => _pressed = true);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) {
    setState(() => _pressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (widget.style) {
      HamsaButtonStyle.primary => (
          HamsaColors.greenAccent,
          HamsaColors.bgDeep,
          Colors.transparent
        ),
      HamsaButtonStyle.secondary => (
          HamsaColors.bgElevated,
          HamsaColors.cream,
          HamsaColors.borderStrong
        ),
      HamsaButtonStyle.ghost => (
          Colors.transparent,
          HamsaColors.greenAccent,
          HamsaColors.greenAccent
        ),
      HamsaButtonStyle.gold => (
          HamsaColors.gold,
          HamsaColors.bgDeep,
          Colors.transparent
        ),
    };

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: widget.onTap == null ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(color: border, width: 1.5),
              boxShadow: widget.style == HamsaButtonStyle.primary
                  ? [
                      BoxShadow(
                        color: HamsaColors.greenAccent.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : widget.style == HamsaButtonStyle.gold
                      ? [
                          BoxShadow(
                            color: HamsaColors.gold.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
            ),
            child: widget.isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: fg, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: HamsaText.body(
                          size: 15,
                          weight: FontWeight.w600,
                          color: fg,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
