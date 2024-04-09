bool isSameMinute(DateTime date1, DateTime date2)
{
  return date1.hour == date2.hour && date1.minute == date2.minute;
}

bool isSameDay(DateTime date1, DateTime date2)
{
  return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}

bool isEarlierInTheDay(DateTime date1, DateTime date2)
{
  return date1.hour < date2.hour || (date1.hour == date2.hour && date1.minute < date2.minute);
}

class AlarmList
{
  List<TinkerAlarm> alarms = [];


  List<TinkerAlarm> sortAlarms(List<TinkerAlarm> alarms)
  {
    alarms.sort((alarmA, alarmB) => alarmA.getNextTriggerTime()!.compareTo(alarmB.getNextTriggerTime()!));
    return alarms;
  }
  List<TinkerAlarm> getAlarmsForToday()
  { // Returns a list of alarms that will trigger today
    List<TinkerAlarm> alarmsForToday = [];
    alarms.forEach((alarm) {
      DateTime now = DateTime.now();
      if (alarm.getNextTriggerTime() != null && isSameDay(now, alarm.getNextTriggerTime()!)) {
        alarmsForToday.add(alarm);
      }
    });
    alarmsForToday = sortAlarms(alarmsForToday);
    return alarmsForToday;
  }
  void triggerAlarms(List<TinkerAlarm> alarms)
  { // Tests each alarm in a sorted list of alarms and triggers it if it is time
    TinkerAlarm earliestAlarm = alarms.first;
    TinkerAlarm latestAlarm = alarms.last;
    alarms.forEach((alarm) {
      if ((!alarm.activateIfEarliest && !alarm.activateIfLatest) ||
          (alarm.activateIfEarliest && alarm == earliestAlarm) ||
          (alarm.activateIfLatest && alarm == latestAlarm))
      {
        bool alarmTriggered = alarm.alarmTrigger();
        if (alarmTriggered && alarm.autoDelete) {
          alarms.remove(alarm);
        }
      }
    });
  }
}

class TinkerAlarm
{
  String? alarmName;
  DateTime triggerTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0, 0, 0);
  bool isActive = true;               // Whether or not alarm will trigger at its trigger time, can ONLY be set to false by the user
  int triggersToIgnore = 0;           // Number of triggers to ignore before the alarm is activated
  bool autoDelete = false;            // The alarm is deleted when it is deactivated UNLESS it was deactivated by the user  (managed by the AlarmList)
  bool activateIfEarliest = false;    // Alarm will only trigger if it is the earliest alarm of the day                     (managed by the AlarmList)
  bool activateIfLatest = false;      // Alarm will only trigger if it is the latest alarm of the day                       (managed by the AlarmList)
  DateTime? specifiedActivationDay;   // Alarm will only trigger after the specified day
  List<int> daysOfTheWeek = [];       // Days of the week the alarm will trigger

  TinkerAlarm();

  bool triggerConditionsMet(DateTime checkTime)
  {
    return isSameMinute(checkTime, triggerTime) &&
           (daysOfTheWeek.isEmpty || daysOfTheWeek.contains(checkTime.weekday)) &&
           (specifiedActivationDay == null || checkTime.isAfter(specifiedActivationDay!));
  }
  bool alarmTrigger()
  { // Returns true if the alarm is triggered
    if (isActive && triggerConditionsMet(DateTime.now())) {
      if (triggersToIgnore > 0) {
        triggersToIgnore--;
      } else {
        // Trigger the alarm here
        return true;
      }
    }
    return false;
  }
  DateTime? simNextTrigger()
  { // Simulates the next time the alarm will trigger, returns the DateTime of the next trigger or null if the alarm will not trigger within the next 30 days
    int triggersToIgnoreCopy = triggersToIgnore;
    DateTime now = DateTime.now();
    DateTime simulationLimit = now.add(const Duration(days: 30, seconds: 1));
    DateTime nextTriggerTime = DateTime(now.year, now.month, now.day, triggerTime.hour, triggerTime.minute, 0, 0, 0).add(Duration(days: 1));
    while (nextTriggerTime.isBefore(simulationLimit)) {
      if (triggerConditionsMet(nextTriggerTime)) {
        if (triggersToIgnoreCopy == 0) {
          return nextTriggerTime;
        } else {
          triggersToIgnoreCopy--;
        }
      }
      nextTriggerTime = nextTriggerTime.add(const Duration(days: 1));
    }
    return null;  // If the alarm will not trigger within the next 30 days
  }
  DateTime? getNextTriggerTime()
  { // Returns the DateTime of the next trigger or null if the alarm will not trigger within the next 30 days
    if (!isActive) { return null; }
    DateTime now = DateTime.now();
    DateTime nextTriggerTime = DateTime(now.year, now.month, now.day, triggerTime.hour, triggerTime.minute, 0, 0, 0);
    if (isEarlierInTheDay(now, nextTriggerTime)) {
      return nextTriggerTime;
    } else {
      return simNextTrigger();
    }
  }
}