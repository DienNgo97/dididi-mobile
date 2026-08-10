import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import 'trip_models.dart';
import 'trip_repository.dart';

const _brand = AppTheme.brand;

class _GuideMsg {
  final String text;
  final bool me;
  final String? source; // 'kb' | 'llm' — hiện nhãn nguồn trả lời
  final List<String> suggests;
  _GuideMsg(this.text, {this.me = false, this.source, this.suggests = const []});
}

/// AI HƯỚNG DẪN VIÊN DU LỊCH (bản mobile của trang web /trip-guide).
/// Hỏi tự do: lịch trình theo giờ, đi lại, ăn uống, ngân sách, thời tiết, đồ mang theo...
/// Backend hybrid: tri thức nội bộ 12 thành phố → LLM (nếu bật) → gợi ý câu hỏi tiếp theo.
/// Endpoint permitAll nên KHÁCH chưa đăng nhập vẫn dùng được.
class TripGuideScreen extends ConsumerStatefulWidget {
  const TripGuideScreen({super.key});
  @override
  ConsumerState<TripGuideScreen> createState() => _TripGuideScreenState();
}

class _TripGuideScreenState extends ConsumerState<TripGuideScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<_GuideMsg> _msgs = [
    _GuideMsg(trg('trip.guideGreeting'), suggests: _starters),
  ];
  bool _sending = false;

  /// Câu hỏi mở đầu (dịch theo ngôn ngữ đang chọn).
  List<String> get _starters => [
        trg('trip.guideStarter1'),
        trg('trip.guideStarter2'),
        trg('trip.guideStarter3'),
        trg('trip.guideStarter4'),
      ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _msgs.add(_GuideMsg(q, me: true));
      _sending = true;
    });
    _scrollDown();
    try {
      final TripGuideAnswer a = await ref.read(tripRepositoryProvider).guide(q);
      setState(() => _msgs.add(_GuideMsg(a.answer, source: a.source, suggests: a.suggests)));
    } catch (_) {
      setState(() => _msgs.add(_GuideMsg(trg('trip.guideFailed'))));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const CircleAvatar(
              radius: 13,
              backgroundColor: _brand,
              child: Icon(Icons.travel_explore, size: 16, color: Colors.white)),
          const SizedBox(width: 8),
          Text(trg('trip.guideTitle')),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: _msgs.length + (_sending ? 1 : 0),
              itemBuilder: (_, i) => i >= _msgs.length ? _typing() : _bubble(_msgs[i]),
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(_GuideMsg m) {
    final bg = m.me ? _brand : AppTheme.bg;
    final fg = m.me ? Colors.white : AppTheme.ink;
    return Column(
      crossAxisAlignment: m.me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(m.me ? 14 : 4),
              bottomRight: Radius.circular(m.me ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lịch trình trả về nhiều dòng (mốc giờ) — giữ nguyên xuống dòng của backend.
              Text(m.text, style: TextStyle(color: fg, height: 1.4, fontSize: 14)),
              if (!m.me && m.source == 'llm') ...[
                const SizedBox(height: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome, size: 13, color: AppTheme.muted),
                  const SizedBox(width: 4),
                  Text(trg('trip.guideByAi'),
                      style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                ]),
              ],
            ],
          ),
        ),
        // Câu hỏi gợi ý tiếp theo: bấm để hỏi ngay.
        if (!m.me && m.suggests.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in m.suggests)
                  InkWell(
                    onTap: _sending ? null : () => _send(s),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.line),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s,
                          style: const TextStyle(color: _brand, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _typing() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(14)),
          child: const SizedBox(
            width: 34,
            child: Text('•••',
                style: TextStyle(color: AppTheme.muted, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),
        ),
      );

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: trg('trip.guideInputHint'),
                filled: true,
                fillColor: AppTheme.bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            onPressed: _sending ? null : () => _send(_input.text),
            style: IconButton.styleFrom(backgroundColor: _brand, foregroundColor: Colors.white),
            icon: const Icon(Icons.send, size: 20),
          ),
        ]),
      ),
    );
  }
}
