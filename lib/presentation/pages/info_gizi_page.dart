import 'package:flutter/material.dart';

class InfoGiziPage extends StatelessWidget {
  const InfoGiziPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Gizi Seimbang'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Edukasi
            Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, size: 60, color: Colors.green.shade600),
                  const SizedBox(height: 12),
                  const Text(
                    "Mengenal 'Isi Piringku'",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Panduan Porsi Makan Sehat Sesuai Kemenkes RI",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              "Pembagian Porsi Sekali Makan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 96, 139, 118)),
            ),
            const SizedBox(height: 12),

            // 1. Makanan Pokok
            _buildInfoCard(
              title: "Makanan Pokok (Karbohidrat) - 2/6 Bagian",
              description: "Porsi makanan pokok seperti nasi, jagung, kentang, atau ubi sebaiknya memenuhi sekitar sepertiga (2/6) dari piring makan Anda.",
              icon: Icons.rice_bowl,
              iconColor: Colors.amber.shade700,
              bgColor: Colors.amber.shade50,
            ),

            // 2. Lauk Pauk
            _buildInfoCard(
              title: "Lauk Pauk (Protein) - 1/6 Bagian",
              description: "Sumber protein baik hewani (ikan, ayam, daging) maupun nabati (tahu, tempe) dianjurkan mengisi seperenam (1/6) bagian piring.",
              icon: Icons.set_meal,
              iconColor: Colors.red.shade600,
              bgColor: Colors.red.shade50,
            ),

            // 3. Sayur-sayuran
            _buildInfoCard(
              title: "Sayur-sayuran (Serat & Vitamin) - 2/6 Bagian",
              description: "Sama banyak dengan makanan pokok, porsi sayuran harus melimpah untuk memenuhi kebutuhan serat harian tubuh.",
              icon: Icons.eco,
              iconColor: Colors.green.shade600,
              bgColor: Colors.green.shade50,
            ),

            // 4. Buah-buahan
            _buildInfoCard(
              title: "Buah-buahan (Vitamin & Mineral) - 1/6 Bagian",
              description: "Buah-buahan bertugas melengkapi kebutuhan mikronutrisi dan antioksidan untuk menjaga daya tahan tubuh.",
              icon: Icons.apple,
              iconColor: Colors.orange.shade600,
              bgColor: Colors.orange.shade50,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Tips Tambahan Kemenkes
            const Text(
              "4 Pilar Gizi Seimbang Lainnya:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 96, 139, 106)),
            ),
            const SizedBox(height: 12),
            _buildPilarRow(Icons.water_drop, "Minum air putih minimal 8 gelas sehari."),
            _buildPilarRow(Icons.clean_hands, "Cuci tangan pakai sabun sebelum makan."),
            _buildPilarRow(Icons.fitness_center, "Lakukan aktivitas fisik/olahraga teratur."),
            _buildPilarRow(Icons.scale, "Pantau berat badan secara berkala."),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPilarRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}