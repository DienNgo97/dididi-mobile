import 'dart:html' as html;
import 'dart:typed_data';

import 'package:video_player/video_player.dart';

/// Web: bọc bytes vào Blob URL rồi phát (media cần JWT nên không thể trỏ URL trực tiếp).
Future<VideoPlayerController> controllerFromBytes(Uint8List bytes, String contentType) async {
  final blob = html.Blob(<Uint8List>[bytes], contentType.isEmpty ? 'video/mp4' : contentType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  return VideoPlayerController.networkUrl(Uri.parse(url));
}
