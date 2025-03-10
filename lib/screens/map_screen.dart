import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waterfinder/models/water_source.dart';
import 'package:waterfinder/services/water_source_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final WaterSourceService _waterSourceService = WaterSourceService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _isLoading = false;
    });

    // Animate camera to current location when obtained
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        ),
      ),
    );

    _loadNearbyWaterSources();
  }

  Future<void> _loadNearbyWaterSources() async {
    if (_currentPosition == null) return;

    final sources = await _waterSourceService.getNearbyWaterSources(
      GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
      5.0, // 5km radius
    );

    setState(() {
      _markers = sources.map((source) {
        return Marker(
          markerId: MarkerId(source.id),
          position: LatLng(
            source.location.latitude,
            source.location.longitude,
          ),
          infoWindow: InfoWindow(
            title: source.name,
            snippet: source.description,
            onTap: () => _showSourceDetails(source),
          ),
        );
      }).toSet();

      if (_currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: const InfoWindow(title: 'موقعك الحالي'),
          ),
        );
      }
    });
  }

  void _showSourceDetails(WaterSource source) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              source.description,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 8),
            Text(
              'الحالة: ${source.status}',
              style: TextStyle(
                color: source.status == 'available'
                    ? Colors.green
                    : Colors.red,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/report',
                  arguments: source,
                );
              },
              child: const Text(
                'الإبلاغ عن مشكلة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مصادر المياه القريبة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentPosition?.latitude ?? 15.5007,
            _currentPosition?.longitude ?? 32.5599,
          ),
          zoom: 14.0,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNearbyWaterSources,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}