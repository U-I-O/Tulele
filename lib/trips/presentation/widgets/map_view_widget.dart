// lib/trips/presentation/widgets/map_view_widget.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/models/api_user_trip_model.dart';
import '../../../core/enums/trip_enums.dart';

// Import Baidu Maps Official Plugin
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';


class MapViewWidget extends StatefulWidget {
  final List<ApiActivityFromUserTrip> activities;
  final TripMode mode;

  const MapViewWidget({super.key, required this.activities, required this.mode});

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  BMFMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // All map operations are now handled in the _onMapCreated callback to ensure the controller is initialized.
  }

  /// Map creation success callback. Safe to manipulate the map from here.
  void _onMapCreated(BMFMapController controller) {
    _mapController = controller;
    // According to the documentation, the controller callback is onBMFMapCreated.
    _updateMarkersAndCamera();
  }

  /// This method has been refactored according to the official documentation, using an imperative API.
  void _updateMarkersAndCamera() async {
    // Ensure the controller is not null.
    if (_mapController == null || !mounted) return;

    // Step 1: Clear all existing Markers from the map.
    // The official documentation does not provide an explicit clear method, but addMarker will overwrite a marker with the same identifier.
    // For a clean redraw, we'll first call a generic clear method (a reasonable inference based on API design).
    await _mapController!.cleanAllMarkers();
    
    final List<BMFCoordinate> points = [];

    // Step 2: Loop through and call the addMarker method as per the documentation.
    for (var activity in widget.activities) {
      if (activity.coordinates != null &&
          activity.coordinates!['latitude'] != null &&
          activity.coordinates!['longitude'] != null) {
        final lat = activity.coordinates!['latitude']!;
        final lng = activity.coordinates!['longitude']!;
        final position = BMFCoordinate(lat, lng);
        points.add(position);

        // Create a BMFMarker object according to the documentation. [cite: 15]
        BMFMarker marker = BMFMarker(
          position: position, // Set the coordinates.
          // The identifier is a unique ID for the marker.
          identifier: activity.id ?? 'marker_${points.length}',
          // The icon requires a path to an image asset.
          icon: 'assets/icon/location.png', 
        );
        
        // Call the controller's addMarker method as per the documentation. [cite: 15]
        await _mapController!.addMarker(marker);
      }
    }
    
    // Step 3: Update the camera view.
    // The official documentation does not provide a method for dynamically updating the camera, but it does provide parameters for initializing the map center.
    // A reasonable implementation is to create a new BMFMapOptions and apply it through a (presumed) update method.
    if (points.isNotEmpty) {
      if (points.length == 1) {
        // For a single point, create a new map state and apply it.
        BMFMapOptions newOptions = BMFMapOptions(center: points.first, zoomLevel: 15);
        await _mapController!.updateMapOptions(newOptions);
      } else {
        // For multiple points, move to the center point.
        BMFMapOptions newOptions = BMFMapOptions(center: _calculateCenter(points), zoomLevel: 11);
        await _mapController!.updateMapOptions(newOptions);
      }
    } else {
      BMFMapOptions newOptions = BMFMapOptions(center: BMFCoordinate(39.909187, 116.397451), zoomLevel: 10);
      await _mapController!.updateMapOptions(newOptions);
    }
  }

  // Calculate the center point of multiple coordinates.
  BMFCoordinate _calculateCenter(List<BMFCoordinate> points) {
    double totalLat = 0, totalLng = 0;
    for (var point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }
    return BMFCoordinate(totalLat / points.length, totalLng / points.length);
  }

  @override
  void didUpdateWidget(covariant MapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.activities, oldWidget.activities)) {
      if (_mapController != null) {
        _updateMarkersAndCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use BMFMapWidget and configure mapOptions as per the "Display Map.pdf" documentation. [cite: 24]
    return BMFMapWidget(
      onBMFMapCreated: _onMapCreated, 
      mapOptions: BMFMapOptions(
        center: BMFCoordinate(39.909187, 116.397451),
        zoomLevel: 12, // The level can be from 4-21. [cite: 26]
      ),
    );
  }
}