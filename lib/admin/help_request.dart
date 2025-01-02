import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'send_help.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpRequest extends StatefulWidget {
  const HelpRequest({super.key});

  @override
  _HelpRequestState createState() => _HelpRequestState();
}

class _HelpRequestState extends State<HelpRequest> {
  String? userName;
  List<Map<String, dynamic>> requestList = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    userName = args?['name'];
    _fetchRequestList();
  }

  Future<void> _fetchRequestList() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse('http://192.168.177.120/evacnow1/get_all_requests.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          requestList = List<Map<String, dynamic>>.from(data['statusList']);
        });
      } else {
        setState(() {
          errorMessage = 'Gagal mengambil daftar permintaan: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan saat mengambil data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteRequest(int requestId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('http://192.168.177.120/evacnow1/delete_request.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': requestId.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permintaan berhasil dihapus')),
          );
          _fetchRequestList(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal menghapus permintaan')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error: ${response.statusCode}')),
        );
      }
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // ignore: use_build_context_synchronously
    Navigator.pushReplacementNamed(context, '/login');
  }

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return; 
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
    return Scaffold(
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
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
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
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : Column(
                    children: [
                      // Content Section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'STATUS HELP REQUEST',
                                style: TextStyle(
                                  color: Color(0xFF7D7D7D),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: requestList.length,
                                  itemBuilder: (context, index) {
                                    final request = requestList[index];
                                    return _requestItem(request, context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

  Widget _requestItem(Map<String, dynamic> request, BuildContext context) {
    return Card(
      color: const Color(0xFFF5F5F5), // Warna latar belakang yang lebih kalem
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFB0B0B0), // Warna latar belakang avatar
          child: Text(
            request['name'][0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          request['name'],
          style: const TextStyle(color: Color(0xFF333333)), // Warna teks judul
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${request['status']}', style: const TextStyle(color: Color(0xFF666666))), // Warna teks subtitle
            Text('Tanggal: ${request['date']}', style: const TextStyle(color: Color(0xFF666666))), // Warna teks subtitle
            Text('Skala Dampak: ${request['impact_scale']}', style: const TextStyle(color: Color(0xFF666666))), // Warna teks subtitle
          ],
        ),
        trailing: request['status'] == 'Tim penyelamat dalam perjalanan'
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _deleteRequest(int.parse(request['id'].toString()));
                },
              )
            : null,
        onTap: () {
          final requestId = int.tryParse(request['id'].toString()) ?? -1;
          if (requestId != -1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SendHelp(
                  requestId: requestId,
                  name: request['name'],
                  date: request['date'],
                  latitude: double.parse(request['latitude'].toString()),
                  longitude: double.parse(request['longitude'].toString()),
                  status: request['status'],
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ID request tidak valid')),
            );
          }
        },
      ),
    );
  }
}