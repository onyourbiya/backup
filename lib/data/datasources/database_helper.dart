import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nourishia.db');
    // Re-seed tabel foods dari CSV setiap kali app dibuka
    await _reseedFoodsTable(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Simpan database di folder lokal 'database/' pada root project
    final dbDir = Directory(join(Directory.current.path, 'dtbase'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final path = join(dbDir.path, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // No-op: upgrade logic removed
  }

    Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        gender TEXT,
        weight REAL,
        height REAL,
        age INTEGER,
        activity_level REAL,
        goal TEXT    
      )
    ''');

    // ... tabel foods dan food_diaries biarkan tetap sama di bawahnya ...

    // 2. TABEL FOODS (Untuk menampung isi data .csv kamu)
    await db.execute('''
      CREATE TABLE foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        kategori TEXT,
        tipe_bahan TEXT,
        jumlah TEXT,
        bdd REAL,
        air REAL,
        energi REAL,
        protein REAL,
        lemak REAL,
        karbohidrat REAL,
        serat REAL
      )
    ''');

    // 3. TABEL FOOD DIARIES (Untuk mencatat makanan harian user)
    await db.execute('''
      CREATE TABLE food_diaries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        food_name TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        porsi_gram REAL NOT NULL,
        energi_terkonsumsi REAL NOT NULL,
        protein_terkonsumsi REAL NOT NULL,
        lemak_terkonsumsi REAL NOT NULL,
        karbohidrat_terkonsumsi REAL NOT NULL,
        serat_terkonsumsi REAL DEFAULT 0
      )
    ''');

    // Panggil fungsi otomatis untuk memasukkan data dari CSV ke dalam database
    await _seedCsvData(db);
  }

  // --- FUNGSI OTOMATIS MEMBACA DAN MEMASUKKAN DATA CSV ---
  Future<void> _seedCsvData(Database db) async {
    try {
      // Membaca file .csv dari folder assets kamu
      final csvRaw = await rootBundle.loadString('assets/panganku_data.csv');

      // Memisah per baris
      List<String> lines = const LineSplitter().convert(csvRaw);

      // Mulai dari baris indeks 1 (baris 0 adalah Judul Kolom/Header, jadi kita lewati)
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;

        // Berdasarkan gambar kamu, data dipisahkan dengan titik koma ';'
        List<String> row = lines[i].split(';');

        if (row.length >= 11) {
          await db.insert('foods', {
            'nama': row[0].trim(),
            'kategori': row[1].trim(),
            'tipe_bahan': row[2].trim(),
            'jumlah': row[3].trim(),
            // Kita ubah koma desimal khas Indonesia menjadi titik agar bisa dibaca SQLite
            'bdd': double.tryParse(row[4].replaceAll(',', '.')) ?? 0.0,
            'air': double.tryParse(row[5].replaceAll(',', '.')) ?? 0.0,
            'energi': double.tryParse(row[6].replaceAll(',', '.')) ?? 0.0,
            'protein': double.tryParse(row[7].replaceAll(',', '.')) ?? 0.0,
            'lemak': double.tryParse(row[8].replaceAll(',', '.')) ?? 0.0,
            'karbohidrat': double.tryParse(row[9].replaceAll(',', '.')) ?? 0.0,
            'serat': double.tryParse(row[10].replaceAll(',', '.')) ?? 0.0,
          });
        }
      }
      // ignore: avoid_print
      print('=== BERHASIL MEMASUKKAN DATA CSV KE SQLITE ===');
    } catch (e) {
      // ignore: avoid_print
      print("Gagal membaca CSV atau seeding database: $e");
    }
  }

  // --- FUNGSI RE-SEED TABEL FOODS DARI CSV (DIJALANKAN SETIAP APP DIBUKA) ---
  Future<void> _reseedFoodsTable(Database db) async {
    try {
      final csvRaw = await rootBundle.loadString('assets/panganku_data.csv');
      List<String> lines = const LineSplitter().convert(csvRaw);

      // Hitung jumlah baris data di CSV (tanpa header dan baris kosong)
      int csvCount = 0;
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isNotEmpty) csvCount++;
      }

      // Hitung jumlah baris di tabel foods saat ini
      final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM foods');
      final dbCount = Sqflite.firstIntValue(result) ?? 0;

      // Jika jumlah berbeda, hapus dan isi ulang
      if (dbCount != csvCount) {
        await db.delete('foods');
        await _seedCsvData(db);
        // ignore: avoid_print
        print('=== TABEL FOODS DI-RESEED (CSV: $csvCount, DB lama: $dbCount) ===');
      }
    } catch (e) {
      // ignore: avoid_print
      print("Gagal reseed tabel foods: $e");
    }
  }

  // --- FUNGSI UNTUK MENCARI MAKANAN LEWAT SEARCH BAR ---
  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    final db = await database;
    return await db.query(
      'foods',
      where: 'nama LIKE ?',
      whereArgs: ['%$query%'],
      limit: 20, // Batasi 20 hasil saja biar aplikasi enteng
    );
  }

  Future<int> registerUser(String username, String password) async {
    final db = await instance.database;

    // 1. Cek dulu apakah username sudah ada di database
    final List<Map<String, dynamic>> checkUser = await db.query(
      'users', // Ganti dengan nama tabel user
      where: 'username = ?',
      whereArgs: [username],
    );

    // 2. Jika hasil query tidak kosong, artinya username SUDAH DIPAKAI!
    if (checkUser.isNotEmpty) {
      return -1; // Kita kembalikan angka -1 sebagai tanda error/gagal
    }

    // 3. Jika aman, baru lakukan insert data baru
    return await db.insert('users', {
      'username': username,
      'password': password,
    });
  }

// --- FUNGSI UPDATE DATA FISIK (SUDAH DITAMBAH GOAL) ---
  Future<int> updateUserProfile(
    int userId, 
    String gender, 
    double weight,
    double height, 
    int age, 
    double activityLevel,
    String goal, // 🌟 Tambahkan parameter goal di sini
  ) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'gender': gender,
        'weight': weight,
        'height': height,
        'age': age,
        'activity_level': activityLevel,
        'goal': goal, // 🌟 Pastikan ini ikut disimpan ke database!
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // --- FUNGSI UNTUK MENGAMBIL PROFIL USER BERDASARKAN ID (UNTUK BYPASS LOGIN) ---
  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // --- FUNGSI UNTUK MENGAMBIL FOOD DIARY BERDASARKAN TANGGAL ---
  Future<List<Map<String, dynamic>>> getFoodDiariesByDate(
      int userId, String tanggal) async {
    final db = await database;
    return await db.query(
      'food_diaries',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tanggal],
      orderBy: 'id DESC',
    );
  }

  // --- FUNGSI UNTUK MENYIMPAN ENTRI FOOD DIARY ---
  Future<int> insertFoodDiary({
    required int userId,
    required String foodName,
    required String tanggal,
    required double porsiGram,
    required double energiTerkonsumsi,
    required double proteinTerkonsumsi,
    required double lemakTerkonsumsi,
    required double karbohidratTerkonsumsi,
    required double seratTerkonsumsi,
  }) async {
    try {
      final db = await database;
      return await db.insert('food_diaries', {
        'user_id': userId,
        'food_name': foodName,
        'tanggal': tanggal,
        'porsi_gram': porsiGram,
        'energi_terkonsumsi': energiTerkonsumsi,
        'protein_terkonsumsi': proteinTerkonsumsi,
        'lemak_terkonsumsi': lemakTerkonsumsi,
        'karbohidrat_terkonsumsi': karbohidratTerkonsumsi,
        'serat_terkonsumsi': seratTerkonsumsi,
      });
    } catch (e) {
      // ignore: avoid_print
      print('Gagal menyimpan food diary: $e');
      return -1;
    }
  }

  // --- FUNGSI UNTUK MENGHAPUS ENTRI FOOD DIARY BERDASARKAN ID ---
  Future<int> deleteFoodDiary(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'food_diaries',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  // --- FUNGSI UNTUK MENGAMBIL RINGKASAN NUTRISI HARIAN ---
  Future<Map<String, double>> getDailyNutritionSummary(
      int userId, String tanggal) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        SUM(energi_terkonsumsi) as total_energi,
        SUM(protein_terkonsumsi) as total_protein,
        SUM(lemak_terkonsumsi) as total_lemak,
        SUM(karbohidrat_terkonsumsi) as total_karbohidrat,
        SUM(serat_terkonsumsi) as total_serat
      FROM food_diaries
      WHERE user_id = ? AND tanggal = ?
      ''',
      [userId, tanggal],
    );

    if (result.isNotEmpty && result.first['total_energi'] != null) {
      final row = result.first;
      return {
        'total_energi': (row['total_energi'] as num?)?.toDouble() ?? 0.0,
        'total_protein': (row['total_protein'] as num?)?.toDouble() ?? 0.0,
        'total_lemak': (row['total_lemak'] as num?)?.toDouble() ?? 0.0,
        'total_karbohidrat':
            (row['total_karbohidrat'] as num?)?.toDouble() ?? 0.0,
        'total_serat': (row['total_serat'] as num?)?.toDouble() ?? 0.0,
      };
    }

    return {
      'total_energi': 0.0,
      'total_protein': 0.0,
      'total_lemak': 0.0,
      'total_karbohidrat': 0.0,
      'total_serat': 0.0,
    };
  }
  // Fungsi untuk membatalkan/menghapus menu makanan berdasarkan ID
  Future<int> deleteFoodEntry(int id) async {
    final db = await database;
    return await db.delete(
      'food_entries', // <--- Sesuaikan ini dengan nama tabel diary makananmu
      where: 'id = ?',
      whereArgs: [id],
    );
  }

    Future<Map<String, dynamic>?> loginUser(String username, String password) async {
      final db = await database;
      
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      if (result.isNotEmpty) {
        return result.first; // ✅ Ketemu! Kembalikan data user pertama
      }
      return null; // ❌ Tidak ketemu atau password salah
    }
  }