import 'alarm_enums.dart';

bool isSameMinute(DateTime dateTime1, DateTime dateTime2) {
  return dateTime1.year == dateTime2.year &&
         dateTime1.month == dateTime2.month &&
         dateTime1.day == dateTime2.day &&
         dateTime1.hour == dateTime2.hour &&
         dateTime1.minute == dateTime2.minute;
}

// TODO: Fix this or make alarm.time update to the next day when the alarm is triggered
// Also make sure deactivated alarms on that day are counted
bool isSameDay(DateTime dateTime1, DateTime dateTime2) {
  return dateTime1.year == dateTime2.year &&
         dateTime1.month == dateTime2.month &&
         dateTime1.day == dateTime2.day;
}

class AlarmList
{
  List<Alarm> alarms = [];

  AlarmList();

  void checkAlarms() {
    for (Alarm alarm in alarms) {
      var preAlarmRules = alarm.rules.where((rule) => rule.effect == EffectType.reactivate).toList();
      for (Rule rule in preAlarmRules) {
        if (rule.evaluate() == true) {
          alarm.active = true;
          // UPDATE UI
          break;
        }
      }

      var alarmSoundingRules = alarm.rules.where((rule) => rule.effect == EffectType.alarm).toList();
      if (alarm.active == true &&
          isSameMinute(alarm.time, DateTime.now()) &&
          (alarmSoundingRules.isEmpty || alarmSoundingRules.any((rule) => rule.evaluate() == true)) &&
          alarm.ignoreTriggers == 0)
      {
        // SOUND THE ALARM
      }
      if (alarm.ignoreTriggers > 0) {
        alarm.ignoreTriggers -= 1;
        // UPDATE UI
      }

      var postAlarmRules = alarm.rules.where((rule) => rule.effect == EffectType.deactivate || rule.effect == EffectType.delete).toList();
      for (Rule rule in postAlarmRules) {
        if (rule.evaluate() == false) { continue; }
        switch (rule.effect) {
          case EffectType.delete:
            alarms.remove(alarm);
            // UPDATE UI
            break;
          case EffectType.deactivate:
            alarm.active = false;
            // UPDATE UI
            break;
          default:
            break;
          }
        }
      }
    }

  bool hasEarlierAlarm(DateTime targetTime) {
    // Filter for all alarms on specified date
    List<Alarm> alarmsOnDate = alarms.where((alarm) => isSameDay(alarm.time, targetTime)).toList();
    if (alarmsOnDate.isEmpty) { return false; }
    // Check if there is an alarm earlier than the given time
    for (Alarm alarm in alarmsOnDate) {
      if (alarm.time.isBefore(targetTime)) { return true; }
    }
    return false;
  }

  bool hasLaterAlarm(DateTime targetTime) {
    List<Alarm> alarmsOnDate = alarms.where((alarm) => isSameDay(alarm.time, targetTime)).toList();
    if (alarmsOnDate.isEmpty) { return false; }

    for (Alarm alarm in alarmsOnDate) {
      if (alarm.time.isAfter(targetTime)) { return true; }
    }
    return false;
  }
}

class Alarm
{
  AlarmList parentList;
  String name = '';
  DateTime time = DateTime.now();
  List<Rule> rules = [];
  int ignoreTriggers = 0;
  bool active = true;

  Alarm(this.parentList);
}

class Rule
{
  Alarm parentAlarm;
  ConditionType condition;
  EffectType effect;
  List<dynamic> parameters;

  Rule(this.parentAlarm, this.condition, this.effect, this.parameters);

  bool evaluate() {
    switch (condition) {
      case ConditionType.none:
        return true;
      case ConditionType.ifEarlierAlarmPresent:
        // Conditions will only be checked when the current time is the same as the alarm time, so we can use DateTime.now() here
        return parentAlarm.parentList.hasEarlierAlarm(DateTime.now());
      case ConditionType.ifLaterAlarmPresent:
        return parentAlarm.parentList.hasLaterAlarm(DateTime.now());
      case ConditionType.ifBeforeDate:
        // Parameter 0 is a DateTime object representing the target date
        return parentAlarm.time.isBefore(parameters[0]);
      case ConditionType.ifAfterDate:
        // Parameter 0 is a DateTime object representing the target date
        return parentAlarm.time.isAfter(parameters[0]);
      case ConditionType.onDaysOfTheWeek:
        // Parameter 0 is a Set<int> representing the days of the week the alarm should trigger on
        return parameters[0].contains(parentAlarm.time.weekday);
      case ConditionType.onDaysOfTheMonth:
        // Parameter 0 is a Set<int> representing the days of the month the alarm should trigger on
        return parameters[0].contains(parentAlarm.time.day);
      case ConditionType.onDaysOfTheYear:
        // Parameter 0 is a Set<DateTime> representing the days of the year the alarm should trigger on
        return parameters[0].any((date) => isSameDay(date, parentAlarm.time));
      // case ConditionType.onHolidays: // For a future update
      //   return true;
      default:
        return false;
    }
  }
}