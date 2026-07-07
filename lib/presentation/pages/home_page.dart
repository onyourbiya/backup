import 'package:flutter/material.dart';
import 'register_page.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFB), // Background segar senada dengan Login
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ILUSTRASI / IKON LOGO UTAMA
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.spa_rounded, 
                    size: 72, 
                    color: Colors.green
                  ),
                ),
                const SizedBox(height: 40),

                // JUDUL UTAMA
                const Text(
                  "Selamat Datang di Nourishia",
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF2D3142),
                    letterSpacing: -0.5
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                
                // SUBJUDUL
                const Text(
                  "Aplikasi Pemantauan Gizi Personal",
                  style: TextStyle(
                    fontSize: 15, 
                    color: Colors.grey,
                    height: 1.4
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // TOMBOL LOGIN (PRIMARY)
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
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
                      "Masuk ke Akun", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // TOMBOL REGISTER (SECONDARY)
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: Colors.green, width: 1.5),
                    foregroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Daftar Akun Baru", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
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