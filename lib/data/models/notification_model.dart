import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String icon; // emoji
  final Color iconBg;
  final String title;
  final String message;
  final String timeLabel; // "2 giờ trước"
  final bool unread;
  final String group; // "Hôm nay" | "Trước đó"

  const AppNotification({
    required this.id,
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.unread = false,
    required this.group,
  });
}
