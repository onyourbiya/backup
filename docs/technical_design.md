# Technical Design Document - Nourishia

## Aplikasi Pemantauan Gizi Personal Berbasis Algoritma Mifflin-St Jeor

---

## 1. Gambaran Umum Sistem

**Nourishia** adalah aplikasi Flutter desktop/web untuk memantau asupan gizi harian pengguna. Aplikasi menghitung kebutuhan kalori harian (TDEE) menggunakan algoritma **Mifflin-St Jeor**, kemudian membandingkan dengan asupan makanan aktual yang dicatat pengguna.

### 1.1 Technology Stack

| Komponen | Teknologi |
|----------|-----------|
| Framework | Flutter 3.x |
| Bahasa | Dart |
| Database | SQLite via `sqflite` + `sqflite_common_ffi` |
| Platform Target | Windows, macOS, Linux, Web |
| Data Sumber | CSV (panganku_data.csv) |
| Arsitektur | Clean Architecture (Data → Domain → Presentation) |

### 1.2 Struktur Project

```
lib/
├── main.dart                          # Entry point + platform setup
├── data/
│   ├── datasources/
│   │   └── database_helper.dart       # SQLite CRUD operations
│   └── models/
│       └── user_model.dart            # Model data user
├── presentation/
│   └── pages/
│       ├── home_page.dart             # Landing page (Login/Register)
│       ├── register_page.dart         # Registrasi akun
│       ├── login_page.dart            # Login + routing logic
│       ├── data_fisik_page.dart       # Input data fisik + hitung TDEE
│       ├── main_dashboard_page.dart   # Container utama (Bottom Nav)
│       ├── dashboard_harian_tab.dart  # Tab 0: Ringkasan nutrisi harian
│       ├── food_diary_tab.dart        # Tab 1: Catatan makanan harian
│       ├── profil_pengguna_tab.dart   # Tab 3: Profil user + BMR/TDEE
│       └── food_diary_page.dart       # (Legacy) Halaman diary standalone
assets/
└── panganku_data.csv                  # Data komposisi pangan Indonesia
```

---

## 2. Database Design

### 2.1 Lokasi Database

Database disimpan di folder lokal project: `{project_root}/dtbase/nourishia.db`

### 2.2 Entity Relationship Diagram

```
┌─────────────────────────────┐
│          users              │
├─────────────────────────────┤
│ id         INTEGER PK AI    │
│ username   TEXT NOT NULL     │
│ password   TEXT NOT NULL     │
│ gender     TEXT              │
│ weight     REAL              │
│ height     REAL              │
│ age        INTEGER           │
│ activity_level REAL          │
└──────────────┬──────────────┘
               │ 1
               │
               │ N
┌──────────────┴──────────────┐
│       food_diaries          │
├─────────────────────────────┤
│ id         INTEGER PK AI    │
│ user_id    INTEGER NOT NULL  │───→ FK ke users.id
│ food_name  TEXT NOT NULL     │
│ tanggal    TEXT NOT NULL     │
│ porsi_gram REAL NOT NULL     │
│ energi_terkonsumsi    REAL   │
│ protein_terkonsumsi   REAL   │
│ lemak_terkonsumsi     REAL   │
│ karbohidrat_terkonsumsi REAL │
│ serat_terkonsumsi     REAL   │
└─────────────────────────────┘

┌─────────────────────────────┐
│          foods              │
├─────────────────────────────┤
│ id         INTEGER PK AI    │
│ nama       TEXT NOT NULL     │
│ kategori   TEXT              │
│ tipe_bahan TEXT              │
│ jumlah     TEXT              │
│ bdd        REAL              │
│ air        REAL              │
│ energi     REAL              │
│ protein    REAL              │
│ lemak      REAL              │
│ karbohidrat REAL             │
│ serat      REAL              │
└─────────────────────────────┘
```

### 2.3 Mekanisme Seeding Data

1. **Saat database pertama kali dibuat** (`onCreate`): data dari `panganku_data.csv` di-insert ke tabel `foods`
2. **Setiap kali app dibuka**: fungsi `_reseedFoodsTable()` membandingkan jumlah baris CSV vs tabel `foods`. Jika berbeda, tabel di-clear dan di-seed ulang dari CSV terbaru.

---

## 3. Alur Aplikasi (Application Flow)

### 3.1 Diagram Alur Utama

```
┌──────────────┐
│   main.dart  │
│ (Init FFI)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   HomePage   │
│ (Welcome)    │
└──┬───────┬───┘
   │       │
   ▼       ▼
┌──────┐ ┌──────────┐
│Login │ │ Register │
└──┬───┘ └────┬─────┘
   │          │
   │          │ (Berhasil → pushReplacement ke LoginPage)
   │          ▼
   │     ┌──────────┐
   │     │LoginPage │
   │     └──────────┘
   │
   ▼
┌────────────────────────────────────┐
│         CEK PROFIL USER            │
│  (weight != null ?)                │
└──┬──────────────────────────────┬──┘
   │ YA                           │ TIDAK
   │                              │
   │ Hitung TDEE                  ▼
   │ dari data tersimpan    ┌─────────────┐
   │                        │DataFisikPage│
   │                        │(Input BB/TB)│
   │                        └──────┬──────┘
   │                               │
   │   Hitung BMR + TDEE           │
   │   Simpan ke SQLite            │
   │                               │
   ▼                               ▼
┌──────────────────────────────────────┐
│         MainDashboardPage            │
│         (targetTdee, userId)         │
├──────────────────────────────────────┤
│  Tab 0: Dashboard Harian            │
│  Tab 1: Food Diary                  │
│  Tab 2: Weight Tracker (Coming Soon)│
│  Tab 3: Profil Pengguna             │
└──────────────────────────────────────┘
```

### 3.2 Alur Registrasi

```
RegisterPage
    │
    ├── Input: username, password
    ├── Validasi: tidak boleh kosong
    ├── Proses: DatabaseHelper.createUser(username, password)
    ├── Feedback: SnackBar "Registrasi berhasil!"
    └── Navigasi: pushReplacement → LoginPage
```

### 3.3 Alur Login

```
LoginPage
    │
    ├── Input: username, password
    ├── Validasi: tidak boleh kosong
    ├── Proses: DatabaseHelper.loginUser(username, password)
    │
    ├── GAGAL → SnackBar "Username atau Password salah!"
    │
    └── BERHASIL → getUserProfile(user['id'])
         │
         ├── weight != null (data fisik sudah ada)
         │   ├── Hitung BMR (Mifflin-St Jeor)
         │   ├── Hitung TDEE = BMR × activity_level
         │   └── pushReplacement → MainDashboardPage(userId, tdee)
         │
         └── weight == null (data fisik belum diisi)
             └── pushReplacement → DataFisikPage(userId)
```

### 3.4 Alur Input Data Fisik

```
DataFisikPage
    │
    ├── Input: gender, weight (kg), height (cm), age, activity_level
    ├── Validasi: semua field wajib diisi
    │
    ├── ALGORITMA MIFFLIN-ST JEOR:
    │   ├── Laki-laki: BMR = (10 × BB) + (6.25 × TB) - (5 × Umur) + 5
    │   └── Perempuan: BMR = (10 × BB) + (6.25 × TB) - (5 × Umur) - 161
    │
    ├── TDEE = BMR × Activity Level
    │   ├── Sedentary:          1.2
    │   ├── Jarang olahraga:    1.375
    │   ├── Cukup olahraga:     1.55
    │   ├── Sering olahraga:    1.725
    │   └── Sangat sering:      1.9
    │
    ├── Simpan: DatabaseHelper.updateUserProfile(...)
    ├── Dialog: Tampilkan hasil BMR & TDEE
    └── Navigasi: pushReplacement → MainDashboardPage(userId, tdee)
```

### 3.5 Alur Dashboard Harian (Tab 0)

```
DashboardHarianTab
    │
    ├── Load data: getDailyNutritionSummary(userId, tanggal_hari_ini)
    │
    ├── Tampilkan:
    │   ├── Tanggal hari ini
    │   ├── Kartu: Kalori terkonsumsi / Target TDEE (Sisa kalori)
    │   ├── Progress Bar: Karbohidrat (target = TDEE × 55% / 4)
    │   ├── Progress Bar: Protein (target = TDEE × 15% / 4)
    │   ├── Progress Bar: Lemak (target = TDEE × 30% / 9)
    │   └── Progress Bar: Serat (target = 30g/hari)
    │
    └── Refresh: dipanggil via GlobalKey saat food diary berubah
```

### 3.6 Alur Food Diary (Tab 1)

```
FoodDiaryTab
    │
    ├── Pilih Tanggal (DatePicker)
    ├── Load entries: getFoodDiariesByDate(userId, tanggal)
    │
    ├── PENCARIAN MAKANAN:
    │   ├── Input: keyword di search bar
    │   ├── Query: searchFood(query) → SELECT dari tabel foods WHERE nama LIKE '%query%'
    │   └── Tampilkan: ListView hasil pencarian
    │
    ├── TAMBAH MAKANAN:
    │   ├── Tap item → Dialog porsi
    │   ├── Tampilkan info nutrisi per 100g (energi, karbo, protein, lemak, serat)
    │   ├── Input porsi (gram), default 100g
    │   ├── Preview: nutrisi × (porsi/100)
    │   ├── Validasi: porsi 1-5000g
    │   │
    │   ├── RUMUS PERHITUNGAN:
    │   │   ├── energi_terkonsumsi = (porsi / 100) × energi_per_100g
    │   │   ├── protein_terkonsumsi = (porsi / 100) × protein_per_100g
    │   │   ├── lemak_terkonsumsi = (porsi / 100) × lemak_per_100g
    │   │   ├── karbohidrat_terkonsumsi = (porsi / 100) × karbohidrat_per_100g
    │   │   └── serat_terkonsumsi = (porsi / 100) × serat_per_100g
    │   │
    │   ├── Simpan: insertFoodDiary(...)
    │   └── Callback: onEntryChanged() → refresh Dashboard
    │
    ├── HAPUS MAKANAN:
    │   ├── Swipe kiri (Dismissible) → Konfirmasi dialog
    │   ├── Proses: deleteFoodDiary(id)
    │   └── Callback: onEntryChanged() → refresh Dashboard
    │
    └── RINGKASAN HARIAN:
        └── Tampilkan total Energi, Karbo, Protein, Lemak di header
```

### 3.7 Alur Profil Pengguna (Tab 3)

```
ProfilPenggunaTab
    │
    ├── Load: getUserProfile(userId)
    │
    ├── Tampilkan:
    │   ├── Data Profil (username, gender, BB, TB, umur, activity_level)
    │   └── Hasil Perhitungan (BMR, TDEE)
    │
    └── Edit Profil → push DataFisikPage → pop & reload profil
```

---

## 4. Komponen Utama & Tanggung Jawab

### 4.1 DatabaseHelper (Singleton)

| Fungsi | Deskripsi |
|--------|-----------|
| `createUser()` | Insert user baru (register) |
| `loginUser()` | Validasi username + password |
| `updateUserProfile()` | Update data fisik user |
| `getUserProfile()` | Ambil profil user by ID |
| `searchFood()` | Cari makanan dari tabel foods (LIKE) |
| `insertFoodDiary()` | Simpan catatan makan harian |
| `deleteFoodDiary()` | Hapus catatan makan by ID |
| `getFoodDiariesByDate()` | Ambil diary berdasarkan tanggal |
| `getDailyNutritionSummary()` | SUM nutrisi harian |
| `_seedCsvData()` | Seed data CSV ke tabel foods |
| `_reseedFoodsTable()` | Re-seed otomatis jika CSV berubah |

### 4.2 Platform Initialization (main.dart)

```dart
if (kIsWeb) → databaseFactoryFfiWeb
if (desktop) → sqfliteFfiInit() + databaseFactoryFfi
if (mobile) → default sqflite (no additional setup needed)
```

---

## 5. Komunikasi Antar Komponen

```
MainDashboardPage
    │
    ├── GlobalKey<DashboardHarianTabState> ──→ DashboardHarianTab
    │                                              │
    │                                              └── refreshData() ←──┐
    │                                                                    │
    └── FoodDiaryTab ──→ onEntryChanged() callback ────────────────────┘
```

Ketika user menambah/menghapus makanan di FoodDiaryTab:
1. `insertFoodDiary()` atau `deleteFoodDiary()` dipanggil
2. Callback `onEntryChanged()` di-trigger
3. `MainDashboardPage._onNutritionUpdated()` dipanggil
4. Menggunakan `GlobalKey` untuk memanggil `DashboardHarianTab.refreshData()`
5. Dashboard query ulang `getDailyNutritionSummary()` dan update UI

---

## 6. Algoritma Inti: Mifflin-St Jeor

### 6.1 Rumus BMR

```
Laki-laki:  BMR = (10 × berat_kg) + (6.25 × tinggi_cm) - (5 × umur) + 5
Perempuan:  BMR = (10 × berat_kg) + (6.25 × tinggi_cm) - (5 × umur) - 161
```

### 6.2 Rumus TDEE

```
TDEE = BMR × Activity Level Factor
```

### 6.3 Distribusi Makronutrien

| Nutrisi | % dari TDEE | Konversi |
|---------|-------------|----------|
| Karbohidrat | 55% | ÷ 4 kcal/g |
| Protein | 15% | ÷ 4 kcal/g |
| Lemak | 30% | ÷ 9 kcal/g |
| Serat | - | 30g/hari (konstan) |

### 6.4 Rumus Perhitungan Asupan

```
nutrisi_terkonsumsi = (porsi_gram / 100) × nutrisi_per_100g
```

---

## 7. Format Data CSV

File: `assets/panganku_data.csv`
Separator: `;` (titik koma)
Desimal: `,` (koma Indonesia, dikonversi ke `.` saat parsing)

| Index | Kolom |
|-------|-------|
| 0 | nama |
| 1 | kategori |
| 2 | tipe_bahan |
| 3 | jumlah |
| 4 | bdd |
| 5 | air |
| 6 | energi |
| 7 | protein |
| 8 | lemak |
| 9 | karbohidrat |
| 10 | serat |

---

## 8. Catatan Penting

1. **Password tidak di-hash** — disimpan plaintext di SQLite (cukup untuk skripsi/prototype)
2. **Tidak ada session management** — userId diteruskan via constructor parameter
3. **food_diary_page.dart** adalah versi lama (standalone) yang tidak digunakan di navigasi aktif
4. **Weight Tracker** (Tab 2) masih placeholder
5. **Database lokal** — semua data offline, tidak ada backend/API
6. **Re-seed otomatis** — update CSV langsung ter-refleksi setelah restart app
