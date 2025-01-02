import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('http://192.168.177.120/evacnow1/login.php');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': email,
          'password': password,
        },
      );

      final data = jsonDecode(response.body);
      setState(() {
        isLoading = false;
      });

      if (data['success']) {
        final name = data['name'] ?? 'User'; // Pastikan nama tidak null
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
        content: Text(
          'Login berhasil, Selamat datang $name',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
          ),
        );

        // Simpan informasi sesi atau token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', name);

        if (data['role'] == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_home', arguments: {
            'user_id': data['user_id'],
            'name': name,
          });
        } else {
          Navigator.pushReplacementNamed(context, '/user_home', arguments: {
            'user_id': data['user_id'],
            'name': name,
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat login')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 162, 155, 180),
        elevation: 0,
        automaticallyImplyLeading: false, // Menghilangkan tombol back
        title: Text(
          'EvacNow',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900, // Montserrat Black
          ),
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Log In',
                  style: GoogleFonts.montserrat(
                    fontSize: 40, // Memperbesar ukuran font
                    fontWeight: FontWeight.w900, // Montserrat Black
                    color: const Color.fromARGB(255, 96, 87, 105),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 162, 155, 180), // Warna yang sama dengan AppBar
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Input Email
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Masukkan email Anda',
                          hintStyle: GoogleFonts.montserrat(),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Input Password
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password Anda',
                          hintStyle: GoogleFonts.montserrat(),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Tombol Login
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
                              onPressed: login,
                              child: Text(
                                'Login',
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      const SizedBox(height: 10),
                      // Link Sign Up
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: Text(
                          'Belum punya akun? Sign up',
                          style: GoogleFonts.montserrat(
                            color: const Color.fromARGB(255, 0, 70, 128),
                            fontWeight: FontWeight.normal,
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
    );
  }
}