import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/design_system/widgets/state_badge.dart';
import 'package:uuid/uuid.dart';

export 'package:otune/core/design_system/widgets/state_badge.dart';

final badgeProvider = NotifierProvider<BadgeNotifier, List<BadgeItem>>(
  BadgeNotifier.new,
);

class BadgeItem {
  const BadgeItem({
    required this.id,
    required this.message,
    required this.duration,
    this.type = BadgeType.info,
    this.backgroundColor,
    this.textColor,
    this.onDismissed,
    this.actionLabel,
    this.onActionPressed,
  });

  final String id;
  final String message;
  final BadgeType type;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration duration;
  final VoidCallback? onDismissed;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
}

class BadgeNotifier extends Notifier<List<BadgeItem>> {
  final Map<String, Timer> _timers = {};

  @override
  List<BadgeItem> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return [];
  }

  void show({
    required String message,
    BadgeType type = BadgeType.info,
    Color? backgroundColor,
    Color? textColor,
    Duration? duration,
    VoidCallback? onDismissed,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final duration_ = duration ?? const Duration(seconds: 3);
    final id = Uuid().v4();
    final item = BadgeItem(
      id: id,
      message: message,
      type: type,
      backgroundColor: backgroundColor,
      textColor: textColor,
      duration: duration_,
      onDismissed: onDismissed,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );

    state = [...state, item];

    _timers[id] = Timer(duration_, () {
      dismiss(id);
    });
  }

  void dismiss(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    state = state.where((item) => item.id != id).toList();
  }

  void dismissAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    state = [];
  }
}
