import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class AppHelpers {
  static Future<String> compressAndSaveImage(String imagePath) async {
    final File imageFile = File(imagePath);
    final Directory tempDir = await getTemporaryDirectory();
    final String targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Load the image
    final ui.Image image = await decodeImageFromList(await imageFile.readAsBytes());
    
    // Calculate new dimensions maintaining aspect ratio
    final double aspectRatio = image.width / image.height;
    const int targetWidth = 800; // Max width for uploaded images
    final int targetHeight = (targetWidth / aspectRatio).round();

    // Create a recorder
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    // Draw the image scaled down
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );

    // Save the compressed image
    final ui.Image compressedImage = await recorder.endRecording().toImage(
      targetWidth,
      targetHeight,
    );
    final ByteData? byteData = await compressedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    if (byteData != null) {
      await File(targetPath).writeAsBytes(byteData.buffer.asUint8List());
      return targetPath;
    }
    
    // Return original path if compression fails
    return imagePath;
  }

  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'ar',
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        return [
          if (place.street?.isNotEmpty ?? false) place.street,
          if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
          if (place.locality?.isNotEmpty ?? false) place.locality,
          if (place.administrativeArea?.isNotEmpty ?? false) place.administrativeArea,
        ].where((e) => e != null).join('، ');
      }
      return 'موقع غير معروف';
    } catch (e) {
      return 'موقع غير معروف';
    }
  }

  static Future<String> formatDistance(double distanceInMeters) async {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} متر';
    } else {
      final kilometers = (distanceInMeters / 1000).toStringAsFixed(1);
      return '$kilometers كم';
    }
  }

  static Future<bool> checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return 'منذ ${(difference.inDays / 365).floor()} سنة';
    } else if (difference.inDays > 30) {
      return 'منذ ${(difference.inDays / 30).floor()} شهر';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'reported':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'متوفر';
      case 'reported':
        return 'تم الإبلاغ عن مشكلة';
      case 'pending':
        return 'قيد المراجعة';
      default:
        return 'غير معروف';
    }
  }
}