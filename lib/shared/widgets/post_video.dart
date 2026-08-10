import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../features/auth/auth_providers.dart';
import 'video_source_stub.dart'
    if (dart.library.html) 'video_source_web.dart'
    if (dart.library.io) 'video_source_io.dart';

const _brand = Color(0xFF2F8B60);

/// Phát video của bài viết. Media cần JWT → tải bytes qua ApiClient rồi phát (blob trên web, file tạm trên mobile).
class PostVideo extends ConsumerStatefulWidget {
  final String path;
  final double? height;
  const PostVideo(this.path, {super.key, this.height});

  @override
  ConsumerState<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends ConsumerState<PostVideo> {
  VideoPlayerController? _ctrl;
  bool _loading = false;
  bool _error = false;
  bool _started = false;

  Future<void> _start() async {
    if (_started) return;
    setState(() {
      _started = true;
      _loading = true;
      _error = false;
    });
    try {
      final api = ref.read(apiClientProvider);
      final bytes = Uint8List.fromList(await api.getBytes(widget.path));
      final ctrl = await controllerFromBytes(bytes, 'video/mp4');
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.play();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _ctrl = ctrl;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
            _loading = false;
            _error = true;
          });
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? 240;
    final ctrl = _ctrl;
    if (ctrl != null && ctrl.value.isInitialized) {
      return GestureDetector(
        onTap: () => setState(() => ctrl.value.isPlaying ? ctrl.pause() : ctrl.play()),
        child: SizedBox(
          height: h,
          width: double.infinity,
          child: Stack(alignment: Alignment.center, children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: ctrl.value.size.width,
                height: ctrl.value.size.height,
                child: VideoPlayer(ctrl),
              ),
            ),
            if (!ctrl.value.isPlaying)
              const Icon(Icons.play_circle_fill, size: 56, color: Colors.white70),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(ctrl, allowScrubbing: true,
                  colors: const VideoProgressColors(playedColor: _brand)),
            ),
          ]),
        ),
      );
    }
    return GestureDetector(
      onTap: _error ? null : _start,
      child: Container(
        height: h,
        width: double.infinity,
        color: const Color(0xFF0E1512),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white70)
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_error ? Icons.videocam_off_outlined : Icons.play_circle_outline,
                      size: 54, color: Colors.white70),
                  const SizedBox(height: 6),
                  Text(_error ? 'Không phát được video' : 'Nhấn để phát video',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
        ),
      ),
    );
  }
}
