import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class HelpRequestPage extends StatefulWidget {
  const HelpRequestPage({super.key});

  @override
  _HelpRequestPageState createState() => _HelpRequestPageState();
}

class _HelpRequestPageState extends State<HelpRequestPage> {
  bool isLoading = false;
  String? userName;
  Position? userLocation;
  List<Map<String, String>> requestStatusList = [];
  String? earthquakeCoordinates;
  String? impactScale;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    userName = args?['name'];
    _fetchRequestStatus();
  }

  Future<void> _initializeData() async {
    await _getUserLocation();
    await fetchEarthquakeData();
    if (userLocation != null && earthquakeCoordinates != null) {
      // Koordinat Surabaya
      const surabayaLat = -7.2575;
      const surabayaLon = 112.7521;

      // Koordinat gempa dari api
      List<String> coords = earthquakeCoordinates!.split(',');
      double quakeLat = double.parse(coords[0]);
      double quakeLon = double.parse(coords[1]);

      // menghitung jarak dan menentukan skala dampak
      double distance = calculateDistance(surabayaLat, surabayaLon, quakeLat, quakeLon);
      setState(() {
        impactScale = determineImpactScale(distance);
      });
    }
  }

  //mengambil data lokasi user dari gps
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    //meminta izin untuk mengaktifkan lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      userLocation = position;
    });
  }

  //mengambil koordinat gempa terkini dari api
  Future<void> fetchEarthquakeData() async {
    const url = 'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var earthquake = data['Infogempa']['gempa'];
      setState(() {
        earthquakeCoordinates = earthquake['Coordinates'];
      });
    } else {
      setState(() {
        impactScale = 'Gagal mengambil data gempa';
      });
    }
  }

//mengambil data status dari database
  Future<void> _fetchRequestStatus() async {
    final url = Uri.parse('http://192.168.177.120/evacnow1/get_request_status.php');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': userName!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        requestStatusList = List<Map<String, String>>.from(
          data['statusList'].map((item) => Map<String, String>.from(item)),
        ).take(2).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil status permintaan: ${response.statusCode}')),
      );
    }
  }
 //jika nilai null
  Future<void> sendHelpRequest() async {
    if (userLocation == null || userName == null || impactScale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi, nama pengguna, atau skala dampak tidak tersedia')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });
    
    //untuk membuat help request ke database dengan memberi data
    final url = Uri.parse('http://192.168.177.120/evacnow1/help_request.php');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': userName!,
        'latitude': userLocation!.latitude.toString(),
        'longitude': userLocation!.longitude.toString(),
        'date': DateTime.now().toIso8601String(),
        'status': 'Admin belum menyetujui',
        'impact_scale': impactScale!, 
      },
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan bantuan berhasil dikirim')),
        );
        _fetchRequestStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal mengirim permintaan bantuan')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server Error: ${response.statusCode}')),
      );
    }
  }

  //menghitung jarak lokasi surabaya dengan lokasi koordinat gempa terkini untuk skala dampak (impact scale)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  String determineImpactScale(double distance) {
    if (distance < 50) {
      return '3';
    } else if (distance < 100) {
      return '2';
    } else {
      return '1';
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamed(context, '/evacuation', arguments: {'name': userName});
    } else if (index == 1) {
      Navigator.pushNamed(context, '/user_home', arguments: {'name': userName});
    } else if (index == 2) {
      // agar tidak terefresh saat sudah di halaman tersebut
    }
  }

  //untuk logout dari sesi dan kembali ke halaman user
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Help Request',
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 214, 208, 231),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nama: $userName',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lokasi: ${userLocation?.latitude}, ${userLocation?.longitude}',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Skala Dampak: $impactScale',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Status:',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: requestStatusList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              requestStatusList[index]['status']!,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              requestStatusList[index]['date']!,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[700],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: sendHelpRequest,
                              child: Text(
                                'Kirim Permintaan Bantuan',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 162, 155, 180),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 2,
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