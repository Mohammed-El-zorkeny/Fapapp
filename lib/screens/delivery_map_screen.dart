import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/app_colors.dart';
import '../services/api_service.dart';

class DeliveryMapScreen extends StatefulWidget {
  final int invoiceId;
  final String customerName;
  final String locationLink;
  final String governorateName;
  final String districtName;
  final String fullAddress;

  const DeliveryMapScreen({
    super.key,
    required this.invoiceId,
    required this.customerName,
    required this.locationLink,
    required this.governorateName,
    required this.districtName,
    required this.fullAddress,
  });

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  final String _googleMapsApiKey = 'AIzaSyA8NdDD7cUCWx_OIvDi0A8EApwA2Bll_sg';
  final ApiService _apiService = ApiService();
  final Battery _battery = Battery();

  GoogleMapController? _mapController;
  LatLng? _salesmanLocation;
  LatLng? _customerLocation;
  bool _isLoading = true;
  String _loadingMessage = 'جاري تحديد موقعك الجغرافي...';

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  String _distanceText = '--';
  String _durationText = '--';

  BitmapDescriptor? _carIcon;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _startMapFlow();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startMapFlow() async {
    try {
      // 1. Load custom car marker icon
      await _loadCustomIcons();

      // 2. Get Salesman Location (GPS)
      setState(() => _loadingMessage = 'جاري الحصول على إحداثيات GPS الخاصة بك...');
      final position = await _getSalesmanCurrentLocation();
      if (position != null) {
        _salesmanLocation = LatLng(position.latitude, position.longitude);
      }

      if (_salesmanLocation == null) {
        throw Exception('تعذر تحديد موقع GPS للمندوب. يرجى تفعيل الموقع.');
      }

      // 3. Resolve Customer Location
      setState(() => _loadingMessage = 'جاري الحصول على موقع العميل...');
      _customerLocation = _parseCoordinates(widget.locationLink);

      if (_customerLocation == null) {
        // Fallback to geocoding address components
        setState(() => _loadingMessage = 'لم يتم العثور على إحداثيات للعميل. جاري تحويل عنوان العميل لموقع جغرافي...');
        _customerLocation = await _geocodeAddress();
      }

      if (_customerLocation == null) {
        throw Exception('تعذر تحديد موقع العميل. يرجى التأكد من عنوان العميل');
      }

      // 4. Get Route and Distance from Directions API
      setState(() => _loadingMessage = 'جاري رسم خط السير ومسار الطريق...');
      await _fetchRouteAndDraw();

      // 5. Build Initial Markers
      _updateMarkers(0.0);

      setState(() => _isLoading = false);

      // Fit bounds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapBounds();
      });

      // 6. Start listening to live location changes (GPS tracking + DB logging)
      _startLiveTracking();

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الخريطة: ${e.toString().replaceAll('Exception:', '')}', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomIcons() async {
    try {
      _carIcon = await getBitmapDescriptorFromAsset('assets/images/car_icon.png', 80); // 80 pixels wide
    } catch (e) {
      debugPrint('Failed to load custom car icon, using default: $e');
    }
  }

  Future<BitmapDescriptor> getBitmapDescriptorFromAsset(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _startLiveTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15, // Update location every 15 meters to conserve bandwidth/battery
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final lastLat = prefs.getDouble('last_lat_${widget.invoiceId}');
        final lastLng = prefs.getDouble('last_lng_${widget.invoiceId}');

        double distanceInMeters = 0.0;
        double bearing = 0.0;
        if (lastLat != null && lastLng != null) {
          distanceInMeters = Geolocator.distanceBetween(
            lastLat,
            lastLng,
            position.latitude,
            position.longitude,
          );
          bearing = Geolocator.bearingBetween(
            lastLat,
            lastLng,
            position.latitude,
            position.longitude,
          );
        }

        // Add to cumulative distance
        final currentDistance = prefs.getDouble('distance_${widget.invoiceId}') ?? 0.0;
        final newDistance = currentDistance + (distanceInMeters / 1000.0);
        await prefs.setDouble('distance_${widget.invoiceId}', newDistance);

        // Update last recorded lat/lng
        await prefs.setDouble('last_lat_${widget.invoiceId}', position.latitude);
        await prefs.setDouble('last_lng_${widget.invoiceId}', position.longitude);

        // Get battery telemetry
        int batteryLevel = 100;
        bool isCharging = false;
        try {
          batteryLevel = await _battery.batteryLevel;
          final state = await _battery.batteryState;
          isCharging = state == BatteryState.charging;
        } catch (e) {
          debugPrint('Battery info error: $e');
        }

        // Save and synchronize tracking point (offline caching queue)
        await _saveAndSyncPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          bearing: bearing,
          batteryLevel: batteryLevel,
          isCharging: isCharging,
        );

        setState(() {
          _salesmanLocation = LatLng(position.latitude, position.longitude);
          _updateMarkers(bearing);
        });
        _fetchRouteAndDraw(); // Recalculate routes and updates floating text
      }
    });
  }

  Future<void> _saveAndSyncPoint({
    required double latitude,
    required double longitude,
    required double bearing,
    required int batteryLevel,
    required bool isCharging,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'offline_points_${widget.invoiceId}';
      
      // 1. Create point map
      final point = {
        'latitude': latitude,
        'longitude': longitude,
        'bearing': bearing,
        'batteryLevel': batteryLevel,
        'isCharging': isCharging,
      };

      // 2. Load current offline points list
      final List<String> offlineList = prefs.getStringList(key) ?? [];
      offlineList.add(json.encode(point));
      await prefs.setStringList(key, offlineList);

      // 3. Try to sync all cached points sequentially
      final List<String> remainingList = List.from(offlineList);
      bool hasError = false;

      for (final pointStr in offlineList) {
        if (hasError) break;
        final pointData = json.decode(pointStr);
        try {
          final response = await _apiService.addTrackingPoint(
            invoiceId: widget.invoiceId,
            latitude: pointData['latitude'],
            longitude: pointData['longitude'],
            bearing: pointData['bearing'],
            batteryLevel: pointData['batteryLevel'],
            isCharging: pointData['isCharging'],
          );
          if (response['success']) {
            remainingList.remove(pointStr);
          } else {
            hasError = true;
          }
        } catch (_) {
          hasError = true;
        }
      }
      
      // 4. Update the stored cache with remaining unsynced points
      await prefs.setStringList(key, remainingList);
    } catch (e) {
      debugPrint('Offline sync error: $e');
    }
  }

  void _updateMarkers(double bearing) {
    if (_salesmanLocation == null || _customerLocation == null) return;

    setState(() {
      _markers.clear();
      
      // Salesman (Car) Marker
      _markers.add(
        Marker(
          markerId: const MarkerId('salesman'),
          position: _salesmanLocation!,
          infoWindow: const InfoWindow(title: 'موقعي الحالي (السيارة)'),
          icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: bearing,
          anchor: const Offset(0.5, 0.5),
        ),
      );

      // Customer Location Pin Marker
      _markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLocation!,
          infoWindow: InfoWindow(title: widget.customerName, snippet: widget.fullAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  Future<Position?> _getSalesmanCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  LatLng? _parseCoordinates(String url) {
    if (url.isEmpty) return null;
    try {
      // e.g. https://maps.google.com/?q=30.123,31.456 or similar
      final regExp = RegExp(r'[?&]q=([-+]?\d*\.\d+|\d+),([-+]?\d*\.\d+|\d+)');
      final match = regExp.firstMatch(url);
      if (match != null) {
        final lat = double.tryParse(match.group(1)!);
        final lng = double.tryParse(match.group(2)!);
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }

      // e.g. maps.google.com/maps/dir/30.123,31.456
      final regExpDirect = RegExp(r'/([-+]?\d*\.\d+|\d+),([-+]?\d*\.\d+|\d+)');
      final matchDirect = regExpDirect.firstMatch(url);
      if (matchDirect != null) {
        final lat = double.tryParse(matchDirect.group(1)!);
        final lng = double.tryParse(matchDirect.group(2)!);
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('Parse coordinates error: $e');
    }
    return null;
  }

  Future<LatLng?> _geocodeAddress() async {
    final queryComponents = [
      widget.governorateName,
      widget.districtName,
      widget.fullAddress
    ].where((s) => s.isNotEmpty).join(' ');

    if (queryComponents.isEmpty) return null;

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(queryComponents)}&key=$_googleMapsApiKey&language=ar');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          return LatLng(loc['lat'], loc['lng']);
        }
      }
    } catch (e) {
      debugPrint('Geocode address error: $e');
    }
    return null;
  }

  Future<void> _fetchRouteAndDraw() async {
    if (_salesmanLocation == null || _customerLocation == null) return;

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_salesmanLocation!.latitude},${_salesmanLocation!.longitude}&destination=${_customerLocation!.latitude},${_customerLocation!.longitude}&key=$_googleMapsApiKey&language=ar');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final pointsStr = route['overview_polyline']['points'] as String;
          final decodedPoints = _decodePolyline(pointsStr);
          
          // Get distance and duration from API response
          String distance = '--';
          String duration = '--';
          if ((route['legs'] as List).isNotEmpty) {
            final leg = route['legs'][0];
            distance = leg['distance']['text'] ?? '--';
            duration = leg['duration']['text'] ?? '--';
          }
          
          setState(() {
            _distanceText = distance;
            _durationText = duration;
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: decodedPoints,
                color: Colors.blue.shade700,
                width: 6,
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Directions API error: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void _fitMapBounds() {
    if (_mapController == null || _salesmanLocation == null || _customerLocation == null) return;

    LatLngBounds bounds;
    if (_salesmanLocation!.latitude > _customerLocation!.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(_customerLocation!.latitude, _salesmanLocation!.longitude < _customerLocation!.longitude ? _salesmanLocation!.longitude : _customerLocation!.longitude),
        northeast: LatLng(_salesmanLocation!.latitude, _salesmanLocation!.longitude > _customerLocation!.longitude ? _salesmanLocation!.longitude : _customerLocation!.longitude),
      );
    } else {
      bounds = LatLngBounds(
        southwest: LatLng(_salesmanLocation!.latitude, _salesmanLocation!.longitude < _customerLocation!.longitude ? _salesmanLocation!.longitude : _customerLocation!.longitude),
        northeast: LatLng(_customerLocation!.latitude, _salesmanLocation!.longitude > _customerLocation!.longitude ? _salesmanLocation!.longitude : _customerLocation!.longitude),
      );
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'خريطة التوصيل للعميل',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: _isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      _loadingMessage,
                      style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textDark),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // 1. Google Map Widget
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitMapBounds();
                  },
                  initialCameraPosition: CameraPosition(
                    target: _salesmanLocation ?? const LatLng(30.0444, 31.2357),
                    zoom: 12,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                // 2. Floating Live Distance & Time Panel (Top of the map)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.directions_car, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'المسافة المتبقية',
                                    style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _distanceText,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 35, color: Colors.grey.shade300),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time_filled, color: Colors.orange.shade700, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'زمن الوصول المتوقع',
                                    style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _durationText,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Floating Bottom Info Card
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.customerName,
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.fullAddress.isNotEmpty ? widget.fullAddress : '${widget.governorateName} - ${widget.districtName}',
                                  style: GoogleFonts.cairo(color: Colors.grey.shade700, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                            label: Text('تركيز الخريطة على المسار', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            onPressed: _fitMapBounds,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Floating Compass Re-center Button
                Positioned(
                  bottom: 200,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    onPressed: () {
                      if (_salesmanLocation != null && _mapController != null) {
                        double currentBearing = 0.0;
                        try {
                          final salesMarker = _markers.firstWhere((m) => m.markerId.value == 'salesman');
                          currentBearing = salesMarker.rotation;
                        } catch (_) {}
                        _mapController!.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: _salesmanLocation!,
                              zoom: 16.5,
                              bearing: currentBearing,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.explore, size: 24),
                  ),
                ),
              ],
            ),
    );
  }
}
