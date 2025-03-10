import 'package:flutter/material.dart';
import 'package:waterfinder/models/water_source.dart';
import 'package:waterfinder/utils/helpers.dart';

class WaterSourceMarker extends StatelessWidget {
  final WaterSource source;
  final VoidCallback? onTap;

  const WaterSourceMarker({
    super.key,
    required this.source,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26), // 0.1 opacity = 26 in alpha (255 * 0.1)
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop,
                  color: AppHelpers.getStatusColor(source.status),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  source.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.location_on,
            color: AppHelpers.getStatusColor(source.status),
            size: 32,
          ),
        ],
      ),
    );
  }
}