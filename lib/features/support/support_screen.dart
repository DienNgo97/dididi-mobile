import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import 'support_models.dart';
import 'support_repository.dart';

const _brand = AppTheme.brand;
const _hotline = '1900 1234';

class _Msg {
  final String text;
  final bool me;
  final bool escalate;
  _Msg(this.text, {this.me = false, this.escalate = false});
}

/// Trợ lý CSKH "Trợ lý Dididi" — chat KB/LLM + gợi ý nhanh + gọi tổng đài.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});
  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _cid = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';
  final List<_Msg> _msgs = [
    _Msg(trg('support.greeting')),
  ];
  bool _sending = false;

  static const _quick = ['Huỷ đơn', 'Hoàn tiền', 'Đổi lịch', 'Thanh toán', 'Điểm thưởng'];

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
      _msgs.add(_Msg(q, me: true));
      _sending = true;
    });
    _scrollDown();
    try {
      final SupportAnswer a = await ref.read(supportRepositoryProvider).ask(q, _cid);
      setState(() => _msgs.add(_Msg(a.answer, escalate: a.escalate)));
    } catch (e) {
      setState(() => _msgs.add(_Msg(trg('support.connectFailed'), escalate: true)));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollDown();
    }
  }

  Future<void> _callHotline() async {
    final uri = Uri.parse('tel:${_hotline.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const CircleAvatar(radius: 13, backgroundColor: _brand, child: Icon(Icons.support_agent, size: 16, color: Colors.white)),
          const SizedBox(width: 8),
          Text(trg('support.title')),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: _msgs.length + (_sending ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= _msgs.length) return _typing();
                return _bubble(_msgs[i]);
              },
            ),
          ),
          _quickRow(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final bg = m.me ? _brand : AppTheme.bg;
    final fg = m.me ? Colors.white : AppTheme.ink;
    return Align(
      alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
            Text(m.text, style: TextStyle(color: fg, height: 1.35, fontSize: 14)),
            if (m.escalate) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: _callHotline,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: _brand, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.headset_mic, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(trg('support.callHotline').replaceAll('{v}', _hotline), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
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
            child: Text('•••', style: TextStyle(color: AppTheme.muted, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),
        ),
      );

  Widget _quickRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _quick.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => InkWell(
          onTap: _sending ? null : () => _send(_quick[i]),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_quick[i], style: const TextStyle(color: _brand, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

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
                hintText: trg('support.inputHint'),
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
