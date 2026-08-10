import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import '../auth/auth_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final lang = ref.watch(localeProvider).languageCode;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.brandSoft,
                child: Text(
                  (auth.email != null && auth.email!.isNotEmpty) ? auth.email![0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 26, color: AppTheme.brand, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.email ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.ink),
                    ),
                    const SizedBox(height: 6),
                    Pill('${tr(ref, 'role')}: ${auth.role ?? '—'}', icon: Icons.verified_user_outlined),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppTheme.brand),
                title: Text(tr(ref, 'profile.title')),
                subtitle: Text(tr(ref, 'account.profileSub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.brand),
                title: Text(tr(ref, 'language')),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'vi', label: Text('VI')),
                    ButtonSegment(value: 'en', label: Text('EN')),
                    ButtonSegment(value: 'zh', label: Text('中')),
                  ],
                  selected: {lang},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => ref.read(localeProvider.notifier).state = Locale(s.first),
                ),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.travel_explore, color: AppTheme.brand),
                title: Text(trg('trip.guideTitle')),
                subtitle: Text(trg('trip.guideBannerMsg')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/trip-guide'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: AppTheme.brand),
                title: Text(tr(ref, 'tripPlanner')),
                subtitle: Text(tr(ref, 'tripPlannerSub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/trip-planner'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.brand),
                title: Text(tr(ref, 'messages')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/dm'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.support_agent, color: AppTheme.brand),
                title: Text(tr(ref, 'support.title')),
                subtitle: Text(tr(ref, 'account.supportSub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/support'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.bookmark_border, color: AppTheme.brand),
                title: Text(tr(ref, 'account.bookmarks')),
                subtitle: Text(tr(ref, 'account.bookmarksSub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/community/bookmarks'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.groups_outlined, color: AppTheme.brand),
                title: Text(tr(ref, 'group.myGroups')),
                subtitle: Text(tr(ref, 'account.groupsSub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/groups'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.business_center_outlined, color: AppTheme.brand),
                title: Text(tr(ref, 'company.title')),
                subtitle: Text(tr(ref, 'account.companySub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/company'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.card_giftcard, color: AppTheme.brand),
                title: Text(trg('offer.title')),
                subtitle: Text(trg('offer.accountSub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/offers'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.star_outline, color: AppTheme.brand),
                title: Text(tr(ref, 'rewards')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/loyalty'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: AppTheme.brand),
                title: Text(tr(ref, 'wishlist')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/wishlist'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppTheme.brand),
                title: Text(tr(ref, 'account.terms')),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => launchUrl(Uri.parse('${Env.baseUrl}/legal/terms'), mode: LaunchMode.externalApplication),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.brand),
                title: Text(tr(ref, 'account.privacy')),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => launchUrl(Uri.parse('${Env.baseUrl}/legal/privacy'), mode: LaunchMode.externalApplication),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.devices_other, color: AppTheme.brand),
                title: Text(tr(ref, 'session.devices')),
                subtitle: Text(tr(ref, 'account.devicesSub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/sessions'),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(tr(ref, 'logout'), style: const TextStyle(color: Colors.redAccent)),
                onTap: () => ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
