import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import 'social_controller.dart';
import 'social_repository.dart';

const _brand = Color(0xFF2F8B60);

/// Soạn & đăng bài: nội dung + ảnh + quyền xem.
class ComposePostScreen extends ConsumerStatefulWidget {
  const ComposePostScreen({super.key});
  @override
  ConsumerState<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends ConsumerState<ComposePostScreen> {
  final _c = TextEditingController();
  final _hotelC = TextEditingController();
  final List<XFile> _photos = [];
  XFile? _video;
  String _visibility = 'PUBLIC';
  bool _checkin = false;
  bool _busy = false;
  String _postAs = 'self'; // 'self' | 'hotel:{id}'

  @override
  void dispose() {
    _c.dispose();
    _hotelC.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) setState(() => _photos.addAll(picked));
  }

  Future<void> _pickVideo() async {
    final v = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (v != null) setState(() => _video = v);
  }

  Future<void> _post() async {
    final caption = _c.text.trim();
    if (caption.isEmpty && _photos.isEmpty && _video == null) return _snack(trg('social.composeEmpty'));
    setState(() => _busy = true);
    try {
      final files = <MultipartFile>[];
      for (final x in _photos) {
        files.add(MultipartFile.fromBytes(await x.readAsBytes(), filename: x.name));
      }
      if (_video != null) {
        files.add(MultipartFile.fromBytes(await _video!.readAsBytes(),
            filename: _video!.name.isEmpty ? 'video.mp4' : _video!.name));
      }
      await ref.read(socialRepositoryProvider).createPost(
            caption,
            files: files,
            visibility: _visibility,
            hotelKeyword: _hotelC.text.trim(),
            // Check-in chỉ có nghĩa khi có gắn thẻ khách sạn.
            checkin: _checkin && _hotelC.text.trim().isNotEmpty,
            postAs: _postAs,
          );
      ref.invalidate(feedProvider);
      if (mounted) {
        Navigator.of(context).pop();
        _snack(trg('social.posted'));
      }
    } catch (e) {
      if (mounted) _snack(trg('social.postFailed').replaceAll('{err}', '$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(trg('social.compose')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SizedBox(
              width: 92,
              child: FilledButton(
                onPressed: _busy ? null : _post,
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                child: _busy
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(trg('social.publish')),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _postAsSelector(),
          TextField(
            controller: _c,
            autofocus: true,
            minLines: 4,
            maxLines: null,
            decoration: InputDecoration(
              hintText: trg('social.composeHint'),
            ),
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _thumb(i),
              ),
            ),
          ],
          if (_video != null) ...[
            const SizedBox(height: 12),
            _videoChip(),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(trg('social.addPhoto')),
            ),
            OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.videocam_outlined, size: 18),
              label: Text(_video == null ? trg('social.addVideo') : trg('social.changeVideo')),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _hotelC,
            decoration: InputDecoration(
              labelText: trg('social.tagHotel'),
              hintText: trg('social.tagHotelHint'),
              prefixIcon: const Icon(Icons.location_on_outlined, color: _brand),
              isDense: true,
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.where_to_vote_outlined, color: _brand),
            title: Text(trg('social.checkinTitle')),
            subtitle: Text(trg('social.checkinSub')),
            value: _checkin,
            onChanged: (v) => setState(() => _checkin = v),
          ),
          const SizedBox(height: 12),
          SectionHeader(trg('social.visibility')),
          Wrap(spacing: 8, children: [
            _visChip('PUBLIC', trg('social.visPublic'), Icons.public),
            _visChip('FOLLOWERS', trg('social.followers'), Icons.group),
            _visChip('PRIVATE', trg('social.visPrivate'), Icons.lock),
          ]),
        ],
      ),
    );
  }

  /// Bộ chọn "Đăng như" — chỉ hiện khi tài khoản sở hữu khách sạn (vendor).
  Widget _postAsSelector() {
    final hotels = ref.watch(myHotelsProvider).asData?.value ?? const <({int id, String name})>[];
    if (hotels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(trg('social.postAs')),
        Wrap(spacing: 8, runSpacing: 4, children: [
          ChoiceChip(
            selected: _postAs == 'self',
            onSelected: (_) => setState(() => _postAs = 'self'),
            avatar: Icon(Icons.person, size: 16, color: _postAs == 'self' ? Colors.white : _brand),
            label: Text(trg('social.postAsMe')),
            selectedColor: _brand,
            labelStyle: TextStyle(color: _postAs == 'self' ? Colors.white : AppTheme.ink),
          ),
          for (final h in hotels)
            ChoiceChip(
              selected: _postAs == 'hotel:${h.id}',
              onSelected: (_) => setState(() => _postAs = 'hotel:${h.id}'),
              avatar: Icon(Icons.apartment,
                  size: 16, color: _postAs == 'hotel:${h.id}' ? Colors.white : _brand),
              label: Text(h.name),
              selectedColor: _brand,
              labelStyle: TextStyle(color: _postAs == 'hotel:${h.id}' ? Colors.white : AppTheme.ink),
            ),
        ]),
      ]),
    );
  }

  Widget _videoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(AppTheme.rControl),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(children: [
        const Icon(Icons.movie_creation_outlined, color: _brand),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_video?.name.isNotEmpty == true ? _video!.name : trg('social.videoSelected'),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          tooltip: trg('social.removeVideo'),
          onPressed: () => setState(() => _video = null),
        ),
      ]),
    );
  }

  Widget _thumb(int i) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<Uint8List>(
            future: _photos[i].readAsBytes(),
            builder: (_, snap) => snap.hasData
                ? Image.memory(snap.data!, width: 90, height: 90, fit: BoxFit.cover)
                : Container(width: 90, height: 90, color: AppTheme.brandSoft),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => setState(() => _photos.removeAt(i)),
            child: Container(
              decoration: const BoxDecoration(color: Color(0xCC000000), shape: BoxShape.circle),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _visChip(String value, String label, IconData icon) {
    final active = _visibility == value;
    return ChoiceChip(
      selected: active,
      onSelected: (_) => setState(() => _visibility = value),
      avatar: Icon(icon, size: 16, color: active ? Colors.white : _brand),
      label: Text(label),
      selectedColor: _brand,
      labelStyle: TextStyle(color: active ? Colors.white : AppTheme.ink),
    );
  }
}
