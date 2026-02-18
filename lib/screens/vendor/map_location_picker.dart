import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class MapLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isLoading = true;
  LatLng _initialPosition = const LatLng(20.5937, 78.9629); // India center

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Widget _darkModeTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.8, 0, 0, 0, 255,
        0, -0.8, 0, 0, 255,
        0, 0, -0.8, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }

  Future<void> _initializeLocation() async {
    try {
      // If initial location provided, use it
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        setState(() {
          _initialPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
          _selectedLocation = _initialPosition;
          _isLoading = false;
        });
        return;
      }

      // Otherwise get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _selectedLocation = _initialPosition;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  void _getCurrentLocation() async {
    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them in settings.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied'), backgroundColor: Colors.red),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied. Enable in settings.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = newLocation;
      });

      _mapController.move(newLocation, 15);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated!'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Shop Location', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialPosition,
                    initialZoom: 15,
                    onTap: _onMapTapped,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.icuisine',
                      tileBuilder: isDark ? _darkModeTileBuilder : null,
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                // Get map bounds for coordinate conversion
                                final bounds = _mapController.camera.visibleBounds;
                                final ne = bounds.northEast;
                                final sw = bounds.southWest;
                                
                                // Calculate map dimensions
                                final latDiff = ne.latitude - sw.latitude;
                                final lngDiff = ne.longitude - sw.longitude;
                                
                                // Get screen size
                                final screenSize = MediaQuery.of(context).size;
                                
                                // Convert pixel movement to lat/lng movement
                                final latChange = -(details.delta.dy / screenSize.height) * latDiff;
                                final lngChange = (details.delta.dx / screenSize.width) * lngDiff;
                                
                                setState(() {
                                  _selectedLocation = LatLng(
                                    _selectedLocation!.latitude + latChange,
                                    _selectedLocation!.longitude + lngChange,
                                  );
                                });
                              },
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFFFA5211),
                                size: 50,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                // Instructions at top
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: const Color(0xFFFA5211), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap or drag marker to select your shop location',
                            style: GoogleFonts.outfit(fontSize: 13, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom buttons
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedLocation != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                              ),
                            ),
                          Row(
                            children: [
                              // Current Location Button
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  onPressed: _getCurrentLocation,
                                  icon: const Icon(Icons.my_location, size: 18),
                                  label: Text('Current Location', style: GoogleFonts.outfit(fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFFA5211),
                                    side: const BorderSide(color: Color(0xFFFA5211)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Confirm Button
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: _selectedLocation != null ? _confirmLocation : null,
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: Text('Confirm Location', style: GoogleFonts.outfit(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFA5211),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
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
              ],
            ),
    );
  }
}
