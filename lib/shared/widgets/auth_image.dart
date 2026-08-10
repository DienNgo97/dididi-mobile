import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_providers.dart';

/// Ảnh yêu cầu JWT (media MXH): tải bytes qua ApiClient (tự gắn token) rồi Image.memory.
/// Cache theo path nhờ FutureProvider.family.
final imageBytesProvider = FutureProvider.family<Uint8List, String>((ref, path) async {
  final api = ref.read(apiClientProvider);
  final bytes = await api.getBytes(path);
  return Uint8List.fromList(bytes);
});

class AuthImage extends ConsumerWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;
  const AuthImage(this.path,
      {super.key, this.width, this.height, this.fit = BoxFit.cover, this.radius});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(imageBytesProvider(path));
    Widget ph(IconData? icon) => Container(
          width: width,
          height: height,
          color: const Color(0xFFEDEFEE),
          child: icon == null ? null : Icon(icon, color: Colors.black26),
        );
    Widget child = async.when(
      loading: () => ph(null),
      error: (_, __) => ph(Icons.broken_image_outlined),
      data: (bytes) =>
          bytes.isEmpty ? ph(Icons.image_outlined) : Image.memory(bytes, width: width, height: height, fit: fit),
    );
    if (radius != null) child = ClipRRect(borderRadius: radius!, child: child);
    return child;
  }
}
