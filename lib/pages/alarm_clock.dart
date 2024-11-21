import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:convert';

class AlarmScreen extends StatefulWidget {
  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<String> _alarmTimes = []; // Danh sách các khung giờ báo thức
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadAlarmTimes();
    _startCheckingAlarm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAlarmTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = prefs.getStringList('alarm_times') ?? [];
    setState(() {
      _alarmTimes = alarms;
    });
  }

  Future<void> _saveAlarmTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('alarm_times', _alarmTimes);
  }

  void _startCheckingAlarm() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      final now = TimeOfDay.now();
      final currentTime = now.format(context);
      if (_alarmTimes.contains(currentTime)) {
        _playAlarmSound();
        _showAlarmNotification(currentTime);
        _removeAlarm(currentTime);
      }
    });
  }

  void _playAlarmSound() async {
    await _audioPlayer.play(AssetSource('audio/aaa.mp3'));
  }

  void _showAlarmNotification(String alarmTime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Báo thức!'),
        content: Text('Đến giờ $alarmTime rồi!'),
        actions: [
          TextButton(
            onPressed: () {
              _audioPlayer.stop();
              Navigator.of(context).pop();
            },
            child: Text('Tắt'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAlarm() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final formattedTime = time.format(context);
      if (!_alarmTimes.contains(formattedTime)) {
        setState(() {
          _alarmTimes.add(formattedTime);
        });
        await _saveAlarmTimes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Khung giờ này đã được thêm trước đó!')),
        );
      }
    }
  }

  Future<void> _removeAlarm(String alarmTime) async {
    setState(() {
      _alarmTimes.remove(alarmTime);
    });
    await _saveAlarmTimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đồng Hồ Báo Thức'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _addAlarm,
              child: Text('Thêm khung giờ báo thức'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _alarmTimes.isEmpty
                  ? Center(
                      child: Text('Chưa có khung giờ báo thức nào.'),
                    )
                  : ListView.builder(
                      itemCount: _alarmTimes.length,
                      itemBuilder: (context, index) {
                        final alarmTime = _alarmTimes[index];
                        return ListTile(
                          title: Text(
                            alarmTime,
                            style: TextStyle(fontSize: 18),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeAlarm(alarmTime),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
