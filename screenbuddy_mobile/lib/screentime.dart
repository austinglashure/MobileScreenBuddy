import 'package:usage_stats/usage_stats.dart';
import 'dart:async';

/*Collects all the android events for a given time period, then prunes it down
to only contain the ones that */
Future<List<EventUsageInfo>> getScreenActions(
  DateTime start,
  DateTime end,
) async {
  List<EventUsageInfo> allActions = await UsageStats.queryEvents(start, end);
  return allActions.where((event) {
    return event.eventType == '15' || event.eventType == '16';
  }).toList();
}

int calculateTotalScreenTimeMinutes(List<EventUsageInfo> events) {
  Duration totalOn = Duration.zero;
  DateTime? lastOn;

  // Ensure sorted by timestamp
  events.sort((a, b) => a.timeStamp!.compareTo(b.timeStamp!));

  for (var event in events) {
    final ts = DateTime.fromMillisecondsSinceEpoch(int.parse(event.timeStamp!));
    if (event.eventType == '15') {
      // Screen turned on
      lastOn = ts;
    } else if (event.eventType == '16' && lastOn != null) {
      // Screen turned off; accumulate duration
      totalOn += ts.difference(lastOn);
      lastOn = null;
    }
  }

  // If the list ends with an “on” without a corresponding “off”,
  // you could treat it as running until now (or end of day):
  // if (lastOn != null) totalOn += DateTime.now().difference(lastOn);

  return totalOn.inMinutes;
}

int decideGoal(int goalMinutes, int screenMinutes) {
  int remainder = goalMinutes % screenMinutes;
  if (remainder == goalMinutes) {
    return 0;
  } else {
    return 1;
  }
}
