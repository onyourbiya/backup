import 'package:flutter/material.dart';
import '../../data/datasources/database_helper.dart';
import 'data_fisik_page.dart';

class ProfilPenggunaTab extends StatefulWidget {
  final int userId;
  const ProfilPenggunaTab({super.key, required this.userId});

  @override
  State<ProfilPenggunaTab> createState() => _ProfilPenggunaTabState();
}

class _ProfilPenggunaTabState extends State<ProfilPenggunaTab> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await DatabaseHelper.instance.getUserProfile(widget.userId);
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Data profil tidak dapat dimuat';
        _isLoading = false;
      });
    }
  }

  double _calculateBMR(Map<String, dynamic> data) {
    final double weight = (data['weight'] as num?)?.toDouble() ?? 0;
    final double height = (data['height'] as num?)?.toDouble() ?? 0;
    final int age = (data['age'] as int?) ?? 0;
    final String gender = data['gender'] ?? '';

    if (gender == 'Laki-laki') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.green));
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    if (_profileData == null) return const Center(child: Text('Data tidak ditemukan'));

    final data = _profileData!;
    final double bmr = _calculateBMR(data);
    
    double dbActivity = (data['activity_level'] as num?)?.toDouble() ?? 1.2;
    String teksGoal = data['goal'] ?? '0';
    double targetKaloriFinal = bmr * dbActivity;
    
    if (teksGoal.contains('-100')) { targetKaloriFinal -= 100; } 
    else if (teksGoal.contains('-200')) { targetKaloriFinal -= 200; } 
    else if (teksGoal.contains('-300')) { targetKaloriFinal -= 300; } 
    else if (teksGoal.contains('-400')) { targetKaloriFinal -= 400; } 
    else if (teksGoal.contains('-500')) { targetKaloriFinal -= 500; } 
    else if (teksGoal.contains('+100')) { targetKaloriFinal += 100; } 
    else if (teksGoal.contains('+200')) { targetKaloriFinal += 200; } 
    else if (teksGoal.contains('+300')) { targetKaloriFinal += 300; } 
    else if (teksGoal.contains('+400')) { targetKaloriFinal += 400; } 
    else if (teksGoal.contains('+500')) { targetKaloriFinal += 500; }
    
    String username = data['username'] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 🌟 Background Off-White Seragam
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // 1. TAMPILAN AVATAR PROFIL BARU (Biar makin keren)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.green,
                      child: Text(
                        username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    data['gender'] ?? '-',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 2. CARD DATA FISIK MODERN
            _buildSectionContainer(
              title: 'Data Fisik',
              icon: Icons.accessibility_new_rounded,
              iconColor: Colors.teal,
              children: [
                _buildProfileRow('Berat Badan', '${data['weight'] ?? '-'} kg'),
                _buildProfileRow('Tinggi Badan', '${data['height'] ?? '-'} cm'),
                _buildProfileRow('Umur', '${data['age'] ?? '-'} tahun'),
              ],
            ),
            const SizedBox(height: 16),

            // 3. CARD HASIL GIZI MODERN
            _buildSectionContainer(
              title: 'Analisis Gizi',
              icon: Icons.analytics_outlined,
              iconColor: Colors.orange,
              children: [
                _buildProfileRow('BMR (Kebutuhan Dasar)', '${bmr.round()} Kcal'),
                _buildProfileRow('Target Kalori (TDEE)', '${targetKaloriFinal.round()} Kcal'),
                const SizedBox(height: 14),
                
                // Banner Catatan Target Estetik
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.track_changes, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text('Catatan Target:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13)),
                        ],
                      ),
                      Text(
                        teksGoal,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 4. TOMBOL EDIT PROFIL DENGAN GLOW SHADOW
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DataFisikPage(userId: widget.userId)),
                  ).then((_) => _loadProfile());
                },
                icon: const Icon(Icons.edit_note_rounded, size: 22),
                label: const Text('Edit Profil & Data Fisik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🛠️ Fungsi pembungkus Card agar serasi dengan layout tracker sebelumnya
  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: Color(0xFFF1F3F5)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}