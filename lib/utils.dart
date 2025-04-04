import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestNotificationPermissions() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

Future<List<AppUsageInfo>> getUsageStats() async {
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
    return top10;
  } catch (exception) {
    // Handle the exception appropriately
    print('Error getting app usage: $exception');
    return []; // Return an empty list in case of error
  }
}

