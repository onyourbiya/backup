// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:nourishia/data/datasources/database_helper.dart';
import 'dashboard_harian_tab.dart';
import 'food_diary_page.dart';
import 'profil_pengguna_tab.dart';
import 'history_page.dart'; 

class MainDashboardPage extends StatefulWidget {
  final int userId;
  final double targetTdee;

  const MainDashboardPage({
    super.key,
    required this.userId,
    required this.targetTdee,
  });

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  int _currentIndex = 0;
  final GlobalKey<DashboardHarianTabState> _dashboardKey =
      GlobalKey<DashboardHarianTabState>();

  bool _isLoadingData = true;
  double _tdeeHasilHitungDinamis = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFreshUserData();
  }

  Future<void> _loadFreshUserData() async {
    try {
      final db = DatabaseHelper.instance;
      final data = await db.getUserProfile(widget.userId);
      
      if (data != null) {
        final double weight = (data['weight'] as num?)?.toDouble() ?? 0;
        final double height = (data['height'] as num?)?.toDouble() ?? 0;
        final int age = (data['age'] as int?) ?? 0;
        final String gender = data['gender'] ?? '';
        double dbActivity = (data['activity_level'] as num?)?.toDouble() ?? 1.2;
        String teksGoal = data['goal'] ?? '0';

        double bmr = 0.0;
        if (gender == 'Laki-laki') {
          bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
        } else {
          bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
        }

        double tdeeMaintenance = bmr * dbActivity;

        if (teksGoal.contains('-100')) { tdeeMaintenance -= 100; }
        else if (teksGoal.contains('-200')) { tdeeMaintenance -= 200; }
        else if (teksGoal.contains('-300')) { tdeeMaintenance -= 300; }
        else if (teksGoal.contains('-400')) { tdeeMaintenance -= 400; }
        else if (teksGoal.contains('-500')) { tdeeMaintenance -= 500; }
        else if (teksGoal.contains('+100')) { tdeeMaintenance += 100; }
        else if (teksGoal.contains('+200')) { tdeeMaintenance += 200; }
        else if (teksGoal.contains('+300')) { tdeeMaintenance += 300; }
        else if (teksGoal.contains('+400')) { tdeeMaintenance += 400; }
        else if (teksGoal.contains('+500')) { tdeeMaintenance += 500; }

        setState(() {
          _tdeeHasilHitungDinamis = tdeeMaintenance;
          _isLoadingData = false;
        });
      } else {
        setState(() {
          _tdeeHasilHitungDinamis = widget.targetTdee;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      setState(() {
        _tdeeHasilHitungDinamis = widget.targetTdee;
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBFDFB),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    double tdeeFinalSemuaUser = _tdeeHasilHitungDinamis; 
        
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFB),
      // Di-remove AppBar bawaannya supaya UI tab di dalamnya bisa nge-blend penuh sampai atas layar (Modern Look)
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardHarianTab(
              key: _dashboardKey,
              userId: widget.userId,
              targetTdee: tdeeFinalSemuaUser, 
            ),
            FoodDiaryPage(
              userId: widget.userId,
              targetTdee: tdeeFinalSemuaUser, 
              onEntryChanged: () {
                // 🌟 KODE SAKTI BARU:
                // Menyuruh Dashboard Harian untuk langsung menarik data terbaru dari database!
                _dashboardKey.currentState?.refreshData(); 
                
                setState(() {}); 
              },
            ),
            WeightAndHistoryTracker(
              userId: widget.userId,
              targetTdee: tdeeFinalSemuaUser, 
            ),
            ProfilPenggunaTab(userId: widget.userId),
          ],
        ),
      ),
      // Desain Bottom Navigation yang dipercantik dengan shadow melengkung
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey[600], // Abu-abu lembut
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: (index) {
            if (_currentIndex != index) {
              setState(() {
                _currentIndex = index;
              });
              _loadFreshUserData(); 
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.dashboard_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.dashboard_rounded),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.restaurant_menu_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.restaurant_menu_rounded),
              ),
              label: 'Diary',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.analytics_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.analytics_rounded),
              ),
              label: 'Tracker',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.person_outline_rounded),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.person_rounded),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}