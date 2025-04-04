// lib/main.dart
import 'package:flutter/material.dart';
import 'utils.dart';
import 'ai_helper.dart';
import 'package:app_usage/app_usage.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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
    _loadSettings(); // Load settings when the app starts
    requestNotificationPermissions();
    initializeNotifications();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temperature = Temperature.values[prefs.getInt('temperature') ?? Temperature.goodCop.index];
      _language = Language.values[prefs.getInt('language') ?? Language.czech.index];
      int hour = prefs.getInt('notificationHour') ?? TimeOfDay.now().hour;
      int minute = prefs.getInt('notificationMinute') ?? TimeOfDay.now().minute;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('temperature', _temperature.index);
    await prefs.setInt('language', _language.index);
    await prefs.setInt('notificationHour', _notificationTime.hour);
    await prefs.setInt('notificationMinute', _notificationTime.minute);
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
      _saveSettings(); // Save settings when the time is picked
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/scsmall.png', // Make sure the path is correct
              width: 48,
              height: 48,
            ),
          ],
        ),
        backgroundColor: Colors.red,
        centerTitle: true, // This line is no longer needed
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
                _saveSettings(); // Save settings when temperature changes
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
                _saveSettings(); // Save settings when language changes
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