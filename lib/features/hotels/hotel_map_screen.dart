import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/i18n/l10n.dart';
import '../../shared/format.dart';
import '../../shared/widgets/error_view.dart';
import 'hotel_models.dart';
import 'hotels_controller.dart';

const _brand = Color(0xFF2F8B60);
// Trung tâm Việt Nam (Đà Nẵng) khi chưa có dữ liệu toạ độ.
const _vnCenter = LatLng(16.047079, 108.206230);

/// Bản đồ khách sạn + nút "Gần tôi" (định vị & phóng tới vị trí người dùng).
class HotelMapScreen extends ConsumerStatefulWidget {
  const HotelMapScreen({super.key});
  @override
  ConsumerState<HotelMapScreen> createState() => _HotelMapScreenState();
}

class _HotelMapScreenState extends ConsumerState<HotelMapScreen> {
  final Completer<GoogleMapController> _ctrl = Completer();
  bool _locating = false;

  Future<void> _goToMe() async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        messenger.showSnackBar(SnackBar(content: Text(trg('hotel.locOff'))));
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        messenger.showSnackBar(SnackBar(content: Text(trg('hotel.locDenied'))));
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final c = await _ctrl.future;
      await c.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 13));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(trg('hotel.locFail').replaceAll('{e}', '$e'))));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _openHotel(Hotel h) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.place, size: 15, color: Colors.black45),
              const SizedBox(width: 4),
              Expanded(child: Text(h.address ?? h.city ?? '', style: const TextStyle(color: Colors.black54))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              if (h.starRating != null)
                Text('★' * h.starRating!, style: const TextStyle(color: Color(0xFFF5A623), fontSize: 15)),
              const Spacer(),
              Text(h.minPrice != null ? trg('hotel.fromPerNight').replaceAll('{p}', formatVnd(h.minPrice)) : trg('hotel.contact'),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _brand, fontSize: 15)),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/hotels/${h.id}');
                },
                child: Text(trg('hotel.viewDetail')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(hotelListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(trg('hotel.mapTitle'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.read(hotelListProvider.notifier).refresh()),
        data: (all) {
          final geo = all.where((h) => h.lat != null && h.lng != null).toList();
          final markers = <Marker>{
            for (final h in geo)
              Marker(
                markerId: MarkerId('h${h.id}'),
                position: LatLng(h.lat!, h.lng!),
                infoWindow: InfoWindow(
                  title: h.name,
                  snippet: h.minPrice != null ? trg('hotel.fromPrice').replaceAll('{p}', formatVnd(h.minPrice)) : null,
                  onTap: () => _openHotel(h),
                ),
                onTap: () => _openHotel(h),
              ),
          };
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: geo.isNotEmpty ? LatLng(geo.first.lat!, geo.first.lng!) : _vnCenter,
              zoom: geo.isNotEmpty ? 11 : 5.5,
            ),
            markers: markers,
            myLocationEnabled: !kIsWeb,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              if (!_ctrl.isCompleted) _ctrl.complete(c);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _locating ? null : _goToMe,
        backgroundColor: _brand,
        icon: _locating
            ? const SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.my_location, color: Colors.white),
        label: const Text('Gần tôi', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
