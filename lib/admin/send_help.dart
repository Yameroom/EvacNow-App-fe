import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SendHelp extends StatefulWidget {
  final int requestId;
  final String name;
  final String date;
  final double latitude;
  final double longitude;
  final String status;

  const SendHelp({
    super.key,
    required this.requestId,
    required this.name,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  @override
  _SendHelpState createState() => _SendHelpState();
}

class _SendHelpState extends State<SendHelp> {
  bool isLoading = false;
  // ignore: unused_field
  late GoogleMapController _mapController;

  Future<void> _updateRequestStatus() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://192.168.177.120/evacnow1/update_request_status.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'id': widget.requestId.toString(),
          'status': 'Tim penyelamat dalam perjalanan',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status permintaan berhasil diperbarui')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal memperbarui status permintaan')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error: ${response.statusCode}')),
        );
      }
    } on TimeoutException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan waktu habis. Silakan coba lagi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String title, String value, {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 162, 155, 180),
      title: Text(
        'Send Help',
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(
        color: Colors.white, // Mengubah warna tombol back menjadi putih
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Icon(Icons.person, color: Colors.white),
        ),
      ],
    ),

      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Google Map Section
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(widget.latitude, widget.longitude),
                                zoom: 16
                                ,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('userLocation'),
                                  position: LatLng(widget.latitude, widget.longitude),
                                  infoWindow: const InfoWindow(title: 'Lokasi Terakhir'),
                                ),
                              },
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Section Title
                        Text(
                          'Identitas dan data pengguna',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey, // Abu-abu
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Info Section
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
                              _buildInfoRow('Nama/Username', widget.name),
                              _buildInfoRow('Waktu Permintaan', widget.date),
                              _buildInfoRow(
                                'Lokasi Terakhir',
                                'Latitude: ${widget.latitude}\nLongitude: ${widget.longitude}',
                                icon: Icons.location_on,
                                iconColor: Colors.red,
                              ),
                              _buildInfoRow(
                                'Status',
                                widget.status,
                                icon: Icons.access_time,
                                iconColor: Colors.red,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Button Section
                        Center(
                          child: ElevatedButton(
                            onPressed: widget.status != 'Tim penyelamat dalam perjalanan'
                                ? _updateRequestStatus
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, // Merah
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'Kirim Bantuan',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
