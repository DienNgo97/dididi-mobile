import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import 'vendor_repository.dart';

const _brand = AppTheme.brand;

/// Đăng ký làm nhà cung cấp (bán phòng trên Dididi). Song song với web /vendor-register.
class VendorRegisterScreen extends ConsumerStatefulWidget {
  const VendorRegisterScreen({super.key});
  @override
  ConsumerState<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends ConsumerState<VendorRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _hotelName = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  int? _star;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _phone.dispose();
    _hotelName.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(vendorRepositoryProvider).register(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim(),
            hotelName: _hotelName.text.trim(),
            city: _city.text.trim(),
            address: _address.text.trim(),
            starRating: _star,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(trg('vendor.successTitle')),
          content: Text(trg('vendor.successBody')),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(trg('vendor.understood'))),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('vendor.registerFailed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trg('vendor.title'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              color: AppTheme.brandSoft,
              border: false,
              child: Text(
                trg('vendor.intro'),
                style: const TextStyle(color: AppTheme.brandDark, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(trg('account')),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec(trg('vendor.emailReq'), Icons.mail_outline),
              validator: (v) => (v == null || !v.contains('@')) ? trg('vendor.emailInvalid') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: _dec(trg('vendor.passwordReq'), Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? trg('vendor.passwordMin6') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _fullName, decoration: _dec(trg('vendor.repName'), Icons.person_outline)),
            const SizedBox(height: 12),
            TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _dec(trg('common.phone'), Icons.phone_outlined)),
            const SizedBox(height: 20),
            SectionHeader(trg('hotels')),
            TextFormField(
              controller: _hotelName,
              decoration: _dec(trg('vendor.hotelNameReq'), Icons.apartment_outlined),
              validator: (v) => (v == null || v.trim().isEmpty) ? trg('vendor.enterHotelName') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _city, decoration: _dec(trg('vendor.city'), Icons.location_city_outlined)),
            const SizedBox(height: 12),
            TextFormField(controller: _address, decoration: _dec(trg('vendor.address'), Icons.place_outlined)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _star,
              decoration: _dec(trg('vendor.starRating'), Icons.star_outline),
              items: [
                for (int i = 1; i <= 5; i++) DropdownMenuItem(value: i, child: Text(trg('vendor.stars').replaceAll('{v}', '$i'))),
              ],
              onChanged: (v) => setState(() => _star = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(trg('vendor.submit')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _brand),
        border: const OutlineInputBorder(),
        isDense: true,
      );
}
