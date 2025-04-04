import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';

void main() => runApp(ScreenSheriff());

class ScreenSheriff extends StatefulWidget {
  const ScreenSheriff({super.key});

  @override
  ScreenSheriffAppState createState() => ScreenSheriffAppState();
}

class ScreenSheriffAppState extends State<ScreenSheriff> {
  List<AppUsageInfo> _infos = [];

  @override
  void initState() {
    super.initState();
  }

  void getUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(hours: 24));
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
        startDate,
        endDate,
      );
      // Sort the list descending by usage time
      infoList.sort((a, b) => b.usage.compareTo(a.usage));
      // Keep only the top 10 apps
      List<AppUsageInfo> top10 = infoList.take(10).toList();
      setState(() => _infos = top10);
    } catch (exception) {
      // should be handled?
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('👮‍♂️ ScreenSheriff'),
          backgroundColor: Colors.red,
        ),
        body: ListView.builder(
          itemCount: _infos.length,
          itemBuilder: (context, index) {
            // Convert usage time to minutes.
            int minutes = _infos[index].usage.inMinutes;
            return ListTile(
              title: Text('${_infos[index].appName} - ${_infos[index].packageName}'),
              trailing: Text('${minutes.toStringAsFixed(2)} min'),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: getUsageStats,
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          child: Icon(Icons.file_download),
        ),
      ),
    );
  }
}