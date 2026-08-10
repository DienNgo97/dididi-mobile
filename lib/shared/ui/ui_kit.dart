import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Bộ UI dùng chung cho toàn app — đồng bộ phong cách hiện đại tối giản (Agoda/Booking).
/// Dùng token màu/bo góc trong [AppTheme].

/// Tiêu đề một khối nội dung: chấm nhấn xanh + tiêu đề + (tuỳ chọn) mô tả / nút bên phải.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.icon,
    this.padding = const EdgeInsets.fromLTRB(4, 4, 4, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppTheme.brand),
            const SizedBox(width: 8),
          ] else ...[
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(color: AppTheme.brand, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink, letterSpacing: -0.2)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Thẻ trắng bo mềm, viền mảnh, bóng rất nhẹ — khối nội dung tiêu chuẩn.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final bool border;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.radius = AppTheme.rCard,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: r,
        border: border ? Border.all(color: AppTheme.line) : null,
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: child,
    );
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: r, onTap: onTap, child: card),
      );
    }
    return card;
  }
}

/// Trạng thái rỗng/không có dữ liệu — icon tròn nhạt + tiêu đề + mô tả + (tuỳ chọn) nút.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppTheme.brandSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppTheme.brand),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppTheme.muted, height: 1.4)),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Viên nhãn nhỏ (pill) — tag/nhãn phụ.
class Pill extends StatelessWidget {
  final String text;
  final Color? color; // màu chữ + nền nhạt
  final IconData? icon;
  const Pill(this.text, {super.key, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.brand;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 8 : 9, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12.5, color: c), const SizedBox(width: 4)],
        Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c)),
      ]),
    );
  }
}

/// Nhãn trạng thái đơn/bài (màu theo ngữ cảnh).
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const StatusBadge(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Đường kẻ mảnh dùng chung.
class SoftDivider extends StatelessWidget {
  final double height;
  const SoftDivider({super.key, this.height = 1});
  @override
  Widget build(BuildContext context) => Container(height: height, color: AppTheme.line);
}
