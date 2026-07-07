import 'package:flutter/material.dart';
import 'package:nourishia/data/datasources/database_helper.dart';

class WeightAndHistoryTracker extends StatefulWidget {
  final int userId;
  final double targetTdee; 

  const WeightAndHistoryTracker({
    super.key, 
    required this.userId, 
    required this.targetTdee, 
  });

  @override
  State<WeightAndHistoryTracker> createState() => _WeightAndHistoryTrackerState();
}

class _WeightAndHistoryTrackerState extends State<WeightAndHistoryTracker> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  double beratBadan = 0.0;
  double tinggiBadan = 0.0;
  double bmr = 0.0;
  double tdee = 0.0;

  List<Map<String, dynamic>> _daftarMakananHariIni = [];

  @override
  void initState() {
    super.initState();
    _loadDataHariIni();
  }

  Future<void> _loadDataHariIni() async {
    setState(() => _isLoading = true);

    String formattedDate =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final db = DatabaseHelper.instance;
    final profile = await db.getUserProfile(widget.userId);
    final diaries = await db.getFoodDiariesByDate(widget.userId, formattedDate);

    if (profile != null) {
      beratBadan = (profile['weight'] as num?)?.toDouble() ?? 0.0;
      tinggiBadan = (profile['height'] as num?)?.toDouble() ?? 0.0;
      int age = (profile['age'] as num?)?.toInt() ?? 0;
      String gender = profile['gender'] ?? 'Laki-laki';

      if (beratBadan > 0 && tinggiBadan > 0 && age > 0) {
        if (gender.toLowerCase() == 'perempuan' || gender.toLowerCase() == 'p') {
          bmr = (10 * beratBadan) + (6.25 * tinggiBadan) - (5 * age) - 161;
        } else {
          bmr = (10 * beratBadan) + (6.25 * tinggiBadan) - (5 * age) + 5;
        }
        tdee = widget.targetTdee;
      } else {
        bmr = 0.0;
        tdee = 0.0;
      }
    }

    if (!mounted) return;

    setState(() {
      _daftarMakananHariIni = diaries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 🌟 Background Off-White Premium
      appBar: AppBar(
        title: const Text('Riwayat Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. TIMELINE 7 HARI TERAKHIR PREMIUM
          _buildWeeklyTimeline(),
          
          // 2. TOMBOL KALENDER POP-UP ELEGAN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: OutlinedButton.icon(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                  _loadDataHariIni();
                }
              },
              icon: const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.green),
              label: Text(
                "Pilih Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : RefreshIndicator(
                    onRefresh: _loadDataHariIni,
                    color: Colors.green,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          
                          // 3. KELOMPOK DATA FISIK & ENERGI STYLE MODERN CARD
                          const Text("Kondisi Fisik & Energi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildSummaryCard("Berat Badan", beratBadan > 0 ? "$beratBadan kg" : "-", Icons.scale, Colors.orange)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildSummaryCard("Tinggi Badan", tinggiBadan > 0 ? "$tinggiBadan cm" : "-", Icons.height, Colors.teal)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildSummaryCard("BMR (Mifflin)", bmr > 0 ? "${bmr.toStringAsFixed(0)} kkal" : "-", Icons.bolt, Colors.redAccent)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildSummaryCard("TDEE (Target)", tdee > 0 ? "${tdee.toStringAsFixed(0)} kkal" : "-", Icons.local_fire_department, Colors.purple)),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // 4. JURNAL MENU MAKANAN MODERN LIST
                          Text(
                            "Menu Makanan Hari Ini",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 12),
                          
                          _daftarMakananHariIni.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.no_food_outlined, size: 40, color: Colors.grey),
                                      SizedBox(height: 10),
                                      Text("Belum ada catatan makanan", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _daftarMakananHariIni.length,
                                  itemBuilder: (context, index) {
                                    final makanan = _daftarMakananHariIni[index];
                                    double kalori = (makanan['energi_terkonsumsi'] as num?)?.toDouble() ?? 0.0;
                                    double porsi = (makanan['porsi_gram'] as num?)?.toDouble() ?? 0.0;

                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.restaurant, color: Colors.green, size: 20),
                                        ),
                                        title: Text(
                                          makanan['food_name'] ?? 'Makanan tanpa nama', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                                        ),
                                        subtitle: Text("${porsi.toStringAsFixed(0)} gram", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        trailing: Text(
                                          "${kalori.toStringAsFixed(0)} kkal",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeeklyTimeline() {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
          final listHari = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              _loadDataHariIni();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 58,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade200),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(listHari[date.weekday % 7], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white70 : Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(date.day.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}