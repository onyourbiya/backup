# Implementation Plan: Dashboard Nutrisi

## Overview

Implementasi Dashboard Nutrisi untuk aplikasi Nourishia Flutter. Fitur ini mencakup navigasi utama dengan 4 tab (Dashboard Harian, Food Diary, Weight Tracker, Profil Pengguna), persistensi data food diary dengan SQLite, kalkulasi nutrisi, dan migrasi database untuk kolom serat. Menggunakan arsitektur existing (clean architecture sederhana) dengan `setState` sebagai state management. WeightTrackerTab hanya berupa placeholder sederhana yang langsung diimplementasikan di dalam MainDashboardPage (task 3.1).

## Tasks

- [x] 1. Database migration dan perluasan DatabaseHelper
  - [x] 1.1 Implementasi database migration untuk kolom serat_terkonsumsi
    - Naikkan database version dari 1 ke 2 di `lib/data/datasources/database_helper.dart`
    - Tambahkan method `_upgradeDB` yang menjalankan `ALTER TABLE food_diaries ADD COLUMN serat_terkonsumsi REAL DEFAULT 0`
    - Pastikan `onUpgrade` callback terdaftar di `openDatabase`
    - _Requirements: 4.1_

  - [x] 1.2 Tambahkan method insertFoodDiary ke DatabaseHelper
    - Implementasi method `insertFoodDiary` yang menerima userId, foodName, tanggal, porsiGram, energiTerkonsumsi, proteinTerkonsumsi, lemakTerkonsumsi, karbohidratTerkonsumsi, dan seratTerkonsumsi
    - Insert ke tabel `food_diaries` dan return ID row baru
    - Wrap dalam try-catch untuk error handling
    - _Requirements: 4.1, 4.8_

  - [x] 1.3 Tambahkan method getFoodDiariesByDate ke DatabaseHelper
    - Implementasi query SELECT dari tabel `food_diaries` WHERE `user_id` = userId AND `tanggal` = tanggal
    - Urutkan berdasarkan `id DESC` (terbaru di atas)
    - Return `List<Map<String, dynamic>>`
    - _Requirements: 4.2, 4.3_

  - [x] 1.4 Tambahkan method deleteFoodDiary ke DatabaseHelper
    - Implementasi DELETE dari tabel `food_diaries` WHERE `id` = entryId
    - Return jumlah row yang terhapus
    - Wrap dalam try-catch untuk error handling
    - _Requirements: 4.4_

  - [x] 1.5 Tambahkan method getDailyNutritionSummary ke DatabaseHelper
    - Implementasi query SELECT SUM untuk energi_terkonsumsi, protein_terkonsumsi, lemak_terkonsumsi, karbohidrat_terkonsumsi, serat_terkonsumsi
    - WHERE `user_id` = userId AND `tanggal` = tanggal
    - Return `Map<String, double>` dengan keys: total_energi, total_protein, total_lemak, total_karbohidrat, total_serat
    - Return 0.0 untuk semua values jika tidak ada entri
    - _Requirements: 2.1, 2.5, 4.5_

  - [x] 1.6 Tambahkan method getUserProfile ke DatabaseHelper
    - Implementasi query SELECT dari tabel `users` WHERE `id` = userId
    - Return `Map<String, dynamic>?` (null jika tidak ditemukan)
    - _Requirements: 3.1_

  - [ ]* 1.7 Write property tests untuk DatabaseHelper (persistence round-trip)
    - **Property 5: Food Diary Persistence Round-Trip**
    - **Validates: Requirements 4.1**
    - Gunakan `glados` package dengan `sqflite_common_ffi` untuk in-memory database
    - Generate random food diary entries dan verify insert-then-query returns identical values

  - [ ]* 1.8 Write property tests untuk DatabaseHelper (date-based filtering)
    - **Property 6: Date-Based Query Filtering**
    - **Validates: Requirements 4.2**
    - Generate entries dengan berbagai tanggal, verify query hanya return entries yang match date

  - [ ]* 1.9 Write property tests untuk DatabaseHelper (delete removes entry)
    - **Property 7: Delete Removes Entry**
    - **Validates: Requirements 4.4**
    - Insert entry, delete, verify subsequent query tidak mengandung entry tersebut dan count berkurang 1

  - [ ]* 1.10 Write property tests untuk DatabaseHelper (daily nutrition summary)
    - **Property 8: Daily Nutrition Summary is Sum of Entries**
    - **Validates: Requirements 4.5**
    - Insert multiple entries pada tanggal sama, verify summary = sum of individual values

- [x] 2. Checkpoint - Pastikan database layer berjalan dengan benar
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Implementasi MainDashboardPage dan navigasi
  - [x] 3.1 Buat file MainDashboardPage
    - Buat `lib/presentation/pages/main_dashboard_page.dart`
    - Implementasi `StatefulWidget` dengan props `userId` (int) dan `targetTdee` (double)
    - State: `_currentIndex` (int, default 0) untuk index tab aktif
    - Scaffold dengan `BottomNavigationBar` berisi 4 item: Dashboard Harian, Food Diary, Weight Tracker, dan Profil Pengguna
    - Body menggunakan `IndexedStack` untuk mempertahankan state tiap tab
    - Jika tab aktif diketuk ulang, tidak melakukan reload (cek `_currentIndex == index`)
    - WeightTrackerTab diimplementasikan langsung sebagai placeholder sederhana (icon + teks "Segera Hadir") di dalam IndexedStack tanpa file terpisah
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

  - [x] 3.2 Update navigation flow dari LoginPage/DataFisikPage ke MainDashboardPage
    - Ubah navigasi setelah login/data fisik agar mengarah ke `MainDashboardPage` alih-alih `FoodDiaryPage`
    - Pass `userId` dan `targetTdee` ke `MainDashboardPage`
    - _Requirements: 1.1, 1.3_

- [x] 4. Implementasi DashboardHarianTab
  - [x] 4.1 Buat file DashboardHarianTab
    - Buat `lib/presentation/pages/dashboard_harian_tab.dart`
    - Implementasi `StatefulWidget` dengan props `userId` dan `targetTdee`
    - State: `_totalKalori`, `_totalKarbo`, `_totalProtein`, `_totalLemak`, `_totalSerat` (double), `_isLoading` (bool)
    - Pada `initState`, panggil `getDailyNutritionSummary(userId, today)` dari DatabaseHelper
    - Tampilkan tanggal hari ini (format: "dd MMMM yyyy")
    - Tampilkan kartu ringkasan: "{konsumsi} / {target} Kcal" dengan presisi 1 desimal
    - Tampilkan sisa kalori (TDEE - total konsumsi) dengan warna hijau jika <= TDEE, merah jika > TDEE
    - Tampilkan 4 progress bar makronutrien dengan target: karbo=(TDEE×0.55)/4, protein=(TDEE×0.15)/4, lemak=(TDEE×0.30)/9, serat=30g
    - Expose method `refreshData()` yang dipanggil dari parent saat food diary berubah
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [ ]* 4.2 Write property tests untuk kalkulasi nutrisi dashboard
    - **Property 1: Sisa Kalori Calculation**
    - **Validates: Requirements 2.2**
    - Untuk semua TDEE > 0 dan totalConsumed >= 0, verify sisa = TDEE - totalConsumed

  - [ ]* 4.3 Write property test untuk indikator warna kalori
    - **Property 2: Calorie Indicator Color Logic**
    - **Validates: Requirements 2.3, 2.4**
    - Untuk semua (totalConsumed, targetTDEE), verify warna merah jika totalConsumed > targetTDEE, hijau jika <=

  - [ ]* 4.4 Write property test untuk distribusi target makronutrien
    - **Property 3: Macronutrient Target Distribution**
    - **Validates: Requirements 2.5**
    - Untuk semua TDEE > 0, verify karbo=(TDEE×0.55)/4, protein=(TDEE×0.15)/4, lemak=(TDEE×0.30)/9, serat=30
    - Verify sum energy (karbo×4 + protein×4 + lemak×9) ≈ TDEE

- [ ] 5. Implementasi FoodDiaryTab
  - [x] 5.1 Buat file FoodDiaryTab
    - Buat `lib/presentation/pages/food_diary_tab.dart`
    - Implementasi `StatefulWidget` dengan props `userId` dan `onEntryChanged` (VoidCallback)
    - State: `_selectedDate`, `_diaryEntries`, `_searchResults`, `_searchController`, `_porsiController`, `_isLoading`
    - Muat entri dari database berdasarkan `_selectedDate` pada initState
    - Tampilkan total akumulasi nutrisi di header (energi, karbo, protein, lemak dengan 1 desimal)
    - Tampilkan daftar entri food diary (food_name, porsi_gram, energi_terkonsumsi)
    - Tampilkan pesan empty state jika tidak ada entri pada tanggal terpilih
    - _Requirements: 4.2, 4.5, 4.7_

  - [x] 5.2 Implementasi search functionality di FoodDiaryTab
    - Search bar yang memanggil `DatabaseHelper.instance.searchFood(query)` saat user mengetik minimal 1 karakter
    - Tampilkan maksimal 20 hasil pencarian dengan nama, kategori, dan energi per 100g
    - Clear results jika search kosong
    - _Requirements: 4.6_

  - [x] 5.3 Implementasi dialog porsi dan kalkulasi nutrisi
    - Dialog input porsi dengan default 100 gram
    - Tampilkan informasi nutrisi per 100g (energi, karbo, protein, lemak, serat)
    - Hitung preview nutrisi: (porsi/100) × nilai per 100g untuk setiap zat gizi, tampilkan 1 desimal
    - Validasi porsi: reject jika non-numerik, <= 0, atau > 5000
    - Tampilkan pesan error sesuai jenis kesalahan tanpa menutup dialog
    - Jika valid, insert ke database, tutup dialog, panggil `onEntryChanged`, refresh list
    - Tampilkan SnackBar keberhasilan menyebutkan nama makanan dan gram
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 4.1_

  - [x] 5.4 Implementasi delete functionality di FoodDiaryTab
    - Swipe (Dismissible) pada entri untuk memunculkan opsi hapus
    - Dialog konfirmasi sebelum penghapusan
    - Setelah konfirmasi, panggil `deleteFoodDiary(id)`, refresh list, panggil `onEntryChanged`
    - Tampilkan SnackBar jika hapus gagal
    - _Requirements: 4.4_

  - [x] 5.5 Implementasi date picker di FoodDiaryTab
    - Komponen date picker menggunakan `showDatePicker()`
    - Saat tanggal dipilih, update `_selectedDate` dan muat ulang entri dari database
    - _Requirements: 4.3_

  - [ ]* 5.6 Write property test untuk kalkulasi porsi nutrisi
    - **Property 9: Nutrient Portion Calculation**
    - **Validates: Requirements 5.2**
    - Untuk semua food nutrient values dan porsi 1-5000g, verify consumed = (porsi/100) × per_100g

  - [ ]* 5.7 Write property test untuk validasi input porsi
    - **Property 10: Portion Input Validation**
    - **Validates: Requirements 5.4, 5.5**
    - Untuk input non-numerik atau numerik <= 0 atau > 5000, verify rejection
    - Untuk input numerik dalam range (0, 5000], verify acceptance

- [x] 6. Checkpoint - Pastikan Food Diary dan Dashboard Harian terintegrasi
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implementasi ProfilPenggunaTab
  - [x] 7.1 Buat file ProfilPenggunaTab
    - Buat `lib/presentation/pages/profil_pengguna_tab.dart`
    - Implementasi `StatefulWidget` dengan props `userId`
    - State: `_profileData`, `_isLoading`, `_errorMessage`
    - Pada initState, panggil `DatabaseHelper.instance.getUserProfile(userId)`
    - Tampilkan: username, jenis kelamin, berat badan, tinggi badan, umur, tingkat aktivitas
    - Hitung dan tampilkan BMR (Mifflin-St Jeor) dan TDEE, dibulatkan ke bilangan bulat
    - Tombol "Edit Profil" navigasi ke `DataFisikPage`
    - Setelah kembali dari `DataFisikPage`, reload data via `Navigator.push().then()`
    - Tampilkan pesan error jika data gagal dimuat
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ]* 7.2 Write property test untuk perhitungan BMR dan TDEE
    - **Property 4: BMR and TDEE Calculation (Mifflin-St Jeor)**
    - **Validates: Requirements 3.2**
    - Untuk semua valid user data (gender, weight>0, height>0, age>0, activity_level), verify:
    - BMR = (10×weight) + (6.25×height) - (5×age) + 5 (male) atau - 161 (female)
    - TDEE = BMR × activity_level

- [x] 8. Wiring dan integrasi keseluruhan
  - [x] 8.1 Wire callback antara FoodDiaryTab dan DashboardHarianTab
    - Di MainDashboardPage, buat callback `_onNutritionUpdated` yang memanggil `refreshData()` pada DashboardHarianTab
    - Pass callback sebagai `onEntryChanged` ke FoodDiaryTab
    - Pastikan perubahan di food diary langsung ter-reflect di dashboard harian
    - _Requirements: 2.6_

  - [x] 8.2 Tambahkan dependency glados ke pubspec.yaml
    - Tambahkan `glados: ^1.1.1` ke `dev_dependencies` di `pubspec.yaml`
    - Jalankan `flutter pub get` untuk install
    - _Requirements: (testing infrastructure)_

  - [ ]* 8.3 Write widget tests untuk MainDashboardPage
    - Test render 4 tabs dengan label yang benar
    - Test default tab adalah Dashboard Harian (index 0)
    - Test navigasi antar tab mempertahankan state (IndexedStack)
    - _Requirements: 1.1, 1.3, 1.5_

- [x] 9. Final checkpoint - Pastikan semua komponen terintegrasi
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using `glados` package
- Unit/widget tests validate specific examples and edge cases
- Database tests menggunakan `sqflite_common_ffi` untuk in-memory SQLite testing
- Semua file baru berada di `lib/presentation/pages/` sesuai arsitektur existing
- State management menggunakan `setState` sesuai pola existing di project
- WeightTrackerTab diimplementasikan sebagai placeholder inline di MainDashboardPage (task 3.1) tanpa file terpisah

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "8.2"] },
    { "id": 1, "tasks": ["1.2", "1.3", "1.4", "1.5", "1.6"] },
    { "id": 2, "tasks": ["1.7", "1.8", "1.9", "1.10", "3.1"] },
    { "id": 3, "tasks": ["3.2", "4.1", "7.1"] },
    { "id": 4, "tasks": ["4.2", "4.3", "4.4", "5.1", "7.2"] },
    { "id": 5, "tasks": ["5.2", "5.3", "5.4", "5.5"] },
    { "id": 6, "tasks": ["5.6", "5.7", "8.1"] },
    { "id": 7, "tasks": ["8.3"] }
  ]
}
```
