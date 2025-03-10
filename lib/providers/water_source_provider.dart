import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterfinder/models/water_source.dart';
import 'package:waterfinder/services/water_source_service.dart';
import 'package:waterfinder/services/offline_service.dart';

class WaterSourceProvider with ChangeNotifier {
  final WaterSourceService _waterSourceService;
  late final OfflineService _offlineService;
  List<WaterSource> _waterSources = [];
  bool _isLoading = false;
  String? _error;

  WaterSourceProvider(this._waterSourceService) {
    _initializeOfflineService();
  }

  List<WaterSource> get waterSources => _waterSources;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _initializeOfflineService() async {
    final prefs = await SharedPreferences.getInstance();
    _offlineService = OfflineService(prefs);
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final cachedSources = _offlineService.getCachedWaterSources();
    if (cachedSources.isNotEmpty) {
      _waterSources = cachedSources;
      notifyListeners();
    }
  }

  Future<void> loadWaterSources() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final sources = await _waterSourceService.getWaterSources().first;
      _waterSources = sources;
      await _offlineService.cacheWaterSources(sources);
      _error = null;
    } catch (e) {
      _error = 'فشل في تحميل مصادر المياه';
      // Load from cache if online fetch fails
      await _loadCachedData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWaterSource(WaterSource source, List<String> imagePaths) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final sourceId = await _waterSourceService.addWaterSource(source, imagePaths);
      final newSource = WaterSource(
        id: sourceId,
        name: source.name,
        location: source.location,
        type: source.type,
        description: source.description,
        status: source.status,
        reportedBy: source.reportedBy,
        lastUpdated: source.lastUpdated,
        images: source.images,
        isVerified: source.isVerified,
      );
      
      _waterSources.add(newSource);
      await _offlineService.cacheWaterSource(newSource);
      _error = null;
    } catch (e) {
      _error = 'فشل في إضافة مصدر المياه';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reportContamination(
    String sourceId,
    String description,
    List<String> imagePaths,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _waterSourceService.reportContamination(
        sourceId,
        description,
        imagePaths,
      );

      final index = _waterSources.indexWhere((s) => s.id == sourceId);
      if (index != -1) {
        final updatedSource = WaterSource(
          id: sourceId,
          name: _waterSources[index].name,
          location: _waterSources[index].location,
          type: _waterSources[index].type,
          description: _waterSources[index].description,
          status: 'reported',
          reportedBy: _waterSources[index].reportedBy,
          lastUpdated: DateTime.now(),
          images: _waterSources[index].images,
          isVerified: _waterSources[index].isVerified,
        );
        
        _waterSources[index] = updatedSource;
        await _offlineService.cacheWaterSource(updatedSource);
      }
      _error = null;
    } catch (e) {
      _error = 'فشل في إرسال البلاغ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<WaterSource>> getNearbyWaterSources(GeoPoint location, double radiusInKm) async {
    try {
      final sources = await _waterSourceService.getNearbyWaterSources(location, radiusInKm);
      return sources;
    } catch (e) {
      // If online fetch fails, filter cached sources by distance
      final cachedSources = _offlineService.getCachedWaterSources();
      return _filterSourcesByDistance(cachedSources, location, radiusInKm);
    }
  }

  List<WaterSource> _filterSourcesByDistance(
    List<WaterSource> sources,
    GeoPoint center,
    double radiusInKm,
  ) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers
    
    return sources.where((source) {
      final lat1 = center.latitude * (pi / 180);
      final lon1 = center.longitude * (pi / 180);
      final lat2 = source.location.latitude * (pi / 180);
      final lon2 = source.location.longitude * (pi / 180);

      final dLat = lat2 - lat1;
      final dLon = lon2 - lon1;

      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      final distance = earthRadius * c;

      return distance <= radiusInKm;
    }).toList();
  }
}