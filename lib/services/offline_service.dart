import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterfinder/models/water_source.dart';

class OfflineService {
  static const String _waterSourcesKey = 'water_sources';
  final SharedPreferences _prefs;

  OfflineService(this._prefs);

  Future<void> cacheWaterSources(List<WaterSource> sources) async {
    final sourcesJson = sources.map((source) => source.toMap()).toList();
    await _prefs.setString(_waterSourcesKey, jsonEncode(sourcesJson));
  }

  List<WaterSource> getCachedWaterSources() {
    final sourcesJson = _prefs.getString(_waterSourcesKey);
    if (sourcesJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(sourcesJson);
      return decoded.map((json) {
        return WaterSource(
          id: json['id'] ?? '',
          name: json['name'] ?? '',
          location: json['location'],
          type: json['type'] ?? '',
          description: json['description'] ?? '',
          status: json['status'] ?? '',
          reportedBy: json['reportedBy'] ?? '',
          lastUpdated: DateTime.parse(json['lastUpdated']),
          images: List<String>.from(json['images'] ?? []),
          isVerified: json['isVerified'] ?? false,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> cacheWaterSource(WaterSource source) async {
    final sources = getCachedWaterSources();
    final existingIndex = sources.indexWhere((s) => s.id == source.id);
    
    if (existingIndex != -1) {
      sources[existingIndex] = source;
    } else {
      sources.add(source);
    }

    await cacheWaterSources(sources);
  }

  Future<void> clearCache() async {
    await _prefs.remove(_waterSourcesKey);
  }

  Future<void> removeCachedWaterSource(String sourceId) async {
    final sources = getCachedWaterSources();
    sources.removeWhere((source) => source.id == sourceId);
    await cacheWaterSources(sources);
  }

  Future<bool> hasCachedData() async {
    return _prefs.containsKey(_waterSourcesKey);
  }
}