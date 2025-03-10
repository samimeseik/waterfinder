import 'package:cloud_firestore/cloud_firestore.dart';

class WaterSource {
  final String id;
  final String name;
  final GeoPoint location;
  final String type;
  final String description;
  final String status;
  final String reportedBy;
  final DateTime lastUpdated;
  final List<String> images;
  final bool isVerified;
  double? distance; // Distance from user's current location in kilometers

  WaterSource({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.description,
    required this.status,
    required this.reportedBy,
    required this.lastUpdated,
    this.images = const [],
    this.isVerified = false,
    this.distance,
  });

  factory WaterSource.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WaterSource(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] as GeoPoint,
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []),
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'type': type,
      'description': description,
      'status': status,
      'reportedBy': reportedBy,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'images': images,
      'isVerified': isVerified,
    };
  }

  WaterSource copyWith({
    String? id,
    String? name,
    GeoPoint? location,
    String? type,
    String? description,
    String? status,
    String? reportedBy,
    DateTime? lastUpdated,
    List<String>? images,
    bool? isVerified,
    double? distance,
  }) {
    return WaterSource(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      reportedBy: reportedBy ?? this.reportedBy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      images: images ?? this.images,
      isVerified: isVerified ?? this.isVerified,
      distance: distance ?? this.distance,
    );
  }
}