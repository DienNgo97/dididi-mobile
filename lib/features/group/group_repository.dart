import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_providers.dart';
import 'group_models.dart';

final groupRepositoryProvider =
    Provider<GroupRepository>((ref) => GroupRepository(ref.watch(apiClientProvider)));

final myGroupsProvider = FutureProvider<List<GroupSummary>>((ref) => ref.read(groupRepositoryProvider).myGroups());

final groupDetailProvider =
    FutureProvider.family<GroupDetail, String>((ref, token) => ref.read(groupRepositoryProvider).dashboard(token));

class GroupRepository {
  final ApiClient _api;
  GroupRepository(this._api);

  Future<List<GroupSummary>> myGroups() => _api.getData(
        '/api/v1/groups/me',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => GroupSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<GroupDetail> dashboard(String token) => _api.getData(
        '/api/v1/groups/$token',
        parse: (d) => GroupDetail.fromJson(d as Map<String, dynamic>),
      );

  Future<GroupSummary> create({
    required int hotelId,
    required int roomTypeId,
    String? roomName,
    required String checkIn,
    required String checkOut,
    String? title,
  }) =>
      _api.postData(
        '/api/v1/groups',
        body: {
          'hotelId': hotelId,
          'roomTypeId': roomTypeId,
          if (roomName != null) 'roomName': roomName,
          'checkIn': checkIn,
          'checkOut': checkOut,
          if (title != null) 'title': title,
        },
        parse: (d) => GroupSummary.fromJson(d as Map<String, dynamic>),
      );

  Future<String> join(String token, {int? roomTypeId, int rooms = 1}) => _api.postData(
        '/api/v1/groups/$token/join',
        body: {if (roomTypeId != null) 'roomTypeId': roomTypeId, 'rooms': rooms},
        parse: (d) => ((d as Map)['bookingCode'] ?? '').toString(),
      );

  Future<void> close(String token) => _api.postData<void>('/api/v1/groups/$token/close', parse: (_) {});
  Future<void> reopen(String token) => _api.postData<void>('/api/v1/groups/$token/reopen', parse: (_) {});

  // ---- Quyền trưởng nhóm ----
  Future<void> removeMember(String token, int memberUserId) =>
      _api.postData<void>('/api/v1/groups/$token/members/$memberUserId/remove', parse: (_) {});

  Future<void> deleteRoom(String token, String bookingCode) =>
      _api.postData<void>('/api/v1/groups/$token/rooms/$bookingCode/delete', parse: (_) {});

  Future<void> editGroup(String token, {String? title, bool? splitEven}) => _api.postData<void>(
        '/api/v1/groups/$token/edit',
        body: {if (title != null) 'title': title, if (splitEven != null) 'splitEven': splitEven},
        parse: (_) {},
      );

  Future<void> endTrip(String token) => _api.postData<void>('/api/v1/groups/$token/end', parse: (_) {});
  Future<void> reopenTrip(String token) => _api.postData<void>('/api/v1/groups/$token/reopen-trip', parse: (_) {});

  /// Hoá đơn chia tiền nhóm (PDF bytes) — chủ nhóm, sau khi kết thúc chuyến.
  Future<List<int>> settlementBytes(String token) => _api.getBytes('/api/v1/groups/$token/settlement');

  /// Thanh toán cho CẢ NHÓM 1 lần (chủ nhóm) → trả về link VNPay + tổng tiền.
  Future<({String payUrl, num total, int rooms})> payGroup(String token) => _api.postData(
        '/api/v1/groups/$token/pay-group',
        parse: (d) {
          final m = (d as Map);
          return (
            payUrl: (m['payUrl'] ?? '').toString(),
            total: (m['total'] ?? 0) as num,
            rooms: int.tryParse('${m['rooms'] ?? 0}') ?? 0,
          );
        },
      );
}
