import 'dart:io';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';

/// Android/iOS: ghi bytes ra file tạm rồi phát (media cần JWT nên tải bytes qua ApiClient trước).
Future<VideoPlayerController> controllerFromBytes(Uint8List bytes, String contentType) async {
  final ext = contentType.contains('quicktime') || contentType.contains('mov')
      ? 'mov'
      : contentType.contains('webm')
          ? 'webm'
          : 'mp4';
  final f = File('${Directory.systemTemp.path}/dididi_vid_${DateTime.now().microsecondsSinceEpoch}.$ext');
  await f.writeAsBytes(bytes, flush: true);
  return VideoPlayerController.file(f);
}
