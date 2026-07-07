import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Inisialisasi Fitur Notifikasi
 Future<void> initNotification() async {
    tz.initializeTimeZones();

    // 1. Pengaturan untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // 4. Gabungkan semua pengaturan di sini
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      linux: initializationSettingsLinux, 
    );

    // Minta izin ke user (khusus Android)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin.initialize(initializationSettings);
  }
  // 2. Fungsi untuk Menjadwalkan Pengingat Harian (Jam & Menit Berulang)
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // Deteksi waktu saat ini berdasarkan zona waktu lokal hp
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    
    // Tentukan jam pencatatan makan yang ditargetkan
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Jika jam tersebut sudah lewat untuk hari ini, jadwalkan buat besoknya
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Detail bentuk notifikasi di Android
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pengingat_makan_channel', // Id Channel
      'Pengingat Makan Nourishia', // Nama Channel
      channelDescription: 'Channel untuk mengingatkan catat makanan harian',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Daftarkan jadwal ke dalam sistem HP
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 🌟 Kunci agar berulang tiap hari di jam yang sama
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 3. Fungsi Membatalkan Notifikasi jika user ingin mematikan pengingat
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}