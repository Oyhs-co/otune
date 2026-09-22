import 'dart:async';

import 'package:flutter/material.dart';

enum BadgeType { info, success, error, loading }

class StateBadge extends StatefulWidget {
  const StateBadge({
    required this.message,
    this.type = BadgeType.info,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
    this.actionLabel,
    this.onActionPressed,
    super.key,
  });

  final String message;
  final BadgeType type;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration duration;
  final VoidCallback? onDismissed;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  State<StateBadge> createState() => _StateBadgeState();
}

class _StateBadgeState extends State<StateBadge> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    // La caducidad la programa el notificador que emite el badge:
    // este widget no mantiene temporizadores propios.
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _visible = false);
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIcon = widget.icon ?? _iconForType(widget.type);
    final resolvedBgColor =
        widget.backgroundColor ?? _backgroundColorForType(widget.type, theme);
    final resolvedTextColor =
        widget.textColor ?? _textColorForType(widget.type, theme);

    return _AnimatedBadge(
      visible: _visible,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: resolvedBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.type == BadgeType.loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: resolvedTextColor,
                ),
              )
            else
              Icon(resolvedIcon, color: resolvedTextColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  color: resolvedTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (widget.actionLabel != null)
              TextButton(
                onPressed: () {
                  widget.onActionPressed?.call();
                  _dismiss();
                },
                child: Text(
                  widget.actionLabel!,
                  style: TextStyle(
                    color: resolvedTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(BadgeType type) {
    switch (type) {
      case BadgeType.success:
        return Icons.check_circle_rounded;
      case BadgeType.error:
        return Icons.error_outline_rounded;
      case BadgeType.loading:
        return Icons.info_rounded;
      case BadgeType.info:
        return Icons.info_rounded;
    }
  }

  Color _backgroundColorForType(BadgeType type, ThemeData theme) {
    switch (type) {
      case BadgeType.success:
        return theme.colorScheme.primaryContainer;
      case BadgeType.error:
        return theme.colorScheme.errorContainer;
      case BadgeType.loading:
        return theme.colorScheme.primaryContainer;
      case BadgeType.info:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  Color _textColorForType(BadgeType type, ThemeData theme) {
    switch (type) {
      case BadgeType.success:
        return theme.colorScheme.onPrimaryContainer;
      case BadgeType.error:
        return theme.colorScheme.onErrorContainer;
      case BadgeType.loading:
        return theme.colorScheme.onPrimaryContainer;
      case BadgeType.info:
        return theme.colorScheme.onSurface;
    }
  }
}

class _AnimatedBadge extends StatefulWidget {
  const _AnimatedBadge({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    unawaited(widget.visible ? _controller.forward() : _controller.reverse());
  }

  @override
  void didUpdateWidget(covariant _AnimatedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _controller.forward();
    } else if (!widget.visible && oldWidget.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
