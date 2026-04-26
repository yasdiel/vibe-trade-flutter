import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class StoreLocationPreview extends StatelessWidget {
  final LatLng location;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const StoreLocationPreview({
    super.key,
    required this.location,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          _MapPreview(location: location),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: const SizedBox.expand()),
            ),
          ),
          _ClearLocationButton(onClear: onClear),
          const _ChangeLocationHint(),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  final LatLng location;

  const _MapPreview({required this.location});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: IgnorePointer(
        child: FlutterMap(
          key: ValueKey<String>('${location.latitude},${location.longitude}'),
          options: MapOptions(
            initialCenter: location,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.vibetrade.vibe_trade_v1',
            ),
            MarkerLayer(markers: [_marker]),
          ],
        ),
      ),
    );
  }

  Marker get _marker {
    return Marker(
      point: location,
      width: 36,
      height: 36,
      child: Icon(Icons.location_on, color: AppTheme.primaryColor, size: 36),
    );
  }
}

class _ClearLocationButton extends StatelessWidget {
  final VoidCallback onClear;

  const _ClearLocationButton({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6,
      right: 6,
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onClear,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.close, size: 18, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _ChangeLocationHint extends StatelessWidget {
  const _ChangeLocationHint();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_location_alt_outlined,
              size: 14,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Tocar para cambiar',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
