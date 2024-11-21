import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


class AlarmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AlarmHomePage(),
    );
  }
}

class AlarmHomePage extends StatefulWidget {
  @override
  _AlarmHomePageState createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> alarms = [];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // Khởi tạo múi giờ

    initializeNotifications();
  }

  void initializeNotifications() async {
    final initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Đảm bảo kênh được thiết lập chính xác
    const androidChannel = AndroidNotificationChannel(
      'alarm_channel', // ID kênh
      'Alarm Channel', // Tên kênh
      description: 'Channel for alarm notifications',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('aaa.mp3'), // Âm thanh tùy chỉnh
    );

    final plugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(androidChannel);
  }


  Future<void> scheduleAlarm(DateTime scheduledDate, int id) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Channel',
      channelDescription: 'Channel for alarm notifications',
      sound: RawResourceAndroidNotificationSound('aaa'),
      importance: Importance.max,
      priority: Priority.high,
    );

    final platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
      id,
      'Báo thức',
      'Đến giờ bạn cài đặt!',
      scheduledDate,
      platformChannelSpecifics,
    );
  }

  void addAlarm(TimeOfDay time) {
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Thời gian đã qua, hãy chọn giờ khác."),
      ));
      return;
    }

    final id = alarms.length + 1;
    alarms.add({
      'time': time,
      'enabled': true,
      'id': id,
    });

    scheduleAlarm(scheduledDate, id);

    setState(() {});
  }

  void toggleAlarm(int index) {
    setState(() {
      alarms[index]['enabled'] = !alarms[index]['enabled'];
    });
  }

  void deleteAlarm(int index) {
    setState(() {
      alarms.removeAt(index);
    });
  }

  Future<void> pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      addAlarm(pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Báo Thức'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          final time = alarm['time'];
          final isEnabled = alarm['enabled'];

          return ListTile(
            leading: Icon(
              Icons.alarm,
              color: isEnabled ? Colors.green : Colors.grey,
            ),
            title: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isEnabled,
                  onChanged: (value) => toggleAlarm(index),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteAlarm(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickTime,
        child: Icon(Icons.add),
      ),
    );
  }
}