import 'package:flutter/material.dart';

import '../../features/social/social_models.dart';
import 'auth_image.dart';

/// Avatar chủ thể: dùng ảnh (JWT) nếu có, không thì hiển thị chữ cái đầu.
class ActorAvatar extends StatelessWidget {
  final Actor? actor;
  final double size;
  const ActorAvatar(this.actor, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final url = actor?.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(child: AuthImage(url, width: size, height: size));
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFCDE5D8),
      child: Text(actor?.initial ?? '?',
          style: TextStyle(color: const Color(0xFF2F8B60), fontWeight: FontWeight.w700, fontSize: size * 0.42)),
    );
  }
}
