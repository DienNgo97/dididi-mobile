import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import 'group_models.dart';
import 'group_repository.dart';

const _brand = AppTheme.brand;

/// Cờ "đang gửi" cho các thao tác GHI của nhóm (thêm phòng, thanh toán cả nhóm).
/// Chặn bấm chồng → tránh tạo phòng trùng / khởi tạo 2 phiên thanh toán.
final _groupBusyProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Bảng điều khiển nhóm: thành viên, tổng tiền, tham gia, đóng/mở, chia sẻ mã.
class GroupDashboardScreen extends ConsumerWidget {
  final String token;
  const GroupDashboardScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(groupDetailProvider(token));
    return Scaffold(
      appBar: AppBar(
        title: Text(trg('group.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: trg('group.share'),
            onPressed: () => _shareDialog(context),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(groupDetailProvider(token))),
        data: (d) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(groupDetailProvider(token)),
          child: _body(context, ref, d),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, GroupDetail d) {
    final g = d.group;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(g.displayTitle, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.ink, letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Text(g.hotelName, style: const TextStyle(color: AppTheme.muted)),
        if (g.checkIn != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('${g.checkIn} → ${g.checkOut ?? ''}', style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
          ),
        const SizedBox(height: 10),
        Row(children: [
          if (g.organizer) _chip(trg('group.organizer'), _brand),
          if (d.closed) _chip(trg('group.closed'), Colors.orange),
          if (g.ended) _chip(trg('group.ended'), AppTheme.muted),
        ]),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: [
              _stat('${d.memberCount}', trg('group.members')),
              _stat('${d.paidCount}', trg('group.paid')),
              _stat(formatVnd(d.totalAll), trg('common.total')),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(trg('group.members')),
        if (d.members.isEmpty)
          Text(trg('group.noRooms'), style: const TextStyle(color: AppTheme.muted))
        else
          for (final m in d.members) _memberTile(context, ref, d, m),
        const SizedBox(height: 20),
        if (d.joinable)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: ref.watch(_groupBusyProvider) ? null : () => _join(context, ref, d),
              icon: const Icon(Icons.add),
              label: Text(trg('group.joinAddRoom')),
            ),
          ),
        if (g.organizer && d.members.any((m) => !m.paid)) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3A5BA0)),
              onPressed: ref.watch(_groupBusyProvider) ? null : () => _payGroup(context, ref, d),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text(trg('group.payAll')),
            ),
          ),
        ],
        if (g.organizer) ...[
          const SizedBox(height: 16),
          SectionHeader(trg('group.manage')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: () => _toggleClose(context, ref, d),
              icon: Icon(d.closed ? Icons.lock_open : Icons.lock_outline, size: 18),
              label: Text(d.closed ? trg('group.reopen') : trg('group.close')),
            ),
            OutlinedButton.icon(
              onPressed: () => _editGroup(context, ref, d),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(trg('group.edit')),
            ),
            OutlinedButton.icon(
              onPressed: () => _toggleEndTrip(context, ref, d),
              icon: Icon(g.ended ? Icons.replay : Icons.flag_outlined, size: 18),
              label: Text(g.ended ? trg('group.reopenTrip') : trg('group.endTrip')),
            ),
            if (g.ended)
              OutlinedButton.icon(
                onPressed: () => _settlement(context, ref),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: Text(trg('group.settlement')),
              ),
          ]),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _shareDialog(context),
          icon: const Icon(Icons.qr_code_2),
          label: Text(trg('group.inviteViaQr').replaceAll('{v}', g.token)),
        ),
      ],
    );
  }

  Widget _memberTile(BuildContext context, WidgetRef ref, GroupDetail d, GroupMember m) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.rControl),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.brandSoft,
              child: Text(m.name.isNotEmpty ? m.name[0].toUpperCase() : '?', style: const TextStyle(color: _brand, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${m.name}${m.mine ? trg('group.you') : ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.ink)),
                Text(trg('group.roomsAmount').replaceAll('{a}', '${m.rooms}').replaceAll('{b}', formatVnd(m.amount)), style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              ]),
            ),
            StatusBadge(m.paid ? trg('group.paid') : trg('group.pending'), m.paid ? _brand : AppTheme.amber),
            if (d.group.organizer)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.black45),
                onSelected: (v) {
                  if (v == 'room') _deleteRoom(context, ref, m);
                  if (v == 'member') _removeMember(context, ref, m);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'room', child: Text(trg('group.deleteRoomItem'))),
                  if (!m.mine && m.userId != null)
                    PopupMenuItem(value: 'member', child: Text(trg('group.removeMember'))),
                ],
              ),
          ],
        ),
      );

  Widget _chip(String label, Color color) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: StatusBadge(label, color),
      );

  Widget _stat(String value, String label) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _brand)),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
        ]),
      );

  void _shareDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('group.inviteTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(data: token, backgroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(trg('group.groupCode'), style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
            SelectableText(token, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _brand)),
            const SizedBox(height: 6),
            Text(trg('group.shareHint'),
                textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('group.codeCopied'))));
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(trg('group.copyCode')),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(trg('common.done'))),
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, WidgetRef ref, GroupDetail d) async {
    int? roomTypeId = d.roomTypes.isNotEmpty ? d.roomTypes.first.id : null;
    int rooms = 1;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(trg('group.addMyRoom')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d.roomTypes.isNotEmpty) ...[
                Text(trg('group.roomType'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButton<int>(
                  isExpanded: true,
                  value: roomTypeId,
                  items: [
                    for (final r in d.roomTypes)
                      DropdownMenuItem(value: r.id, child: Text('${r.name} · ${formatVnd(r.basePrice)}')),
                  ],
                  onChanged: (v) => setS(() => roomTypeId = v),
                ),
                const SizedBox(height: 12),
              ],
              Row(children: [
                Text(trg('group.roomCount'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton.outlined(onPressed: rooms > 1 ? () => setS(() => rooms--) : null, icon: const Icon(Icons.remove)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('$rooms', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton.outlined(onPressed: () => setS(() => rooms++), icon: const Icon(Icons.add)),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('group.add'))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (ref.read(_groupBusyProvider)) return; // đang có lệnh ghi -> bỏ qua lần bấm chồng
    ref.read(_groupBusyProvider.notifier).state = true;
    try {
      await ref.read(groupRepositoryProvider).join(token, roomTypeId: roomTypeId, rooms: rooms);
      ref.invalidate(groupDetailProvider(token));
      messenger.showSnackBar(SnackBar(content: Text(trg('group.roomAdded'))));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(trg('group.addRoomFailed'))));
    } finally {
      ref.read(_groupBusyProvider.notifier).state = false;
    }
  }

  Future<void> _toggleClose(BuildContext context, WidgetRef ref, GroupDetail d) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (d.closed) {
        await ref.read(groupRepositoryProvider).reopen(token);
      } else {
        await ref.read(groupRepositoryProvider).close(token);
      }
      ref.invalidate(groupDetailProvider(token));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(trg('common.error'))));
    }
  }

  /// Nhận sẵn [messenger] thay vì BuildContext: hàm này hầu hết được gọi SAU khi một
  /// hộp thoại đóng, lúc đó màn hình có thể đã bị huỷ và `ScaffoldMessenger.of(context)`
  /// sẽ ném lỗi. Bên gọi lấy messenger TRƯỚC khi mở hộp thoại — nó thuộc MaterialApp
  /// nên vẫn sống kể cả khi route bị pop, snackbar vẫn hiện được.
  Future<void> _run(ScaffoldMessengerState messenger, WidgetRef ref, Future<void> Function() action, String okMsg) async {
    try {
      await action();
      ref.invalidate(groupDetailProvider(token));
      messenger.showSnackBar(SnackBar(content: Text(okMsg)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(trg('common.error'))));
    }
  }

  Future<void> _editGroup(BuildContext context, WidgetRef ref, GroupDetail d) async {
    final messenger = ScaffoldMessenger.of(context);
    final nameC = TextEditingController(text: d.group.title ?? '');
    bool splitEven = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(trg('group.edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: InputDecoration(labelText: trg('group.titleLabel'), border: const OutlineInputBorder())),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(trg('group.splitEven')),
                subtitle: Text(trg('group.splitEvenSub')),
                value: splitEven,
                onChanged: (v) => setS(() => splitEven = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.save'))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _run(messenger, ref, () => ref.read(groupRepositoryProvider).editGroup(token, title: nameC.text.trim(), splitEven: splitEven), trg('group.updated'));
  }

  Future<void> _toggleEndTrip(BuildContext context, WidgetRef ref, GroupDetail d) async {
    final messenger = ScaffoldMessenger.of(context);
    if (d.group.ended) {
      await _run(messenger, ref, () => ref.read(groupRepositoryProvider).reopenTrip(token), trg('group.tripReopened'));
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(trg('group.endTripConfirm')),
          content: Text(trg('group.endTripBody')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('group.end'))),
          ],
        ),
      );
      if (ok != true) return;
      await _run(messenger, ref, () => ref.read(groupRepositoryProvider).endTrip(token), trg('group.tripEnded'));
    }
  }

  Future<void> _payGroup(BuildContext context, WidgetRef ref, GroupDetail d) async {
    final messenger = ScaffoldMessenger.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('group.payAllConfirm')),
        content: Text(trg('group.payAllBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.next'))),
        ],
      ),
    );
    if (go != true) return;
    String payUrl;
    num total;
    if (ref.read(_groupBusyProvider)) return; // chặn tạo 2 phiên thanh toán nhóm song song
    ref.read(_groupBusyProvider.notifier).state = true;
    try {
      final r = await ref.read(groupRepositoryProvider).payGroup(token);
      payUrl = r.payUrl;
      total = r.total;
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(trg('group.payLinkFailed'))));
      return;
    } finally {
      ref.read(_groupBusyProvider.notifier).state = false;
    }
    if (payUrl.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(trg('group.nothingToPay'))));
      return;
    }
    final opened = await launchUrl(Uri.parse(payUrl), mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(trg('group.vnpayFailed'))));
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('group.payAllTitle')),
        content: Text(trg('group.payAllDone').replaceAll('{v}', formatVnd(total))),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(trg('common.done')))],
      ),
    );
    ref.invalidate(groupDetailProvider(token));
  }

  Future<void> _settlement(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await ref.read(groupRepositoryProvider).settlementBytes(token);
      final uri = Uri.dataFromBytes(Uint8List.fromList(bytes), mimeType: 'application/pdf');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(trg('group.settlementFailed'))));
    }
  }

  Future<void> _deleteRoom(BuildContext context, WidgetRef ref, GroupMember m) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('group.deleteRoomConfirm')),
        content: Text(trg('group.deleteRoomBody').replaceAll('{a}', m.name).replaceAll('{b}', m.bookingCode)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await _run(messenger, ref, () => ref.read(groupRepositoryProvider).deleteRoom(token, m.bookingCode), trg('group.roomDeleted'));
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref, GroupMember m) async {
    if (m.userId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('group.removeMemberConfirm')),
        content: Text(trg('group.removeMemberBody').replaceAll('{v}', m.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await _run(messenger, ref, () => ref.read(groupRepositoryProvider).removeMember(token, m.userId!), trg('group.memberRemoved'));
  }
}
