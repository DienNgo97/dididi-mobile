import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../flights/flight_models.dart';
import '../hotels/hotel_models.dart';
import 'trip_models.dart';
import 'trip_repository.dart';

const _brand = AppTheme.brand;

/// Gợi ý chuyến đi: nhập thành phố → chuyến bay + khách sạn gợi ý.
class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});
  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  final _city = TextEditingController();
  final _from = TextEditingController();
  TripSuggestion? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _city.dispose();
    _from.dispose();
    super.dispose();
  }

  Future<void> _suggest() async {
    final city = _city.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('trip.enterCity'))));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(tripRepositoryProvider).suggest(city, from: _from.text.trim());
      if (mounted) setState(() => _result = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = trg('trip.suggestFail'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trg('tripPlanner'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.brandSoft,
            child: ListTile(
              leading: const Icon(Icons.card_travel, color: _brand),
              title: Text(trg('trip.packageCard'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(trg('trip.packageCardSub')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/trip-plan'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
                labelText: trg('trip.cityLabel'), border: const OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _from,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
                labelText: trg('trip.fromAirportOptional'),
                border: const OutlineInputBorder(),
                isDense: true),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _suggest,
            icon: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(trg('trip.suggestBtn')),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          if (_result != null) ..._results(_result!),
        ],
      ),
    );
  }

  List<Widget> _results(TripSuggestion s) {
    return [
      const SizedBox(height: 20),
      SectionHeader('${trg('trip.destination')}: ${s.city ?? ''}${s.destinationAirport != null ? ' (${s.destinationAirport})' : ''}'),
      const SizedBox(height: 12),
      SectionHeader(trg('trip.suggestedFlights')),
      const SizedBox(height: 8),
      if (s.flights.isEmpty)
        Text(trg('flight.noneShort'), style: const TextStyle(color: AppTheme.muted))
      else
        for (final f in s.flights.take(5)) _flightRow(f),
      const SizedBox(height: 20),
      SectionHeader(trg('trip.suggestedHotels')),
      const SizedBox(height: 8),
      if (s.hotels.isEmpty)
        Text(trg('trip.noHotel'), style: const TextStyle(color: AppTheme.muted))
      else
        for (final h in s.hotels.take(6)) _hotelRow(h),
    ];
  }

  Widget _flightRow(Flight f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.flight, color: _brand),
        title: Text('${f.from} → ${f.to}  ·  ${f.airlineCode ?? ''} ${f.flightNumber}'.trim()),
        subtitle: Text(f.departureTime == null ? '' : '${hm(f.departureTime!)} · ${dmy(f.departureTime!)}'),
        trailing: Text(formatVnd(f.price), style: const TextStyle(fontWeight: FontWeight.w700, color: _brand)),
        onTap: () => context.push('/flights/${f.id}/book'),
      ),
    );
  }

  Widget _hotelRow(Hotel h) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.hotel, color: _brand),
        title: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text([
          if (h.starRating != null) '${'★' * h.starRating!} ',
          h.city ?? '',
        ].join()),
        trailing: h.minPrice != null
            ? Text(formatVnd(h.minPrice), style: const TextStyle(fontWeight: FontWeight.w700, color: _brand))
            : null,
        onTap: () => context.push('/hotels/${h.id}'),
      ),
    );
  }
}
