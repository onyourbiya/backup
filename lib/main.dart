// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nourishia/presentation/pages/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; 
import 'presentation/pages/home_page.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🌟 1. KUNCI PERBAIKAN: Inisialisasi Database FFI khusus kalau jalan di Linux/Windows
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 🌟 2. CEK NOTIFIKASI: Cuma aktifkan notifikasi kalau dijalankan di HP (Android/iOS)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await NotificationService().initNotification();

      // Daftarkan jadwal pengingat makan pagi
      await NotificationService().scheduleDailyNotification(
        id: 1,
        title: "Halo, waktunya sarapan! 🍲", 
        body: "Selamat pagi dan semoga harimu menyenangkan, jangan lupa catat makanan hari ini!",
        hour: 8,
        minute: 00,
      );

      // Daftarkan jadwal pengingat makan siang
      await NotificationService().scheduleDailyNotification(
        id: 2, 
        title: "Halo, waktunya makan siang! 🍲", 
        body: "Sudah jam 13 nih, yuk catat makananmu di Nourishia agar kalorimu terjaga!", 
        hour: 13,
        minute: 00,
      );

      // Daftarkan jadwal pengingat makan malam
      await NotificationService().scheduleDailyNotification(
        id: 3, 
        title: "Halo, waktunya makan malam! 🌙", 
        body: "Satu langkah lagi menuju target harianmu, yuk masukkan menumu sekarang!", 
        hour: 20,
        minute: 00,
      );
    } catch (e) {
      debugPrint("Gagal mengaktifkan notifikasi: $e");
    }
  } else {
    debugPrint("Aplikasi berjalan di Linux/Desktop. Fitur notifikasi HP dilewati.");
  }

  // 🌟 3. Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nourishia',
      home: HomePage(),
    );
  }
}