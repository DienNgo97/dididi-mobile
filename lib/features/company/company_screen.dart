import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import 'company_repository.dart';

const _brand = AppTheme.brand;

/// Công ty của tôi (B2B): xem ngân sách còn lại + nhận lời mời bằng mã.
class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});
  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  final _tokenC = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _tokenC.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _accept() async {
    final token = _tokenC.text.trim();
    if (token.isEmpty) return _snack(trg('company.enterInvite'));
    setState(() => _busy = true);
    try {
      final name = await ref.read(companyRepositoryProvider).acceptInvite(token);
      _tokenC.clear();
      ref.invalidate(companyMeProvider);
      _snack(trg('company.joined').replaceAll('{v}', name));
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('company.inviteInvalid'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(companyMeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(trg('company.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          async.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text(trg('account.errorWith').replaceAll('{v}', '$e'), style: const TextStyle(color: Colors.redAccent)),
            data: (c) => c == null
                ? const _NoCompany()
                : AppCard(
                    color: AppTheme.brandSoft,
                    border: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.business, color: _brand),
                          const SizedBox(width: 8),
                          Expanded(child: Text(c.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.ink))),
                        ]),
                        const SizedBox(height: 10),
                        _row(trg('company.budget'), formatVnd(c.budgetTotal)),
                        _row(trg('company.used'), formatVnd(c.budgetUsed)),
                        _row(trg('company.remaining'), formatVnd(c.budgetRemaining), highlight: true),
                        const SizedBox(height: 6),
                        Text(trg('company.payHint'),
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          SectionHeader(trg('company.acceptInvite')),
          TextField(
            controller: _tokenC,
            decoration: InputDecoration(
              labelText: trg('company.inviteCode'),
              hintText: trg('company.inviteHint'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _accept,
            icon: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.how_to_reg_outlined),
            label: Text(trg('company.join')),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 13))),
          Text(value,
              style: TextStyle(
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                  color: highlight ? _brand : AppTheme.ink,
                  fontSize: 14)),
        ]),
      );
}

class _NoCompany extends StatelessWidget {
  const _NoCompany();
  @override
  Widget build(BuildContext context) => AppCard(
        color: AppTheme.bg,
        child: Row(children: [
          const Icon(Icons.info_outline, color: AppTheme.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(trg('company.none'),
                style: const TextStyle(color: AppTheme.ink)),
          ),
        ]),
      );
}
