// lib/main.dart
import 'package:flutter/material.dart';
import 'utils.dart';
import 'ai_helper.dart';
import 'package:app_usage/app_usage.dart';
import 'notification_service.dart'; // Import the notification service

void main() => runApp(ScreenSheriffApp());

enum Temperature { goodCop, badCop }

enum Language { czech, english }

class ScreenSheriffApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScreenSheriff(),
    );
  }
}

class ScreenSheriff extends StatefulWidget {
  const ScreenSheriff({Key? key});

  @override
  ScreenSheriffAppState createState() => ScreenSheriffAppState();
}

class ScreenSheriffAppState extends State<ScreenSheriff> {
  List<AppUsageInfo> _infos = [];
  final AiHelper aiHelper = AiHelper();
  bool _isLoading = false;

  Temperature _temperature = Temperature.goodCop;
  Language _language = Language.czech;
  TimeOfDay _notificationTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    requestNotificationPermissions();
    initializeNotifications();
  }

  List<AppUsageInfo> getTopTenApps(List<AppUsageInfo> infos) {
    infos.sort((a, b) => b.usage.compareTo(a.usage));
    return infos.take(10).toList();
  }

  Future<void> _generateTestNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<AppUsageInfo> usageInfo = await getUsageStats();
      setState(() {
        _infos = usageInfo;
      });

      if (_infos.isNotEmpty) {
        int totalMinutes = getTopTenApps(_infos)
            .fold(0, (sum, info) => sum + info.usage.inMinutes);
        double totalHours = totalMinutes / 60;
        List<String> appNames = getTopTenApps(_infos)
            .map((info) => '${info.packageName}: ${info.usage.inMinutes.toString()} min')
            .toList();

        Map<String, dynamic> notification = await aiHelper.generateNotification(
            totalHours.round(),
            appNames,
            _temperature == Temperature.goodCop,
            _language == Language.czech);

        showNotification(notification['header'], notification['body']); // Use the function from notification_service.dart
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (pickedTime != null && pickedTime != _notificationTime) {
      setState(() {
        _notificationTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👮‍♂️ ScreenSheriff'),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Notification Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Temperature'),
            trailing: DropdownButton<Temperature>(
              value: _temperature,
              onChanged: (Temperature? newValue) {
                setState(() {
                  _temperature = newValue!;
                });
              },
              items: Temperature.values
                  .map<DropdownMenuItem<Temperature>>((Temperature value) {
                return DropdownMenuItem<Temperature>(
                  value: value,
                  child: Text(value == Temperature.goodCop
                      ? 'Good Cop'
                      : 'Bad Cop'),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<Language>(
              value: _language,
              onChanged: (Language? newValue) {
                setState(() {
                  _language = newValue!;
                });
              },
              items: Language.values
                  .map<DropdownMenuItem<Language>>((Language value) {
                return DropdownMenuItem<Language>(
                  value: value,
                  child: Text(value == Language.czech ? 'Czech' : 'English'),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Notification Time'),
            subtitle: Text(
                '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}'),
            trailing: Icon(Icons.access_time),
            onTap: () => _selectTime(context),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64.0),
            child: TextButton(
              style: ButtonStyle(
                foregroundColor:
                MaterialStateProperty.all<Color>(Colors.black54),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    side: const BorderSide(color: Colors.black54, width: 3),
                  ),
                ),
              ),
              onPressed: _isLoading ? null : _generateTestNotification,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.black54),
                        strokeWidth: 3,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isLoading ? 'working...' : 'send test notification',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}