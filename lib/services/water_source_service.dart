import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:waterfinder/models/water_source.dart';

class WaterSourceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all water sources
  Stream<List<WaterSource>> getWaterSources() {
    return _firestore
        .collection('waterSources')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => WaterSource.fromFirestore(doc)).toList();
    });
  }

  // Get nearby water sources
  Future<List<WaterSource>> getNearbyWaterSources(
      GeoPoint location, double radiusInKm) async {
    // Create a GeoPoint for the search
    final center = location;
    const double earthRadius = 6371.0; // Earth's radius in kilometers

    // Calculate the bounding box for the search radius
    final double latChange = (radiusInKm / earthRadius) * (180 / pi);
    final double lonChange = (radiusInKm / earthRadius) * (180 / pi) /
        cos(center.latitude * pi / 180);

    final double minLat = center.latitude - latChange;
    final double maxLat = center.latitude + latChange;
    final double minLon = center.longitude - lonChange;
    final double maxLon = center.longitude + lonChange;

    final snapshot = await _firestore
        .collection('waterSources')
        .where('location.latitude', isGreaterThan: minLat)
        .where('location.latitude', isLessThan: maxLat)
        .get();

    return snapshot.docs
        .map((doc) => WaterSource.fromFirestore(doc))
        .where((source) {
      final sourceLon = source.location.longitude;
      return sourceLon >= minLon && sourceLon <= maxLon;
    }).toList();
  }

  // Add a new water source
  Future<String> addWaterSource(WaterSource source, List<String> imagePaths) async {
    // Upload images first
    List<String> imageUrls = [];
    for (String path in imagePaths) {
      final ref = _storage.ref().child('waterSources/${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
      await ref.putFile(File(path));
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    // Create water source with image URLs
    final docRef = await _firestore.collection('waterSources').add({
      ...source.toMap(),
      'images': imageUrls,
    });
    
    return docRef.id;
  }

  // Update water source status
  Future<void> updateWaterSourceStatus(String sourceId, String status) async {
    await _firestore.collection('waterSources').doc(sourceId).update({
      'status': status,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Report contaminated source
  Future<void> reportContamination(
      String sourceId, String description, List<String> imagePaths) async {
    List<String> imageUrls = [];
    for (String path in imagePaths) {
      final ref = _storage.ref().child('reports/${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
      await ref.putFile(File(path));
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    await _firestore.collection('waterSources').doc(sourceId).collection('reports').add({
      'description': description,
      'images': imageUrls,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await updateWaterSourceStatus(sourceId, 'reported');
  }
}