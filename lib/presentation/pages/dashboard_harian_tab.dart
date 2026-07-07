import 'package:flutter/material.dart';
import '../../data/datasources/database_helper.dart';
import 'info_gizi_page.dart';

class DashboardHarianTab extends StatefulWidget {
  final int userId;
  final double targetTdee;

  const DashboardHarianTab({
    super.key,
    required this.userId,
    required this.targetTdee,
  });

  @override
  State<DashboardHarianTab> createState() => DashboardHarianTabState();
}

class DashboardHarianTabState extends State<DashboardHarianTab> {
  double _totalKalori = 0.0;
  double _totalKarbo = 0.0;
  double _totalProtein = 0.0;
  double _totalLemak = 0.0;
  double _totalSerat = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final today = DateTime.now();
      final tanggal =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final summary = await DatabaseHelper.instance
          .getDailyNutritionSummary(widget.userId, tanggal);

      if (!mounted) return;

      setState(() {
        _totalKalori = summary['total_energi'] ?? 0.0;
        _totalKarbo = summary['total_karbohidrat'] ?? 0.0;
        _totalProtein = summary['total_protein'] ?? 0.0;
        _totalLemak = summary['total_lemak'] ?? 0.0;
        _totalSerat = summary['total_serat'] ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _totalKalori = 0.0;
        _totalKarbo = 0.0;
        _totalProtein = 0.0;
        _totalLemak = 0.0;
        _totalSerat = 0.0;
        _isLoading = false;
      });
    }
  }

  void refreshData() {
    _loadData();
  }

  String _formatTanggalHariIni() {
    const bulanIndonesia = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')} ${bulanIndonesia[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    final sisaKalori = widget.targetTdee - _totalKalori;
    final sisaPositif = _totalKalori <= widget.targetTdee;
    final progressKalori = widget.targetTdee > 0 ? (_totalKalori / widget.targetTdee).clamp(0.0, 1.0) : 0.0;

    final targetKarbo = (widget.targetTdee * 0.55) / 4;
    final targetProtein = (widget.targetTdee * 0.15) / 4;
    final targetLemak = (widget.targetTdee * 0.30) / 9;
    const targetSerat = 30.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER SALUTATION & TANGGAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Halo, Sahabat Sehat!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTanggalHariIni(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.wb_sunny_rounded, color: Colors.orange),
              )
            ],
          ),
          const SizedBox(height: 24),

          // KARTU RINGKASAN KALORI UTAMA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Kalori Dikonsumsi", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          '${_totalKalori.round()} Kcal',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Target Harian", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.targetTdee.round()} Kcal',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressKalori,
                    backgroundColor: const Color(0xFFF1F5F1),
                    valueColor: AlwaysStoppedAnimation<Color>(sisaPositif ? Colors.green : Colors.redAccent),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sisaPositif ? 'Sisa Alokasi Kalori' : 'Melebihi Batas Kalori',
                      style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${sisaKalori.abs().round()} Kcal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: sisaPositif ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BANNER CARD "ISI PIRINGKU"
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InfoGiziPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF26A69A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Panduan Gizi Seimbang",
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Pelajari porsi ideal 'Isi Piringku' Kemenkes RI.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8), // 🌟 Menggantikan whiteCC
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.8), size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // JUDUL SEKSI MAKRONUTRIEN
          const Text(
            "Nutrisi Makro & Serat",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 12),

          // PROGRESS LIST MAKRONUTRIEN
          _buildMacroCard(
            label: 'Karbohidrat (55%)',
            consumed: _totalKarbo,
            target: targetKarbo,
            color: Colors.green,
            icon: Icons.grain_rounded,
          ),
          const SizedBox(height: 12),
          _buildMacroCard(
            label: 'Protein (15%)',
            consumed: _totalProtein,
            target: targetProtein,
            color: Colors.redAccent,
            icon: Icons.kebab_dining_rounded,
          ),
          const SizedBox(height: 12),
          _buildMacroCard(
            label: 'Lemak (30%)',
            consumed: _totalLemak,
            target: targetLemak,
            color: Colors.orange,
            icon: Icons.opacity_rounded,
          ),
          const SizedBox(height: 12),
          _buildMacroCard(
            label: 'Serat Harian',
            consumed: _totalSerat,
            target: targetSerat,
            color: Colors.teal,
            icon: Icons.eco_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard({
    required String label,
    required double consumed,
    required double target,
    required Color color,
    required IconData icon,
  }) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF1F5F1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpenuhi',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                '${consumed.toStringAsFixed(1)}g / ${target.toStringAsFixed(1)}g',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}