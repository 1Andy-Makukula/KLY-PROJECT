/// =============================================================================
/// KithLy Global Protocol - LOCATION PICKER (Onboarding Step 3)
/// location_picker.dart - Google Maps + Places Autocomplete
/// =============================================================================
///
/// Features:
/// - Google Places Autocomplete search bar
/// - Map layer toggle (Normal/Satellite/Hybrid)
/// - "Use My Current Location" button
/// - Confirm button (only active when map idle)
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// Location picker screen for shop onboarding
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng location, String? address)? onLocationConfirmed;
  
  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.onLocationConfirmed,
  });
  
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  // Default to Lusaka, Zambia
  static const LatLng _defaultLocation = LatLng(-15.4167, 28.2833);
  
  LatLng _currentCenter = _defaultLocation;
  MapType _currentMapType = MapType.normal;
  bool _isMapIdle = true;
  bool _isLoadingLocation = false;
  String? _selectedAddress;
  
  // Place predictions (mock - would use Google Places API)
  List<PlacePrediction> _predictions = [];
  bool _showPredictions = false;
  
  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation ?? _defaultLocation;
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Select Shop Location'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Google Map
          _buildMap(),
          
          // Center pin (fixed)
          _buildCenterPin(),
          
          // Search bar overlay
          _buildSearchBar(),
          
          // Map controls
          _buildMapControls(),
          
          // Confirm button
          _buildConfirmButton(),
        ],
      ),
    );
  }
  
  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentCenter,
        zoom: 15,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _setMapStyle();
      },
      onCameraMove: (position) {
        setState(() {
          _currentCenter = position.target;
          _isMapIdle = false;
        });
      },
      onCameraIdle: () {
        setState(() => _isMapIdle = true);
        _reverseGeocode(_currentCenter);
      },
      mapType: _currentMapType,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
    );
  }
  
  Widget _buildCenterPin() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(
              0, 
              _isMapIdle ? 0 : -10, 
              0,
            ),
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: _isMapIdle 
                  ? const Color(0xFF10B981) 
                  : const Color(0xFF3B82F6),
              shadows: const [
                Shadow(
                  blurRadius: 10,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  blurRadius: _isMapIdle ? 4 : 8,
                  spreadRadius: _isMapIdle ? 2 : 4,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Search input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _showPredictions = false);
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _onSearchChanged,
              onTap: () => setState(() => _showPredictions = true),
            ),
          ),
          
          // Predictions dropdown
          if (_showPredictions && _predictions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.grey),
                    title: Text(
                      prediction.mainText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      prediction.secondaryText,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => _selectPrediction(prediction),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      bottom: 120,
      child: Column(
        children: [
          // Map type toggle
          _ControlButton(
            icon: _currentMapType == MapType.normal 
                ? Icons.satellite_alt 
                : Icons.map,
            onPressed: _toggleMapType,
            tooltip: 'Toggle map view',
          ),
          const SizedBox(height: 8),
          
          // Current location
          _ControlButton(
            icon: Icons.my_location,
            onPressed: _goToCurrentLocation,
            isLoading: _isLoadingLocation,
            tooltip: 'Use my location',
          ),
          const SizedBox(height: 8),
          
          // Zoom in
          _ControlButton(
            icon: Icons.add,
            onPressed: () => _mapController?.animateCamera(
              CameraUpdate.zoomIn(),
            ),
            tooltip: 'Zoom in',
          ),
          const SizedBox(height: 8),
          
          // Zoom out
          _ControlButton(
            icon: Icons.remove,
            onPressed: () => _mapController?.animateCamera(
              CameraUpdate.zoomOut(),
            ),
            tooltip: 'Zoom out',
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfirmButton() {
    return Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: Column(
        children: [
          // Address preview
          if (_selectedAddress != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_pin, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAddress!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isMapIdle ? _confirmLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isMapIdle ? Icons.check_circle : Icons.pending,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isMapIdle ? 'Confirm Location' : 'Move map to select...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _setMapStyle() async {
    // Custom dark map style would be loaded here
  }
  
  void _onSearchChanged(String query) {
    if (query.length < 3) {
      setState(() => _predictions = []);
      return;
    }
    
    // Mock predictions (in production, call Google Places API)
    setState(() {
      _predictions = [
        PlacePrediction(
          placeId: '1',
          mainText: 'Lusaka City Market',
          secondaryText: 'Cairo Road, Lusaka, Zambia',
          location: const LatLng(-15.4178, 28.2823),
        ),
        PlacePrediction(
          placeId: '2',
          mainText: 'Manda Hill Shopping Mall',
          secondaryText: 'Great East Road, Lusaka, Zambia',
          location: const LatLng(-15.3996, 28.3228),
        ),
        PlacePrediction(
          placeId: '3',
          mainText: 'Levy Junction Mall',
          secondaryText: 'Church Road, Lusaka, Zambia',
          location: const LatLng(-15.4039, 28.3135),
        ),
      ];
      _showPredictions = true;
    });
  }
  
  void _selectPrediction(PlacePrediction prediction) {
    _searchController.text = prediction.mainText;
    _selectedAddress = '${prediction.mainText}, ${prediction.secondaryText}';
    _showPredictions = false;
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(prediction.location, 17),
    );
    
    setState(() {
      _currentCenter = prediction.location;
    });
  }
  
  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }
  
  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
        return;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final newLocation = LatLng(position.latitude, position.longitude);
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 17),
      );
      
      setState(() {
        _currentCenter = newLocation;
      });
      
    } catch (e) {
      _showError('Could not get current location');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }
  
  void _reverseGeocode(LatLng location) async {
    // In production, call Google Geocoding API
    // For now, show coordinates
    setState(() {
      _selectedAddress = 
          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
    });
  }
  
  void _confirmLocation() {
    widget.onLocationConfirmed?.call(_currentCenter, _selectedAddress);
    Navigator.pop(context, {
      'latitude': _currentCenter.latitude,
      'longitude': _currentCenter.longitude,
      'address': _selectedAddress,
    });
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Control button widget for map controls
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final String tooltip;
  
  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    required this.tooltip,
  });
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, color: const Color(0xFF1E293B)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Place prediction model
class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final LatLng location;
  
  PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.location,
  });
}
