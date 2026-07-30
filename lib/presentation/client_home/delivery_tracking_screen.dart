import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

/// Suivi de livraison sur carte (Google Maps) — affiche la dernière
/// position connue du livreur (mise à jour manuellement par le staff, pas
/// de suivi GPS continu) et une ligne directe vers l'adresse de
/// livraison, pas un itinéraire routier réel (pas d'API Directions
/// payante — cohérent avec le calcul de distance à vol d'oiseau déjà
/// utilisé pour les frais de livraison, voir delivery_pricing.dart).
class DeliveryTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const DeliveryTrackingScreen({super.key, required this.order});

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'le ${DateFormat('dd/MM à HH:mm').format(dt.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driverLat = (order['driver_latitude'] as num?)?.toDouble();
    final driverLon = (order['driver_longitude'] as num?)?.toDouble();
    final updatedAtRaw = order['driver_position_updated_at'] as String?;
    final updatedAt =
        updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null;

    if (driverLat == null || driverLon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suivi de livraison')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "La position du livreur n'a pas encore été renseignée pour "
              "cette commande. Elle apparaîtra ici dès que notre équipe "
              "l'aura mise à jour.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final driverPos = LatLng(driverLat, driverLon);
    final destLat = (order['latitude'] as num?)?.toDouble();
    final destLon = (order['longitude'] as num?)?.toDouble();
    final destPos =
        (destLat != null && destLon != null) ? LatLng(destLat, destLon) : null;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('driver'),
        position: driverPos,
        infoWindow: const InfoWindow(title: 'Livreur'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      if (destPos != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: destPos,
          infoWindow: const InfoWindow(title: 'Votre adresse'),
        ),
    };

    final polylines = <Polyline>{
      if (destPos != null)
        Polyline(
          polylineId: const PolylineId('route'),
          points: [driverPos, destPos],
          color: theme.colorScheme.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi de livraison')),
      body: Column(
        children: [
          if (updatedAt != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Position mise à jour ${_relativeTime(updatedAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          if (destPos == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.errorContainer,
              child: Text(
                "Adresse de livraison non disponible — seule la position "
                "du livreur est affichée.",
                style: theme.textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: driverPos, zoom: 13),
              markers: markers,
              polylines: polylines,
              myLocationButtonEnabled: false,
              onMapCreated: (controller) {
                if (destPos == null) return;
                final south = driverPos.latitude < destPos.latitude
                    ? driverPos.latitude
                    : destPos.latitude;
                final north = driverPos.latitude > destPos.latitude
                    ? driverPos.latitude
                    : destPos.latitude;
                final west = driverPos.longitude < destPos.longitude
                    ? driverPos.longitude
                    : destPos.longitude;
                final east = driverPos.longitude > destPos.longitude
                    ? driverPos.longitude
                    : destPos.longitude;
                final bounds = LatLngBounds(
                  southwest: LatLng(south, west),
                  northeast: LatLng(north, east),
                );
                Future.delayed(const Duration(milliseconds: 300), () {
                  controller
                      .animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
