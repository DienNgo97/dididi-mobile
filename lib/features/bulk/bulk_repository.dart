import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_providers.dart';
import 'bulk_models.dart';

final bulkRepositoryProvider =
    Provider<BulkRepository>((ref) => BulkRepository(ref.watch(apiClientProvider)));

class BulkRepository {
  final ApiClient _api;
  BulkRepository(this._api);

  /// Đặt hàng loạt: nhiều khách, cùng khách sạn/loại phòng.
  /// [dayUse]=true → đặt theo giờ trong ngày (gửi date/timeIn/timeOut HH:mm).
  Future<List<BulkLineResult>> createHotelBulk({
    required int hotelId,
    required int roomTypeId,
    String? roomName,
    required String checkIn, // với day-use dùng làm 'date'
    required String checkOut,
    required List<Map<String, dynamic>> guests, // [{name, rooms}]
    bool dayUse = false,
    String? timeIn,
    String? timeOut,
  }) =>
      _api.postData(
        '/api/v1/bulk/hotel',
        body: {
          'hotelId': hotelId,
          'roomTypeId': roomTypeId,
          if (roomName != null) 'roomName': roomName,
          'stay': dayUse ? 'day' : 'overnight',
          if (dayUse) ...{
            'date': checkIn,
            'timeIn': timeIn ?? '09:00',
            'timeOut': timeOut ?? '13:00',
          } else ...{
            'checkIn': checkIn,
            'checkOut': checkOut,
          },
          'guests': guests,
        },
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => BulkLineResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
