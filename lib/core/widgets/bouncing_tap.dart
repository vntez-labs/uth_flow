import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tiện ích phản hồi xúc giác (Haptic Feedback) chuẩn trải nghiệm người dùng cao cấp
class AppHaptics {
  /// Rung nhẹ khi chạm nút, thẻ, tab navigation (Light Impact)
  static void light() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Rung xác nhận khi chọn giá trị, tick chọn ngày (Selection Click)
  static void selection() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Rung vừa khi mở modal, giữ lâu (Medium Impact)
  static void medium() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Rung thông báo thao tác thành công hoặc cảnh báo (Heavy Impact)
  static void heavy() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}

/// Widget bọc tương tác (Micro-interaction wrapper):
/// - Co giãn đàn hồi khi chạm (Scale bounce)
/// - Mờ nhẹ tạo cảm giác bấm vật lý (Opacity feedback)
/// - Rung điện thoại phản hồi xúc giác (Haptic feedback)
class BouncingTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final double opacityFactor;
  final Duration duration;
  final Duration reverseDuration;
  final HitTestBehavior behavior;
  final bool enableHaptic;

  const BouncingTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.95,
    this.opacityFactor = 0.88,
    this.duration = const Duration(milliseconds: 90),
    this.reverseDuration = const Duration(milliseconds: 140),
    this.behavior = HitTestBehavior.opaque,
    this.enableHaptic = true,
  });

  @override
  State<BouncingTap> createState() => _BouncingTapState();
}

class _BouncingTapState extends State<BouncingTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutQuad,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: widget.opacityFactor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutQuad,
      ),
    );
  }

  @override
  void didUpdateWidget(BouncingTap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleFactor != widget.scaleFactor) {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.scaleFactor,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeOutQuad,
        ),
      );
    }
    if (oldWidget.opacityFactor != widget.opacityFactor) {
      _opacityAnimation = Tween<double>(
        begin: 1.0,
        end: widget.opacityFactor,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeOutQuad,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (widget.enableHaptic) {
      AppHaptics.light();
    }
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress != null
          ? () {
              if (widget.enableHaptic) {
                AppHaptics.medium();
              }
              widget.onLongPress!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
