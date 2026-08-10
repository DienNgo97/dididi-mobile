import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const _brand = Color(0xFF2F8B60);

/// Hiển thị caption; biến #hashtag và (tuỳ chọn) @mention thành liên kết bấm được.
class HashtagText extends StatefulWidget {
  final String text;
  final void Function(String tag) onTapTag;
  final void Function(String handle)? onTapMention;
  final TextStyle? style;
  final int? maxLines;
  const HashtagText(this.text, {super.key, required this.onTapTag, this.onTapMention, this.style, this.maxLines});

  @override
  State<HashtagText> createState() => _HashtagTextState();
}

class _HashtagTextState extends State<HashtagText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final base = widget.style ?? const TextStyle(fontSize: 14, color: Colors.black87, height: 1.35);
    final link = base.copyWith(color: _brand, fontWeight: FontWeight.w600);
    final spans = <InlineSpan>[];
    final re = RegExp(r'([#@])([\p{L}0-9_]+)', unicode: true);
    final wordish = RegExp(r'[\p{L}\p{N}_@#]', unicode: true);
    int last = 0;
    for (final m in re.allMatches(widget.text)) {
      if (m.start > last) spans.add(TextSpan(text: widget.text.substring(last, m.start), style: base));
      final sym = m.group(1)!;
      final word = m.group(2)!;
      // Chỉ coi là hashtag/mention khi đứng đầu hoặc sau khoảng trắng/dấu câu —
      // tránh biến "john@gmail" hay "a#b" trong 1 từ/email thành liên kết.
      final boundaryOk = m.start == 0 || !wordish.hasMatch(widget.text[m.start - 1]);
      if (!boundaryOk) {
        spans.add(TextSpan(text: '$sym$word', style: base));
        last = m.end;
        continue;
      }
      if (sym == '#') {
        final rec = TapGestureRecognizer()..onTap = () => widget.onTapTag(word);
        _recognizers.add(rec);
        spans.add(TextSpan(text: '#$word', style: link, recognizer: rec));
      } else if (widget.onTapMention != null) {
        final rec = TapGestureRecognizer()..onTap = () => widget.onTapMention!(word);
        _recognizers.add(rec);
        spans.add(TextSpan(text: '@$word', style: link, recognizer: rec));
      } else {
        spans.add(TextSpan(text: '@$word', style: base));
      }
      last = m.end;
    }
    if (last < widget.text.length) spans.add(TextSpan(text: widget.text.substring(last), style: base));

    return Text.rich(
      TextSpan(children: spans),
      maxLines: widget.maxLines,
      overflow: widget.maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
