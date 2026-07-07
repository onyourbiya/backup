// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:nourishia/data/datasources/database_helper.dart';

class FoodDiaryPage extends StatefulWidget {
  final int userId;
  final double targetTdee; // 🌟 Sudah menggunakan TDEE dinamis bawaan user
  final VoidCallback onEntryChanged;

  const FoodDiaryPage({
    super.key, 
    required this.userId, 
    required this.onEntryChanged, 
    required this.targetTdee, // 🌟 Diperbaiki susunan constructor-nya
  });

  @override
  State<FoodDiaryPage> createState() => _FoodDiaryPageState();
}

class _FoodDiaryPageState extends State<FoodDiaryPage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _diaries = [];
  
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Map<String, dynamic> _summary = {
    'total_energi': 0.0,
    'total_karbohidrat': 0.0,
    'total_protein': 0.0,
    'total_lemak': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    String formattedDate =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    
    final db = DatabaseHelper.instance;
    final diaries = await db.getFoodDiariesByDate(widget.userId, formattedDate);
    final summary = await db.getDailyNutritionSummary(widget.userId, formattedDate);

    if (!mounted) return;

    setState(() {
      _diaries = diaries;
      _summary = summary;
    });
    
    widget.onEntryChanged();
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final results = await DatabaseHelper.instance.searchFood(query);
    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  void _showGramInputDialog(Map<String, dynamic> food) {
    final TextEditingController gramController = TextEditingController(text: "100");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(food['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Masukkan porsi (gram):", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: gramController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                suffixText: "gram",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              double? inputGram = double.tryParse(gramController.text);
              if (inputGram != null && inputGram > 0) {
                Navigator.pop(context);
                _saveFoodToDiary(food, inputGram);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _saveFoodToDiary(Map<String, dynamic> food, double gram) async {
    String formattedDate =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    
    double faktor = gram / 100.0;

    await DatabaseHelper.instance.insertFoodDiary(
      userId: widget.userId,
      foodName: food['nama'],
      tanggal: formattedDate,
      porsiGram: gram,
      energiTerkonsumsi: (food['energi'] as num).toDouble() * faktor,
      proteinTerkonsumsi: (food['protein'] as num).toDouble() * faktor,
      lemakTerkonsumsi: (food['lemak'] as num).toDouble() * faktor,
      karbohidratTerkonsumsi: (food['karbohidrat'] as num).toDouble() * faktor,
      seratTerkonsumsi: ((food['serat'] ?? 0) as num).toDouble() * faktor,
    );

    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
    
    _refreshData();
  }

  Future<void> _deleteEntry(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Menu?"),
        content: const Text("Apakah Anda yakin ingin membatalkan menu ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteFoodDiary(id);
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          _buildMacroChart(),
          _buildSearchBar(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              "Riwayat Makan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResultsList() : _buildFoodList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Food Diary", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _refreshData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChart() {
    double totalEnergi = (_summary['total_energi'] as num?)?.toDouble() ?? 0.0;
    double karbo = (_summary['total_karbohidrat'] as num?)?.toDouble() ?? 0.0;
    double protein = (_summary['total_protein'] as num?)?.toDouble() ?? 0.0;
    double lemak = (_summary['total_lemak'] as num?)?.toDouble() ?? 0.0;
    double totalMacros = karbo + protein + lemak;

    // 🌟 MENGHITUNG SISA KALORI SECARA DINAMIS SESUAI USER YANG AKTIF
    double sisaKalori = widget.targetTdee - totalEnergi;

    // Menghitung porsi pembagian lengkungan lingkaran gizi
    double karboPercent = totalMacros > 0 ? (karbo / totalMacros) : 0.0;
    double proteinPercent = totalMacros > 0 ? (protein / totalMacros) : 0.0;
    double lemakPercent = totalMacros > 0 ? (lemak / totalMacros) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 15)],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 110,
            width: 110,
            child: Stack(
              children: [
                // 1. Teks di tengah lingkaran (Menghitung Sisa Kalori)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sisaKalori < 0 ? "0" : sisaKalori.toStringAsFixed(0), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 20,
                          color: sisaKalori < 0 ? Colors.red : const Color(0xFF2D3142)
                        ),
                      ),
                      Text(
                        sisaKalori < 0 ? "Lebih" : "Sisa Kcal", 
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // 2. Lingkaran Dasar Abu-Abu
                SizedBox(
                  height: 110,
                  width: 110,
                  child: CircularProgressIndicator(value: 1.0, strokeWidth: 10, color: Colors.grey.shade100),
                ),
                // 3. 🌟 PROSES LAYER 3 WARNA BERLAPIS (Hijau, Merah, Oranye)
                if (totalMacros > 0) ...[
                  // Lingkaran Karbohidrat (Hijau)
                  SizedBox(
                    height: 110,
                    width: 110,
                    child: CircularProgressIndicator(
                      value: karboPercent, 
                      strokeWidth: 10, 
                      color: Colors.green,
                    ),
                  ),
                  // Lingkaran Protein (Merah) - Diputar mengikuti ujung Karbo
                  SizedBox(
                    height: 110,
                    width: 110,
                    child: RotationTransition(
                      turns: AlwaysStoppedAnimation(karboPercent),
                      child: CircularProgressIndicator(
                        value: proteinPercent, 
                        strokeWidth: 10, 
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  // Lingkaran Lemak (Oranye) - Diputar mengikuti ujung Karbo + Protein
                  SizedBox(
                    height: 110,
                    width: 110,
                    child: RotationTransition(
                      turns: AlwaysStoppedAnimation(karboPercent + proteinPercent),
                      child: CircularProgressIndicator(
                        value: lemakPercent, 
                        strokeWidth: 10, 
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              children: [
                _macroInfo("Karbohidrat", karbo, Colors.green),
                const SizedBox(height: 8),
                _macroInfo("Protein", protein, Colors.redAccent),
                const SizedBox(height: 8),
                _macroInfo("Lemak", lemak, Colors.orange),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _macroInfo(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        Text("${value.toStringAsFixed(1)}g", style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Cari & tambah makanan...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (_searchResults.isEmpty) return const Center(child: Text("Makanan tidak ditemukan"));
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.add_circle_outline, color: Colors.green),
          title: Text(food['nama']),
          subtitle: Text("${food['energi']} Kcal (per 100g)"),
          onTap: () => _showGramInputDialog(food), 
        );
      },
    );
  }

  Widget _buildFoodList() {
    if (_diaries.isEmpty) {
      return const Center(child: Text("Belum ada makanan dicatat hari ini."));
    }
    return ListView.builder(
      itemCount: _diaries.length,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemBuilder: (context, index) {
        final item = _diaries[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(item['food_name']),
            subtitle: Text("${item['porsi_gram']}g  •  ${item['energi_terkonsumsi']} Kcal"),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteEntry(item['id']),
            ),
          ),
        );
      },
    );
  }
}