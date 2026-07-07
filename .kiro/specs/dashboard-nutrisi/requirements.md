# Requirements Document

## Introduction

Fitur Dashboard Nutrisi adalah halaman utama aplikasi Nourishia yang mengintegrasikan komponen pemantauan gizi personal. Dashboard ini menampilkan ringkasan harian kalori dan makronutrien, profil pengguna, serta food diary yang persisten. Fitur ini menjadi pusat navigasi setelah user login dan mengisi data fisik, menggantikan navigasi langsung ke FoodDiaryPage yang ada saat ini. Navigasi tetap memiliki 4 tab termasuk Weight Tracker, namun Weight Tracker hanya menampilkan halaman placeholder untuk saat ini.

## Glossary

- **Dashboard**: Halaman utama aplikasi yang menampilkan ringkasan gizi harian dan navigasi ke semua fitur
- **TDEE**: Total Daily Energy Expenditure, total kebutuhan kalori harian yang dihitung dari BMR dikali faktor aktivitas
- **BMR**: Basal Metabolic Rate, kebutuhan kalori dasar tubuh yang dihitung dengan algoritma Mifflin-St Jeor
- **Makronutrien**: Zat gizi makro yang terdiri dari karbohidrat, protein, dan lemak
- **Food_Diary**: Catatan makanan harian pengguna yang disimpan secara persisten di database SQLite
- **Weight_Tracker**: Tab navigasi yang saat ini menampilkan halaman placeholder (coming soon) untuk fitur pencatatan berat badan yang akan dikembangkan di fase berikutnya
- **Profil_Pengguna**: Halaman yang menampilkan informasi fisik dan data gizi personal pengguna
- **Bottom_Navigation**: Komponen navigasi di bagian bawah layar untuk berpindah antar halaman utama
- **Porsi_Gram**: Jumlah gram makanan yang dikonsumsi pengguna, digunakan untuk menghitung nutrisi terkonsumsi
- **Progress_Bar**: Indikator visual berbentuk bar yang menunjukkan persentase pencapaian target gizi

## Requirements

### Requirement 1: Navigasi Dashboard Utama

**User Story:** As a pengguna, I want navigasi yang jelas antar fitur utama aplikasi, so that saya bisa berpindah antara dashboard harian, food diary, weight tracker, dan profil dengan mudah.

#### Acceptance Criteria

1. WHEN pengguna berhasil login dan telah mengisi data fisik, THE Dashboard SHALL menampilkan halaman utama dengan Bottom_Navigation yang memiliki tepat 4 tab: Dashboard Harian, Food Diary, Weight Tracker, dan Profil Pengguna
2. WHEN pengguna mengetuk salah satu tab pada Bottom_Navigation, THE Dashboard SHALL berpindah ke halaman yang sesuai dalam waktu maksimal 300 milidetik, dengan mempertahankan data yang sudah dimuat dan posisi scroll pada halaman sebelumnya selama sesi navigasi berlangsung
3. WHEN Dashboard pertama kali dibuka setelah login, THE Dashboard SHALL menampilkan tab Dashboard Harian sebagai halaman default dan menandai tab tersebut sebagai tab aktif pada Bottom_Navigation
4. WHILE pengguna berada di halaman manapun, THE Bottom_Navigation SHALL tetap terlihat di bagian bawah layar dan setiap tab dapat diketuk oleh pengguna
5. WHEN pengguna mengetuk salah satu tab pada Bottom_Navigation, THE Dashboard SHALL menampilkan indikator visual pada tab yang aktif sehingga pengguna dapat membedakan tab yang sedang dipilih dari tab lainnya
6. IF pengguna mengetuk tab yang sudah aktif, THEN THE Dashboard SHALL tetap menampilkan halaman tersebut tanpa melakukan reload atau perubahan state
7. WHEN pengguna mengetuk tab Weight Tracker, THE Dashboard SHALL menampilkan halaman placeholder dengan pesan "Coming Soon" atau "Segera Hadir" yang mengindikasikan fitur ini akan tersedia di pembaruan mendatang

### Requirement 2: Dashboard Harian (Ringkasan Gizi)

**User Story:** As a pengguna, I want melihat ringkasan gizi harian saya dalam satu tampilan, so that saya bisa memantau apakah asupan nutrisi saya sudah memenuhi target TDEE.

#### Acceptance Criteria

1. WHEN Dashboard Harian dibuka, THE Dashboard SHALL menampilkan tanggal hari ini (format: dd MMMM yyyy) dan total kalori yang sudah dikonsumsi dibandingkan target TDEE pengguna dalam format "{konsumsi} / {target} Kcal" dengan presisi 1 angka desimal
2. WHEN Dashboard Harian dibuka, THE Dashboard SHALL menampilkan sisa kalori yang masih bisa dikonsumsi hari ini (TDEE dikurangi total kalori terkonsumsi) dengan presisi 1 angka desimal, menampilkan nilai negatif jika total konsumsi melebihi TDEE
3. IF total kalori terkonsumsi lebih besar dari target TDEE, THEN THE Dashboard SHALL menampilkan indikator visual berwarna merah pada sisa kalori
4. IF total kalori terkonsumsi kurang dari atau sama dengan target TDEE, THEN THE Dashboard SHALL menampilkan indikator visual berwarna hijau pada sisa kalori
5. THE Dashboard SHALL menampilkan Progress_Bar untuk setiap makronutrien (karbohidrat, protein, lemak, serat) dengan label "{konsumsi}g / {target}g" dan target berdasarkan distribusi: karbohidrat 55% TDEE dibagi 4 kkal/g, protein 15% TDEE dibagi 4 kkal/g, lemak 30% TDEE dibagi 9 kkal/g, dan serat 30 gram per hari
6. WHEN pengguna menambahkan entri makanan baru di Food_Diary, THE Dashboard SHALL memperbarui ringkasan gizi dalam waktu kurang dari 1 detik tanpa perlu refresh manual oleh pengguna
7. IF tidak terdapat entri makanan untuk tanggal hari ini, THEN THE Dashboard SHALL menampilkan total kalori terkonsumsi sebesar 0 Kcal dan semua Progress_Bar makronutrien pada posisi 0%

### Requirement 3: Profil Pengguna

**User Story:** As a pengguna, I want melihat dan memverifikasi data fisik saya yang tersimpan, so that saya bisa memastikan perhitungan TDEE saya berdasarkan data yang benar.

#### Acceptance Criteria

1. WHEN halaman Profil_Pengguna dibuka, THE Profil_Pengguna SHALL menampilkan username, jenis kelamin, berat badan (kg), tinggi badan (cm), umur (tahun), dan tingkat aktivitas fisik (ditampilkan sebagai nilai multiplier: 1.2, 1.375, 1.55, 1.725, atau 1.9) yang tersimpan di database
2. WHEN halaman Profil_Pengguna dibuka, THE Profil_Pengguna SHALL menampilkan hasil perhitungan BMR (dalam kkal, dibulatkan ke bilangan bulat) menggunakan rumus Mifflin-St Jeor sesuai jenis kelamin, dan TDEE (dalam kkal, dibulatkan ke bilangan bulat) menggunakan rumus BMR dikali tingkat aktivitas fisik
3. WHEN pengguna mengetuk tombol edit profil, THE Profil_Pengguna SHALL membuka halaman DataFisikPage untuk memperbarui data fisik
4. WHEN pengguna kembali ke halaman Profil_Pengguna setelah memperbarui data fisik melalui DataFisikPage, THE Profil_Pengguna SHALL memuat ulang data dari database dan menampilkan data terbaru beserta hasil perhitungan ulang BMR dan TDEE
5. IF halaman Profil_Pengguna gagal memuat data dari database, THEN THE Profil_Pengguna SHALL menampilkan pesan kesalahan yang menginformasikan bahwa data tidak dapat dimuat

### Requirement 4: Food Diary Persisten

**User Story:** As a pengguna, I want catatan makanan harian saya tersimpan secara permanen di database, so that saya bisa melihat riwayat makanan yang sudah dikonsumsi dan data tidak hilang saat aplikasi ditutup.

#### Acceptance Criteria

1. WHEN pengguna menambahkan makanan melalui pencarian food database, THE Food_Diary SHALL menyimpan entri makanan ke tabel food_diaries di SQLite dengan data: user_id, food_name, tanggal (format ISO 8601 yyyy-MM-dd), porsi_gram, energi_terkonsumsi, protein_terkonsumsi, lemak_terkonsumsi, dan karbohidrat_terkonsumsi, lalu menampilkan entri baru tersebut di daftar makanan hari ini
2. WHEN halaman Food_Diary dibuka, THE Food_Diary SHALL memuat semua entri makanan dari database untuk tanggal hari ini dan menampilkannya dalam bentuk daftar yang diurutkan berdasarkan waktu penambahan (terbaru di atas), dengan setiap item menampilkan food_name, porsi_gram, dan energi_terkonsumsi
3. WHEN pengguna mengetuk komponen pemilih tanggal (date picker) pada halaman Food_Diary, THE Food_Diary SHALL menampilkan dialog pemilihan tanggal dan memuat ulang daftar entri makanan sesuai tanggal yang dipilih
4. WHEN pengguna menggeser (swipe) atau mengetuk tombol hapus pada entri makanan, THE Food_Diary SHALL menampilkan dialog konfirmasi penghapusan, dan jika pengguna mengonfirmasi, menghapus entri tersebut dari database dan memperbarui total nutrisi harian
5. THE Food_Diary SHALL menampilkan total akumulasi nutrisi (energi dalam kkal, karbohidrat dalam gram, protein dalam gram, lemak dalam gram) dari semua entri makanan pada tanggal yang dipilih, dengan nilai dibulatkan ke 1 desimal
6. WHEN pengguna memasukkan minimal 1 karakter di search bar, THE Food_Diary SHALL menampilkan maksimal 20 hasil pencarian dari tabel foods yang nama-nya mengandung kata kunci pencarian (case-insensitive, partial match), dengan setiap hasil menampilkan nama, kategori, dan kandungan energi per 100 gram
7. IF tidak terdapat entri makanan pada tanggal yang dipilih, THEN THE Food_Diary SHALL menampilkan pesan bahwa belum ada catatan makanan untuk tanggal tersebut
8. IF penyimpanan entri makanan ke database gagal, THEN THE Food_Diary SHALL menampilkan pesan kesalahan yang mengindikasikan kegagalan penyimpanan dan tidak menambahkan entri ke daftar tampilan

### Requirement 5: Pencatatan Porsi dan Kalkulasi Nutrisi

**User Story:** As a pengguna, I want memasukkan porsi makanan dalam gram dan melihat kalkulasi nutrisi yang akurat, so that saya bisa mencatat asupan gizi secara presisi.

#### Acceptance Criteria

1. WHEN pengguna memilih makanan dari hasil pencarian, THE Food_Diary SHALL menampilkan dialog input porsi dengan nilai default 100 gram dan informasi kandungan nutrisi per 100 gram dari makanan tersebut meliputi: energi (Kcal), karbohidrat (g), protein (g), lemak (g), dan serat (g)
2. WHEN pengguna memasukkan jumlah porsi dalam gram (nilai valid: lebih dari 0 hingga maksimal 5000 gram), THE Food_Diary SHALL menghitung dan menampilkan preview nutrisi terkonsumsi dengan rumus: (porsi_gram / 100) dikali nilai nutrisi per 100 gram untuk setiap zat gizi (energi, karbohidrat, protein, lemak, serat) dengan hasil ditampilkan dalam 1 angka desimal
3. WHEN pengguna menekan tombol konfirmasi pada dialog porsi dengan nilai porsi yang valid, THE Food_Diary SHALL menyimpan entri makanan, menutup dialog, dan menampilkan notifikasi keberhasilan yang menyebutkan nama makanan dan jumlah gram yang ditambahkan
4. IF pengguna memasukkan porsi kurang dari atau sama dengan 0 gram atau lebih dari 5000 gram, THEN THE Food_Diary SHALL menampilkan pesan kesalahan yang mengindikasikan rentang porsi yang diperbolehkan (1-5000 gram) dan menolak penyimpanan entri tanpa menutup dialog
5. IF pengguna memasukkan karakter non-numerik pada input porsi, THEN THE Food_Diary SHALL menampilkan pesan kesalahan yang mengindikasikan bahwa hanya angka yang diterima dan menolak penyimpanan entri tanpa menutup dialog
