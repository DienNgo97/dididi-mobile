/// Lỗi API đã chuẩn hoá (từ envelope ErrorResponse {code,message} của backend).
class ApiException implements Exception {
  final String code;
  final String message;
  final int? status;

  ApiException(this.code, this.message, [this.status]);

  @override
  String toString() => message;
}
