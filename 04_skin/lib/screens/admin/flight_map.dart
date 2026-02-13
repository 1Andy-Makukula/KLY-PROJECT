/// =============================================================================
/// KithLy Global Protocol - FLIGHT MAP (Phase IV-Extension)
/// flight_map.dart - Active Riders Map View
/// =============================================================================
///
/// GoogleMap showing active Riders (Status 300) across Lusaka.
library;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../theme/alpha_theme.dart';
import '../../services/api_service.dart';

/// Active rider model
class ActiveRider {
  final String riderId;
  final String name;
  final double latitude;
  final double longitude;
  final String currentOrderId;
  final String status;
  final DateTime lastUpdate;

  ActiveRider({
    required this.riderId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.currentOrderId,
    required this.status,
    required this.lastUpdate,
  });

  factory ActiveRider.fromJson(Map<String, dynamic> json) {
    return ActiveRider(
      riderId: json['rider_id'] ?? '',
      name: json['name'] ?? 'Unknown Rider',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      currentOrderId: json['current_order_id'] ?? '',
      status: json['status'] ?? 'active',
      lastUpdate:
          DateTime.tryParse(json['last_update'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Flight Map showing active riders
class FlightMap extends StatefulWidget {
  const FlightMap({super.key});

  @override
  State<FlightMap> createState() => _FlightMapState();
}

class _FlightMapState extends State<FlightMap> {
  final ApiService _api = ApiService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<ActiveRider> _riders = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Lusaka center coordinates
  static const LatLng _lusakaCenter = LatLng(-15.3875, 28.3228);

  @override
  void initState() {
    super.initState();
    _loadRiders();
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadRiders(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadRiders() async {
    try {
      final data = await _api.getActiveRiders();
      _riders = data.map((json) => ActiveRider.fromJson(json)).toList();
    } catch (e) {
      // Use mock data for development
      _riders = _getMockRiders();
    }

    _updateMarkers();
    setState(() => _isLoading = false);
  }

  List<ActiveRider> _getMockRiders() {
    return [
      ActiveRider(
        riderId: 'rider-1',
        name: 'Emmanuel Phiri',
        latitude: -15.3920,
        longitude: 28.3180,
        currentOrderId: 'order-abc',
        status: 'delivering',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      ActiveRider(
        riderId: 'rider-2',
        name: 'Joseph Banda',
        latitude: -15.4010,
        longitude: 28.2890,
        currentOrderId: 'order-def',
        status: 'delivering',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ActiveRider(
        riderId: 'rider-3',
        name: 'Moses Tembo',
        latitude: -15.3780,
        longitude: 28.3450,
        currentOrderId: 'order-ghi',
        status: 'picking_up',
        lastUpdate: DateTime.now(),
      ),
    ];
  }

  void _updateMarkers() {
    _markers = _riders.map((rider) {
      return Marker(
        markerId: MarkerId(rider.riderId),
        position: LatLng(rider.latitude, rider.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          rider.status == 'delivering'
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueBlue,
        ),
        infoWindow: InfoWindow(
          title: rider.name,
          snippet: rider.status == 'delivering' ? 'Delivering' : 'Picking up',
        ),
        onTap: () => _showRiderDetails(rider),
      );
    }).toSet();
  }

  void _showRiderDetails(ActiveRider rider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AlphaTheme.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: rider.status == 'delivering'
                        ? AlphaTheme.accentGreen.withOpacity(0.2)
                        : AlphaTheme.accentBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delivery_dining,
                    color: rider.status == 'delivering'
                        ? AlphaTheme.accentGreen
                        : AlphaTheme.accentBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.name,
                        style: AlphaTheme.headingMedium,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: rider.status == 'delivering'
                              ? AlphaTheme.accentGreen.withOpacity(0.2)
                              : AlphaTheme.accentBlue.withOpacity(0.2),
                          borderRadius: AlphaTheme.chipRadius,
                        ),
                        child: Text(
                          rider.status == 'delivering'
                              ? 'DELIVERING'
                              : 'PICKING UP',
                          style: TextStyle(
                            color: rider.status == 'delivering'
                                ? AlphaTheme.accentGreen
                                : AlphaTheme.accentBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.location_on, 'Location',
                '${rider.latitude.toStringAsFixed(4)}, ${rider.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 12),
            _buildDetailRow(
                Icons.receipt_long, 'Current Order', rider.currentOrderId),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.access_time, 'Last Update',
                _getTimeAgo(rider.lastUpdate)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Open chat/call
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _focusOnRider(rider);
                    },
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Focus'),
                    style: AlphaTheme.primaryButton,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AlphaTheme.textMuted, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AlphaTheme.textMuted),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AlphaTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _focusOnRider(ActiveRider rider) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(rider.latitude, rider.longitude),
        16,
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _lusakaCenter,
            zoom: 12,
          ),
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
            // Apply dark theme
            controller.setMapStyle(_mapStyle);
          },
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
        ),

        // Loading indicator
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AlphaTheme.accentBlue),
            ),
          ),

        // Stats overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AlphaTheme.glassCard,
            child: Row(
              children: [
                _buildStatBadge(
                  Icons.delivery_dining,
                  '${_riders.length}',
                  'Active Riders',
                  AlphaTheme.accentGreen,
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white12,
                ),
                _buildStatBadge(
                  Icons.local_shipping,
                  '${_riders.where((r) => r.status == 'delivering').length}',
                  'Delivering',
                  AlphaTheme.accentBlue,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadRiders();
                  },
                ),
              ],
            ),
          ),
        ),

        // Rider list (bottom)
        if (_riders.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _riders.length,
                itemBuilder: (context, index) {
                  final rider = _riders[index];
                  return GestureDetector(
                    onTap: () => _focusOnRider(rider),
                    child: Container(
                      width: 160,
                      margin: EdgeInsets.only(
                        right: index < _riders.length - 1 ? 12 : 0,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: AlphaTheme.glassCard,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: rider.status == 'delivering'
                                  ? AlphaTheme.accentGreen.withOpacity(0.2)
                                  : AlphaTheme.accentBlue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delivery_dining,
                              color: rider.status == 'delivering'
                                  ? AlphaTheme.accentGreen
                                  : AlphaTheme.accentBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  rider.name.split(' ').first,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _getTimeAgo(rider.lastUpdate),
                                  style: AlphaTheme.captionText,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatBadge(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AlphaTheme.captionText,
            ),
          ],
        ),
      ],
    );
  }

  // Dark map style
  static const String _mapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#023e58"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
]
''';
}
