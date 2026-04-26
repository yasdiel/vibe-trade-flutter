import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(19.4326, -99.1332);

  final MapController _mapController = MapController();
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation;
  }

  void _handleTap(TapPosition _, LatLng latLng) {
    setState(() => _selected = latLng);
  }

  void _confirm() {
    Navigator.pop<LatLng>(context, _selected);
  }

  void _clear() {
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = widget.initialLocation ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.foregroundColor,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: const Text(
          'Seleccionar ubicacion',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_selected != null)
            TextButton(
              onPressed: _clear,
              child: Text(
                'Limpiar',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13,
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vibetrade.vibe_trade_v1',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: AppTheme.primaryColor,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  _selected == null
                      ? 'Toca el mapa para marcar tu ubicacion.'
                      : 'Lat: ${_selected!.latitude.toStringAsFixed(5)}  ·  Lng: ${_selected!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop<LatLng?>(context, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.foregroundColor,
                      side: BorderSide(color: AppTheme.primaryColor, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selected == null ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.foregroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Usar esta ubicacion',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
