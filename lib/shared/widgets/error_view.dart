import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/utils/error_message.dart';

/// Khối báo lỗi dùng chung cho mọi màn hình.
///
/// Truyền [error] (đối tượng lỗi thô) chứ đừng tự gọi `e.toString()` rồi truyền
/// vào [message]: widget này sẽ tự dịch lỗi sang câu tiếng người đúng ngôn ngữ
/// qua [thongDiepLoi]. Trước ngày 24/08/2026 tất cả 44 nơi gọi đều truyền
/// `e.toString()`, nên khi mất mạng người dùng nhận nguyên văn tiếng Anh của
/// thư viện Dio. Gom việc dịch vào ĐÂY để không nơi nào phải nhớ làm nữa.
///
/// [message] vẫn giữ cho vài chỗ muốn tự soạn câu riêng.
class ErrorView extends StatelessWidget {
  final String? message;
  final Object? error;
  final VoidCallback? onRetry;

  const ErrorView({super.key, this.message, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cau = message ?? thongDiepLoi(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(cau, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton(onPressed: onRetry, child: Text(trg('common.retry'))),
              ),
          ],
        ),
      ),
    );
  }
}
