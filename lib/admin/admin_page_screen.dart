import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';

class AdminPageScreen extends StatefulWidget {
  const AdminPageScreen({super.key});

  @override
  _AdminPageScreenState createState() => _AdminPageScreenState();
}

class _AdminPageScreenState extends State<AdminPageScreen> {
  String? magnitude;
  String? depth;
  String? coordinates;
  String? location;
  String? time;
  String? shakemapUrl;
  String? weatherWarning;
  String? temperature;
  String? humidity;
  String? userName;
  String? earthquakeImpactWarning;
  Color impactColor = const Color(0xFFFFF3CD); // Default color
  Color textColor = const Color(0xFF856404); // Default text color

  @override
  void initState() {
    super.initState();
    fetchEarthquakeData();
    fetchWeatherData();
  }

  // Mengambil data gempa dari API BMKG
  Future<void> fetchEarthquakeData() async {
    const url = 'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var earthquake = data['Infogempa']['gempa'];

      setState(() {
        magnitude = earthquake['Magnitude'];
        depth = earthquake['Kedalaman'];
        coordinates = earthquake['Coordinates'];
        location = earthquake['Wilayah'];
        time = '${earthquake['Tanggal']} ${earthquake['Jam']}';
        shakemapUrl = earthquake['Shakemap'] != null
            ? 'https://data.bmkg.go.id/DataMKG/TEWS/${earthquake['Shakemap']}'
            : null;

        // Koordinat Surabaya
        const surabayaLat = -7.2575;
        const surabayaLon = 112.7521;

        // Koordinat gempa
        List<String> coords = coordinates!.split(',');
        double quakeLat = double.parse(coords[0]);
        double quakeLon = double.parse(coords[1]);

        // Hitung jarak dan tentukan skala dampak
        double distance = calculateDistance(surabayaLat, surabayaLon, quakeLat, quakeLon);
        String impactScale = determineImpactScale(distance);

        // Tampilkan peringatan dampak gempa
        earthquakeImpactWarning = 'Jarak gempa dari Surabaya: ${distance.toStringAsFixed(2)} km. $impactScale';

        // Tentukan warna berdasarkan skala dampak
        if (impactScale.contains('Tinggi')) {
          impactColor = Colors.red;
          textColor = Colors.white;
        } else if (impactScale.contains('Sedang')) {
          impactColor = const Color(0xFFFFF3CD); // Warna kuning
          textColor = const Color(0xFF856404);
        } else {
          impactColor = Colors.green;
          textColor = Colors.white;
        }
      });
    } else {
      setState(() {
        earthquakeImpactWarning = 'Gagal mengambil data gempa';
      });
    }
  }

  // Mengambil data cuaca dari API BMKG
  Future<void> fetchWeatherData() async {
    const weatherUrl = 'https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=35.78.09.1001';
    try {
      final response = await http.get(Uri.parse(weatherUrl));

      if (response.statusCode == 200) {
        var weatherData = jsonDecode(response.body);
        var currentWeather = weatherData['data'][0]['cuaca'][0][0];

        var weatherDesc = currentWeather['weather_desc'] ?? 'Tidak ada data';
        temperature = currentWeather['t'] != null ? '${currentWeather['t']} °C' : null;
        humidity = currentWeather['hu'] != null ? '${currentWeather['hu']}%' : null;

        String warningMessage = '';

        // Menyesuaikan pesan berdasarkan deskripsi cuaca
        if (weatherDesc == 'Cerah' || weatherDesc == 'Sunny') {
          warningMessage = 'Cuaca hari ini di Surabaya diperkirakan cerah. Meskipun demikian, kami menghimbau kepada seluruh warga untuk tetap waspada, mengingat prediksi cuaca tidak selalu dapat dipastikan akurat.';
        } else if (weatherDesc == 'Berawan' || weatherDesc == 'Cloudy') {
          warningMessage = 'Cuaca hari ini di Surabaya diperkirakan berawan. Kami menghimbau kepada seluruh warga untuk tetap waspada terhadap kemungkinan perubahan cuaca yang cepat.';
        } else if (weatherDesc == 'Hujan' || weatherDesc == 'Rainy') {
          warningMessage = 'Cuaca hari ini di Surabaya diperkirakan hujan. Kami menghimbau kepada seluruh warga untuk berhati-hati saat bepergian, dan disarankan untuk membawa payung atau mengenakan pelindung hujan guna menghindari ketidaknyamanan serta potensi bahaya akibat kondisi cuaca yang basah.';
        } else if (weatherDesc == 'Badai' || weatherDesc == 'Storm') {
          warningMessage = 'Cuaca buruk dengan badai terjadi di Surabaya. Kami menghimbau kepada seluruh warga untuk tetap berada di dalam rumah dan menghindari perjalanan yang tidak perlu demi keselamatan. Pastikan juga untuk memeriksa kondisi bangunan dan peralatan rumah untuk mengurangi risiko yang ditimbulkan oleh cuaca ekstrem ini.';
        } else {
          warningMessage = 'Cuaca tidak dapat diprediksi dengan akurat saat ini. Tetap berhati-hati dan waspada terhadap perubahan cuaca.';
        }

        setState(() {
          weatherWarning = warningMessage;
        });
      } else {
        setState(() {
          weatherWarning = 'Gagal mengambil data cuaca';
          temperature = null;
          humidity = null;
        });
      }
    } catch (e) {
      setState(() {
        weatherWarning = 'Terjadi kesalahan: ${e.toString()}';
        temperature = null;
        humidity = null;
      });
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // Radius bumi dalam km
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
      return 'Skala Dampak: 3 (Tinggi)';
    } else if (distance < 100) {
      return 'Skala Dampak: 2 (Sedang)';
    } else {
      return 'Skala Dampak: 1 (Rendah)';
    }
  }

  Future<void> _logout() async {
    // Hapus informasi sesi atau token
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Arahkan ke halaman login
    Navigator.pushReplacementNamed(context, '/login');
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return; // Do nothing if the current index is selected
    }

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/admin_home', arguments: {'name': userName});
    } else if (index == 1) {
      Navigator.pushNamed(context, '/admin_updates', arguments: {'name': userName});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    userName = args?['name'];

    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 162, 155, 180),
        title: Text(
          'EvacNow Admin',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900, // Montserrat Black
          ),
        ),
        centerTitle: true,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.white),
          offset: const Offset(0, 40), // Menggeser posisi popup ke bawah ikon
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PERINGATAN DINI CUACA',
                style: TextStyle(fontSize: 18, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(FontAwesomeIcons.exclamationTriangle, color: Color(0xFF856404), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weatherWarning ?? 'Mengambil data cuaca...',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF856404)),
                          ),
                          const SizedBox(height: 5), // Jarak vertikal antara peringatan dan informasi suhu
                          Row(
                            children: [
                              const Text(
                                'Suhu: ',
                                style: TextStyle(fontSize: 14, color: Color(0xFF856404)),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                temperature ?? 'Loading...',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                'Kelembapan: ',
                                style: TextStyle(fontSize: 14, color: Color(0xFF856404)),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                humidity ?? 'Loading...',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'GEMPABUMI TERKINI',
                style: TextStyle(fontSize: 18, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: impactColor, // Warna berdasarkan skala dampak
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(FontAwesomeIcons.exclamationTriangle, color: textColor, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            earthquakeImpactWarning ?? 'Mengambil data gempa...',
                            style: TextStyle(fontSize: 14, color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (shakemapUrl != null)
                      Image.network(
                        shakemapUrl!,
                        fit: BoxFit.fitWidth,
                        width: double.infinity,
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoColumn('Magnitude', magnitude, Colors.red),
                        SizedBox(width: screenWidth * 0.05),
                        _buildInfoColumn('Kedalaman', depth, Colors.green),
                        SizedBox(width: screenWidth * 0.05),
                        _buildInfoColumn('Koordinat', coordinates, Colors.yellow),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Mengurangi ketebalan garis horizontal
                    const Divider(
                      color: Colors.grey,
                      thickness: 0.5,  // Ketebalan garis diubah menjadi lebih tipis
                      height: 20,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRowWithIcon(FontAwesomeIcons.mapMarkerAlt, 'Lokasi', location),
                    const SizedBox(height: 10),
                    _buildInfoRowWithIcon(FontAwesomeIcons.clock, 'Waktu', time),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/evacuation', arguments: {'name': userName});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 197, 78, 62),
                    padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 65),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Set Alert',
                    style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 162, 155, 180),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.syncAlt),
            label: 'Updates',
          ),
        ],
      ),
    );
  }

  /// Fungsi untuk menampilkan kolom informasi dengan judul di atas nilai dan warna value yang berbeda
  Widget _buildInfoColumn(String title, String? value, Color valueColor) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Data not available',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,  // Menerapkan warna berdasarkan kategori
            ),
          ),
        ],
      ),
    );
  }

  /// Fungsi untuk menampilkan baris informasi dengan ikon berwarna merah
  Widget _buildInfoRowWithIcon(IconData icon, String title, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? 'Data not available',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}