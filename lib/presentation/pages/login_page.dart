import 'package:flutter/material.dart';
import '../../data/datasources/database_helper.dart';
import 'data_fisik_page.dart';
import 'main_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true; // State untuk show/hide password

  void _handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan Password wajib diisi!')),
      );
      return;
    }

    try {
      final user = await DatabaseHelper.instance.loginUser(username, password);

      if (user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selamat Datang, ${user['username']}!')),
          );

          // ===================================================================
          // LOGIKA SKRIPSI: CEK APAKAH USER SUDAH PERNAH ISI DATA FISIK (BB/TB)
          // ===================================================================
          final userProfile =
              await DatabaseHelper.instance.getUserProfile(user['id']);

          if (mounted) {
            if (userProfile != null && userProfile['weight'] != null) {
              // ALUR A: Hitung TDEE dari data profil, lalu loncat ke Dashboard Utama
              final double weight = (userProfile['weight'] as num).toDouble();
              final double height = (userProfile['height'] as num).toDouble();
              final int age = (userProfile['age'] as num).toInt();
              final String gender = userProfile['gender'] ?? 'Perempuan';
              final double activityLevel =
                  (userProfile['activity_level'] as num?)?.toDouble() ?? 1.2;

              // Mifflin-St Jeor formula
              double bmr;
              if (gender == 'Laki-laki') {
                bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
              } else {
                bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
              }
              final double tdee = bmr * activityLevel;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainDashboardPage(
                    userId: user['id'],
                    targetTdee: tdee,
                  ),
                ),
              );
            } else {
              // ALUR B: Jika data fisik masih kosong, lempar ke halaman input data fisik dulu
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DataFisikPage(userId: user['id']),
                ),
              );
            }
          }
          // ===================================================================
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username atau Password salah!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan database: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFB), // Background putih bersih agak kehijauan tipis
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO/IKON APLIKASI (Simbol Kesehatan sederhana bawaan Flutter)
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.spa_rounded, size: 40, color: Colors.green),
                ),
                const SizedBox(height: 24),

                // JUDUL & SUBJUDUL
                const Text(
                  "Silakan Masuk",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Masukkan akun Nourishia yang telah terdaftar",
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // INPUT USERNAME
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F1), // Background input soft
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.green, width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),

                // INPUT PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.green, width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // TOMBOL MASUK PREMIUM
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
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