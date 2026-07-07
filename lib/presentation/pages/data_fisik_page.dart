import 'package:flutter/material.dart';
import '../../data/datasources/database_helper.dart';
import 'main_dashboard_page.dart';

class DataFisikPage extends StatefulWidget {
  final int userId;
  const DataFisikPage({super.key, required this.userId});

  @override
  State<DataFisikPage> createState() => _DataFisikPageState();
}

class _DataFisikPageState extends State<DataFisikPage> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String selectedGender = 'Perempuan';
  String selectedGoal = '0'; 
  double selectedActivity = 1.2;
  bool _isLoadingData = true;

  final Map<String, double> activityOptions = {
    'Sangat Jarang Olahraga (Sedentary)': 1.2,
    'Jarang Olahraga (1-3 hari/minggu)': 1.375,
    'Cukup Olahraga (3-5 hari/minggu)': 1.55,
    'Sering Olahraga (6-7 hari/minggu)': 1.725,
    'Sangat Sering Olahraga (Atlet/Pekerja Berat)': 1.9,
  };

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final profile = await DatabaseHelper.instance.getUserProfile(widget.userId);
      if (profile != null) {
        setState(() {
          weightController.text = (profile['weight'] ?? '').toString();
          heightController.text = (profile['height'] ?? '').toString();
          ageController.text = (profile['age'] ?? '').toString();
          selectedGender = profile['gender'] == 'Laki-laki' ? 'Laki-laki' : 'Perempuan';
          
          double? dbActivity = (profile['activity_level'] as num?)?.toDouble();
          if (dbActivity != null && activityOptions.containsValue(dbActivity)) {
            selectedActivity = dbActivity;
          }

          if (profile['goal'] != null) {
            final String dbGoal = profile['goal'].toString();
            if (['-500', '-400', '-300', '-200', '-100', '0', '+100', '+200', '+300', '+400', '+500'].contains(dbGoal)) {
              selectedGoal = dbGoal;
            }
          }
        });
      }
    } catch (_) {
      // Abaikan jika data belum ada
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  void _hitungDanSimpan() async {
    final weightStr = weightController.text.trim();
    final heightStr = heightController.text.trim();
    final ageStr = ageController.text.trim();

    if (weightStr.isEmpty || heightStr.isEmpty || ageStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua data fisik wajib diisi!')),
      );
      return;
    }

    double weight = double.parse(weightStr);
    double height = double.parse(heightStr);
    int age = int.parse(ageStr);

    double bmr = 0;
    if (selectedGender == 'Laki-laki') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    double tdeeMaintenance = bmr * selectedActivity;
    double targetKaloriAkhir = tdeeMaintenance;

    if (selectedGoal.contains('-100')) { targetKaloriAkhir = tdeeMaintenance - 100; }
    else if (selectedGoal.contains('-200')) { targetKaloriAkhir = tdeeMaintenance - 200; }
    else if (selectedGoal.contains('-300')) { targetKaloriAkhir = tdeeMaintenance - 300; }
    else if (selectedGoal.contains('-400')) { targetKaloriAkhir = tdeeMaintenance - 400; }
    else if (selectedGoal.contains('-500')) { targetKaloriAkhir = tdeeMaintenance - 500; } 
    else if (selectedGoal.contains('+100')) { targetKaloriAkhir = tdeeMaintenance + 100; }
    else if (selectedGoal.contains('+200')) { targetKaloriAkhir = tdeeMaintenance + 200; }
    else if (selectedGoal.contains('+300')) { targetKaloriAkhir = tdeeMaintenance + 300; }
    else if (selectedGoal.contains('+400')) { targetKaloriAkhir = tdeeMaintenance + 400; }
    else if (selectedGoal.contains('+500')) { targetKaloriAkhir = tdeeMaintenance + 500; }

    await DatabaseHelper.instance.updateUserProfile(
      widget.userId,
      selectedGender,
      double.parse(weightController.text),
      double.parse(heightController.text),
      int.parse(ageController.text),
      selectedActivity, 
      selectedGoal,   
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.green),
              SizedBox(width: 10),
              Text('Hasil Analisis Gizi', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'BMR kamu: ${bmr.toStringAsFixed(0)} Kcal\n'
            'Target Kalori Harian Baru ($selectedGoal):\n'
            '👉 ${targetKaloriAkhir.toStringAsFixed(0)} Kcal/hari.\n\n'
            'Data berhasil diperbarui di database!',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainDashboardPage(
                      userId: widget.userId,
                      targetTdee: targetKaloriAkhir,
                    ),
                  ),
                );
              },
              child: const Text('Lanjutkan', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  // Helper untuk membuat gaya input textfield yang seragam
  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF1F5F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.green, width: 1.5),
      ),
      prefixIcon: Icon(icon, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Analisis Gizi Personal",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Isi data di bawah ini untuk menghitung kalori harianmu secara akurat.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  
                  // SELEKSI GENDER
                  const Text("Jenis Kelamin", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Perempuan',
                        groupValue: selectedGender,
                        activeColor: Colors.green,
                        onChanged: (value) => setState(() => selectedGender = value!),
                      ),
                      const Text('Perempuan', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 30),
                      Radio<String>(
                        value: 'Laki-laki',
                        groupValue: selectedGender,
                        activeColor: Colors.green,
                        onChanged: (value) => setState(() => selectedGender = value!),
                      ),
                      const Text('Laki-laki', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // INPUT BERAT BADAN
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputStyle('Berat Badan (kg)', Icons.scale_outlined),
                  ),
                  const SizedBox(height: 16),
                  
                  // INPUT TINGGI BADAN
                  TextField(
                    controller: heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputStyle('Tinggi Badan (cm)', Icons.height_rounded),
                  ),
                  const SizedBox(height: 16),
                  
                  // INPUT UMUR
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: _inputStyle('Umur (tahun)', Icons.cake_outlined),
                  ),
                  const SizedBox(height: 24),
                  
                  // DROPDOWN AKTIVITAS FISIK
                  const Text("Tingkat Aktivitas Fisik", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<double>(
                    value: selectedActivity,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F5F1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: activityOptions.entries.map((entry) {
                      return DropdownMenuItem<double>(
                        value: entry.value,
                        child: Text(entry.key, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedActivity = value!),
                  ),
                  const SizedBox(height: 24),
                  
                  // DROPDOWN TARGET DIET
                  const Text("Tujuan / Target Berat Badan", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedGoal,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F5F1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: '-500', child: Text('Turunkan BB (Maksimal | -500 Kcal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '-400', child: Text('Turunkan BB (Tahap 4 | -400 Kcal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '-300', child: Text('Turunkan BB (Tahap 3 | -300 Kcal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '-200', child: Text('Turunkan BB (Tahap 2 | -200 Kcal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '-100', child: Text('Turunkan BB (Tahap Awal | -100 Kcal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '0', child: Text('Pertahankan Berat Badan (Normal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '+100', child: Text('Naikkan BB (Tahap Awal | +100 Kcal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '+200', child: Text('Naikkan BB (Tahap 2 | +200 Kcal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '+300', child: Text('Naikkan BB (Tahap 3 | +300 Kcal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '+400', child: Text('Naikkan BB (Tahap 4 | +400 Kcal)', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: '+500', child: Text('Naikkan BB (Maksimal | +500 Kcal)', style: TextStyle(fontSize: 14))),
                    ],
                    onChanged: (value) => setState(() => selectedGoal = value!),
                  ),
                  const SizedBox(height: 40),
                  
                  // TOMBOL SUBMIT
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
                      onPressed: _hitungDanSimpan,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Hitung Kebutuhan Gizi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }