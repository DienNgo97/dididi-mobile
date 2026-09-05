import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/actor_avatar.dart';
import '../../shared/widgets/error_view.dart';
import 'social_controller.dart';
import 'social_repository.dart';

/// Tạo nhóm chat mới, hoặc thêm thành viên vào nhóm đang mở khi [convId] != null.
///
/// Danh sách chỉ có người THEO DÕI QUA LẠI — backend chặn mời người lạ, nên bày họ ra
/// chỉ tổ để người dùng chọn xong rồi ăn lỗi.
class GroupNewScreen extends ConsumerStatefulWidget {
  const GroupNewScreen({super.key, this.convId, this.groupName});

  final int? convId;
  final String? groupName;

  @override
  ConsumerState<GroupNewScreen> createState() => _GroupNewScreenState();
}

class _GroupNewScreenState extends ConsumerState<GroupNewScreen> {
  final _title = TextEditingController();
  final _search = TextEditingController();
  final _picked = <int, String>{};   // userId -> tên, giữ lại khi đổi từ khoá tìm
  String _q = '';
  bool _busy = false;
  Timer? _debounce;   // moi phim go la 1 request neu khong cho no lang xuong

  bool get _isAdd => widget.convId != null;

  @override
  void dispose() {
    _debounce?.cancel();
    _title.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _q = v.trim());
    });
  }

  Future<void> _submit() async {
    if (_picked.isEmpty) {
      _snack(trg('dm.pickOne'));
      return;
    }
    final title = _title.text.trim();
    if (!_isAdd && title.isEmpty) {
      _snack(trg('dm.needGroupName'));
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(socialRepositoryProvider);
    try {
      if (_isAdd) {
        await repo.addMembers(widget.convId!, _picked.keys.toList());
        if (!mounted) return;                       // roi man giua chung -> ref da bi huy
        ref.invalidate(groupInfoProvider(widget.convId!));
        ref.invalidate(conversationMessagesProvider(widget.convId!));
        Navigator.pop(context, true);
      } else {
        final id = await repo.createGroup(title, _picked.keys.toList());
        if (!mounted) return;
        ref.invalidate(dmInboxProvider);
        context.pushReplacement('/dm/$id', extra: title);
      }
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(invitableFriendsProvider((convId: widget.convId ?? 0, q: _q)));
    return Scaffold(
      appBar: AppBar(title: Text(trg(_isAdd ? 'dm.addMember' : 'dm.newGroup'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isAdd)
                  TextField(
                    controller: _title,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: trg('dm.groupName'),
                      hintText: trg('dm.groupNamePh'),
                      counterText: '',
                    ),
                  )
                else if (widget.groupName != null)
                  Text(widget.groupName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: trg('dm.searchPeople'),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 6),
                Text(trg('dm.mutualOnly'), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                if (_picked.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in _picked.entries)
                        Chip(
                          label: Text(e.value),
                          onDeleted: () => setState(() => _picked.remove(e.key)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SoftDivider(),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(invitableFriendsProvider((convId: widget.convId ?? 0, q: _q))),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.group_outlined,
                    title: trg('dm.noMutual'),
                    message: trg('dm.noMutualMsg'),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final a = list[i];
                    final id = a.id;
                    if (id == null) return const SizedBox.shrink();
                    final on = _picked.containsKey(id);
                    return CheckboxListTile(
                      value: on,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _picked[id] = a.name;
                        } else {
                          _picked.remove(id);
                        }
                      }),
                      secondary: ActorAvatar(a, size: 40),
                      title: Text(a.name),
                      subtitle: a.handle != null ? Text('@${a.handle}') : null,
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy
                      ? trg('common.saving')
                      : trg(_isAdd ? 'dm.addMember' : 'dm.createGroup')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
