import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ảnh đại diện: URL mạng (Google/Cloudinary), đường dẫn file cục bộ (mock),
/// hoặc placeholder người dùng khi chưa có ảnh.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  const UserAvatar({super.key, this.photoUrl, this.radius = 30});

  @override
  Widget build(BuildContext context) {
    final p = photoUrl;
    ImageProvider? img;
    if (p != null && p.isNotEmpty) {
      img = p.startsWith('http')
          ? CachedNetworkImageProvider(p)
          : FileImage(File(p)); // mock: đường dẫn file cục bộ
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.inputFill,
      backgroundImage: img,
      child: img == null
          ? Icon(Icons.person, color: AppColors.bodyText, size: radius)
          : null,
    );
  }
}
