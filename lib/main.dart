import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/l10n.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase/push chỉ chạy trên Android/iOS (không phải web). Bọc try/catch để app
  // vẫn chạy khi Firebase chưa cấu hình cho nền tảng đang chạy.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {
      // bỏ qua -> app chạy không có push
    }
  }
  // Khôi phục ngôn ngữ đã chọn từ lần dùng trước (mặc định 'vi').
  final savedLang = await LocalePrefs.load();
  l10nLocale = Locale(savedLang);
  runApp(ProviderScope(
    overrides: [
      localeProvider.overrideWith((ref) => Locale(savedLang)),
    ],
    child: const DididiApp(),
  ));
}

class DididiApp extends ConsumerWidget {
  const DididiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    l10nLocale = locale; // đồng bộ locale toàn cục cho trg()

    // Khi trạng thái đăng nhập chuyển sang authenticated -> đăng ký token push.
    ref.listen(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        ref.read(pushServiceProvider).setup();
      }
    });

    // Tự lưu ngôn ngữ mỗi khi người dùng đổi (để lần mở sau vẫn giữ).
    ref.listen(localeProvider, (prev, next) {
      if (prev?.languageCode != next.languageCode) {
        LocalePrefs.save(next.languageCode);
      }
    });

    return MaterialApp.router(
      title: 'Dididi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: locale,
      supportedLocales: L10n.supported,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
