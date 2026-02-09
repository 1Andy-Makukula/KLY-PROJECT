/// =============================================================================
/// KithLy Global Protocol - SHOP VIEW (Phase V)
/// shop_view.dart - Shop Detail Page with Map Integration
/// =============================================================================
/// 
/// Shop details view with:
/// - Shop header + rating
/// - "View on Map" button → GoogleMap modal
/// - Products grid
library;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/alpha_theme.dart';

/// Shop View Screen
class ShopView extends StatelessWidget {
  final String shopId;
  final String shopName;
  final String? shopImage;
  final double rating;
  final double latitude;
  final double longitude;
  final String category;
  final String tier;
  
  const ShopView({
    super.key,
    required this.shopId,
    required this.shopName,
    this.shopImage,
    this.rating = 4.5,
    required this.latitude,
    required this.longitude,
    this.category = 'Gifts',
    this.tier = 'verified',
  });
  
  void _showMapModal(BuildContext context, LatLng? userLocation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapModal(
        shopName: shopName,
        shopLocation: LatLng(latitude, longitude),
        userLocation: userLocation,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Mock user location (in production, get from GPS)
    final userLocation = LatLng(-15.3650, 28.3420);
    
    return Scaffold(
      backgroundColor: AlphaTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Shop Header
          SliverToBoxAdapter(
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: AlphaTheme.backgroundCard,
                image: shopImage != null
                    ? DecorationImage(
                        image: NetworkImage(shopImage!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AlphaTheme.backgroundDark.withOpacity(0.9),
                      AlphaTheme.backgroundDark,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TierBadge(tier: tier),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AlphaTheme.secondaryGold.withOpacity(0.2),
                            borderRadius: AlphaTheme.chipRadius,
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(color: AlphaTheme.secondaryGold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AlphaTheme.secondaryGold, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        // VIEW ON MAP BUTTON
                        GestureDetector(
                          onTap: () => _showMapModal(context, userLocation),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AlphaTheme.accentBlue.withOpacity(0.2),
                              borderRadius: AlphaTheme.chipRadius,
                              border: Border.all(color: AlphaTheme.accentBlue.withOpacity(0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map, color: AlphaTheme.accentBlue, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'View on Map',
                                  style: TextStyle(color: AlphaTheme.accentBlue, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Products Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AlphaTheme.primaryOrange.withOpacity(0.2),
                      borderRadius: AlphaTheme.chipRadius,
                    ),
                    child: const Icon(Icons.shopping_bag, color: AlphaTheme.primaryOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Products',
                    style: TextStyle(color: AlphaTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          
          // Products Grid (Placeholder)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductCard(
                  name: 'Product ${index + 1}',
                  price: 150.0 + (index * 50),
                ),
                childCount: 6,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

/// Map Modal showing shop location relative to user
class _MapModal extends StatefulWidget {
  final String shopName;
  final LatLng shopLocation;
  final LatLng? userLocation;
  
  const _MapModal({
    required this.shopName,
    required this.shopLocation,
    this.userLocation,
  });
  
  @override
  State<_MapModal> createState() => _MapModalState();
}

class _MapModalState extends State<_MapModal> {
  GoogleMapController? _mapController;
  
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('shop'),
        position: widget.shopLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: widget.shopName),
      ),
    };
    
    if (widget.userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: widget.userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Delivery Location'),
        ),
      );
    }
    
    return markers;
  }
  
  LatLng _calculateCenter() {
    if (widget.userLocation == null) return widget.shopLocation;
    return LatLng(
      (widget.shopLocation.latitude + widget.userLocation!.latitude) / 2,
      (widget.shopLocation.longitude + widget.userLocation!.longitude) / 2,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: AlphaTheme.backgroundCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AlphaTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AlphaTheme.primaryOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.shopName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AlphaTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: AlphaTheme.cardRadius,
                boxShadow: AlphaTheme.softShadow,
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _calculateCenter(),
                  zoom: 14,
                ),
                markers: _buildMarkers(),
                onMapCreated: (controller) => _mapController = controller,
                mapType: MapType.normal,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                // Dark theme styling
                style: _darkMapStyle,
              ),
            ),
          ),
          
          // Distance info
          if (widget.userLocation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AlphaTheme.glassCard,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AlphaTheme.accentGreen.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions, color: AlphaTheme.accentGreen),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated Distance', style: TextStyle(color: AlphaTheme.textMuted, fontSize: 12)),
                          Text('2.4 km', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AlphaTheme.accentGreen.withOpacity(0.2),
                        borderRadius: AlphaTheme.chipRadius,
                      ),
                      child: const Text('Zone A · K50', style: TextStyle(color: AlphaTheme.accentGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Dark map style
const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]}
]
''';

// Helper widgets
class _TierBadge extends StatelessWidget {
  final String tier;
  
  const _TierBadge({required this.tier});
  
  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (tier) {
      case 'select':
        color = AlphaTheme.secondaryGold;
        icon = Icons.workspace_premium;
        break;
      case 'verified':
        color = AlphaTheme.accentGreen;
        icon = Icons.verified;
        break;
      case 'independent':
        color = AlphaTheme.accentBlue;
        icon = Icons.store;
        break;
      default:
        color = AlphaTheme.textMuted;
        icon = Icons.hourglass_empty;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: AlphaTheme.chipRadius,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            tier.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final double price;
  
  const _ProductCard({required this.name, required this.price});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AlphaTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AlphaTheme.backgroundGlass,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(
                child: Icon(Icons.image, color: AlphaTheme.textMuted, size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'K${price.toStringAsFixed(0)}',
                  style: const TextStyle(color: AlphaTheme.accentGreen, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
