# Phase 9: Push Notifications

## Tujuan
Implementasi notifikasi untuk reminder waktu solat.

## Deliverables

### 9.1 Notification Service
- Setup flutter_local_notifications
- Setup android_alarm_manager_plus untuk exact alarms
- Request notification permissions

### 9.2 Prayer Time Notifications
- Schedule notifikasi untuk setiap waktu solat
- Trigger saat masuk waktu ("Sudah masuk waktu Dzuhur")
- Re-schedule setiap hari setelah fetch jadwal baru

### 9.3 Notification Actions (Opsional)
- Action button untuk quick check-in
- Tap notification → buka app ke home screen

### 9.4 Background Handling
- Handle notifikasi saat app di-kill
- Persist scheduled alarms
- Cancel old alarms saat reschedule

## Kriteria Selesai
- [x] Notifikasi muncul tepat waktu
- [x] Works saat app di background/killed
- [x] Reschedule otomatis setiap hari
- [x] Toggle on/off berfungsi dari settings
