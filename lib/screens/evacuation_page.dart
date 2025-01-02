import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EvacuationPage extends StatefulWidget {
  const EvacuationPage({super.key});

  @override
  _EvacuationPageState createState() => _EvacuationPageState();
}

class _EvacuationPageState extends State<EvacuationPage> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  LatLng? _nearestEvacuation;
  List<Marker> _markers = [];
  final Set<Polyline> _polylines = {}; 
  String? userName;

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then((_) {
      getPolylinePoints().then((coordinates) {
        generatePolyLineFromPoints(coordinates);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    userName = args?['name'];
  }

  // Mengambil lokasi gps userr
  Future<void> getLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });

    _findNearestEvacuation();
  }

  // mencari koordinat rute
  Future<List<LatLng>> getPolylinePoints() async {
    if (_userLocation == null || _nearestEvacuation == null) return [];

    String apiKey = 'YOUR API KEY'; 
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_userLocation!.latitude},${_userLocation!.longitude}&destination=${_nearestEvacuation!.latitude},${_nearestEvacuation!.longitude}&mode=walking&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('API Response: $data');  

      if (data['status'] == 'OK') {
        List<LatLng> polylinePoints = _decodePolyline(data['routes'][0]['overview_polyline']['points']);
        return polylinePoints;
      } else {
        print('Error: ${data['status']}');
        return [];
      }
    } else {
      print('API request failed with status code: ${response.statusCode}');
      return [];
    }
  }

  // Fungsi yang mengubah data jalur menjadi koordinat yang bisa di gambar di tampilan maps
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index) - 63;
        index++;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index) - 63;
        index++;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      LatLng point = LatLng(lat / 1E5, lng / 1E5);
      polyline.add(point);
    }

    return polyline;
  }

  // Fungsi untuk menambahkan polyline pada peta
  void generatePolyLineFromPoints(List<LatLng> polylinePoints) {
    if (polylinePoints.isEmpty) return;

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: polylinePoints,
        color: Colors.blue,
        width: 5,
      ));
    });
    _zoomToMidPoint(_userLocation!, _nearestEvacuation!);  
  }

  // Fungsi untuk menghitung zoom berdasarkan jarak agar tidak terlalu jauh
  double _calculateZoomLevel(double distanceInKm) {
    if (distanceInKm < 1) {
      return 16.0; // satuan kilometer
    } else if (distanceInKm < 5) {
      return 14.0; 
    } else {
      return 12.0; 
    }
  }

  // Fungsi menyesuaikan zoom point maps
  void _zoomToMidPoint(LatLng userLocation, LatLng evacuationLocation) {
    LatLng midPoint = _calculateMidPoint(userLocation, evacuationLocation);

    // Menghitung jarak dua lokasi
    double distance = _calculateDistance(userLocation, evacuationLocation);
    
    // Menghitung zoom level berdasarkan jarak
    double zoomLevel = _calculateZoomLevel(distance);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: midPoint,
          zoom: zoomLevel, 
        ),
      ),
    );
  }

  // Fungsi untuk menghitung jarak dua lokasi
  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371; // Radius bumi dalam km
    double dLat = (end.latitude - start.latitude) * (pi / 180);
    double dLng = (end.longitude - start.longitude) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * (pi / 180)) *
            cos(end.latitude * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return 2 * earthRadius * asin(sqrt(a));
  }

  // Fungsi untuk menghitung titik tengah antara dua lokasi digunakan untuk mengatur zoom level
  LatLng _calculateMidPoint(LatLng start, LatLng end) {
    double midLat = (start.latitude + end.latitude) / 2;
    double midLng = (start.longitude + end.longitude) / 2;
    return LatLng(midLat, midLng);
  }

  // Mendapatkan lokasi evakuasi terdekat
  void _findNearestEvacuation() {
    if (_userLocation == null) return;

    const evacuationPlaces = [
      {'name': 'Lapangan Tugu Pahlawan', 'lat': -7.2458, 'lng': 112.7378},
      {'name': 'Lapangan Kodam Brawijaya', 'lat': -7.2758, 'lng': 112.7288},
      {'name': 'Taman Bungkul', 'lat': -7.2839, 'lng': 112.7383},
      {'name': 'Taman Harmoni', 'lat': -7.295024567906063, 'lng': 112.80361460886976},
      {'name': 'Masjid Darul Hijrah', 'lat': -7.288857313292945, 'lng': 112.80340137728179},
      {'name': 'Bundaran ITS','lat': -7.274528140603375, 'lng': 112.79781773858011},
      {'name': 'Bundaran ITS Gebang', 'lat':-7.279246495717793, 'lng':112.79041897897991},
    ];

    //menghitung jarak distance
    double calculateDistance(LatLng start, LatLng end) {
      const earthRadius = 6371; 
      double dLat = (end.latitude - start.latitude) * (pi / 180);
      double dLng = (end.longitude - start.longitude) * (pi / 180);
      double a = sin(dLat / 2) * sin(dLat / 2) +
          cos(start.latitude * (pi / 180)) *
              cos(end.latitude * (pi / 180)) *
              sin(dLng / 2) *
              sin(dLng / 2);
      return 2 * earthRadius * asin(sqrt(a));
    }

    //untuk mengupdate tanda ke lokasi terdekat bila ada jarak yang lebih dekat dengan user
    double? shortestDistance;
    for (var place in evacuationPlaces) {
      LatLng placeLatLng = LatLng(place['lat'] as double, place['lng'] as double);
      double distance = calculateDistance(_userLocation!, placeLatLng);

      if (shortestDistance == null || distance < shortestDistance) {
        shortestDistance = distance;
        _nearestEvacuation = placeLatLng;
      }
    }

    _updateMarkers();
  }

  void _updateMarkers() {
    if (_userLocation == null || _nearestEvacuation == null) return;

    _markers = [
      Marker(
        markerId: const MarkerId('user'),
        position: _userLocation!,
        infoWindow: const InfoWindow(title: 'Lokasi Anda'),
      ),
      Marker(
        markerId: const MarkerId('evacuation'),
        position: _nearestEvacuation!,
        infoWindow: const InfoWindow(title: 'Evakuasi Terdekat'),
      ),
    ];

    setState(() {});
  }

  int _selectedIndex = 0;

 //mencegah refresh saat menekan icon di halaman yang sama
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; 
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/evacuation', arguments: {'name': userName});
    } else if (index == 1) {
      Navigator.pushNamed(context, '/user_home', arguments: {'name': userName});
    } else if (index == 2) {
      Navigator.pushNamed(context, '/help_request', arguments: {'name': userName});
    }
  }

  Future<void> _logout() async {
    // Hapus informasi sesi dari user saat logout
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // diarahkan ke halaman login
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 162, 155, 180),
        title: Text(
          'EvacNow',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900, 
          ),
        ),
        centerTitle: true,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.white),
          offset: const Offset(0, 40), 
          onSelected: (String result) {
            if (result == 'logout') {
              _logout();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        ),
          actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
      body: _userLocation == null || _nearestEvacuation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation!,
                zoom: 14,
              ),
              markers: Set.from(_markers),
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
                _zoomToMidPoint(_userLocation!, _nearestEvacuation!);
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 162, 155, 180),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Evakuasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.syncAlt),
            label: 'Bantuan',
          ),
        ],
      ),
    );
  }
}
