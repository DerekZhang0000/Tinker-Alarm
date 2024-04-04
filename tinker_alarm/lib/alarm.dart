import 'alarm_enums.dart';

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
  /*
    AlarmList class that contains a list of alarms
    Alarms are checked to determine if they should trigger
  */
  List<Alarm> alarms = [];

  AlarmList();

  void addAlarm(Alarm alarm)
  {
    alarms.add(alarm);
  }
  void modifyAlarm(Alarm alarm, Alarm newAlarm)
  {
    alarms[alarms.indexOf(alarm)] = newAlarm;
  }
  void removeAlarm(Alarm alarm)
  {
    alarms.remove(alarm);
  }
  bool isEarliestAlarm(Alarm testAlarm, List<Alarm> activeAlarms)
  { // Alarm list must only contain alarms that will trigger on the current day
    for (Alarm alarm in activeAlarms)
    {
      if (alarm != testAlarm &&
          isEarlierInTheDay(alarm.triggerTime, testAlarm.triggerTime))
      {
        return false;
      }
    }
    return true;
  }
  bool isLatestAlarm(Alarm testAlarm, List<Alarm> activeAlarms)
  { // Alarm list must only contain alarms that will trigger on the current day
    for (Alarm alarm in activeAlarms)
    {
      if (alarm != testAlarm &&
          isEarlierInTheDay(testAlarm.triggerTime, alarm.triggerTime))
      {
        return false;
      }
    }
    return true;
  }
  void checkAlarms()
  {
    List<Alarm> activeAlarms = [];  // Alarms that will trigger on the current day
    for (Alarm alarm in alarms)
    {
      var reactivationPolicies = alarm.policies.where((policy) => policy.effect == EffectType.reactivate).toList();
      for (Policy policy in reactivationPolicies)
      {
        if (policy.evaluate() == true) {
          alarm.isActive = true;
          // UPDATE UI
          break;
        }
      }

      if (alarm.isActive && alarm.policies.every((policy) => policy.evaluate() == true)) {
        activeAlarms.add(alarm);
      }
    }
    for (Alarm alarm in activeAlarms)
    {
      var alarmPolicies = alarm.policies.where((policy) => policy.effect != EffectType.reactivate).toList();
      if (alarm.isActive &&                                                                        // Alarm is active
          isSameMinute(alarm.triggerTime, DateTime.now()) &&                                       // The current time is the trigger time
          (alarmPolicies.isEmpty || alarmPolicies.every((policy) => policy.evaluate() == true)) &&  // All policies are satisfied
          (alarm.activateIfEarliest == false || isEarliestAlarm(alarm, activeAlarms)) &&           // Alarm does not need to be the earliest of the day, or it is
          (alarm.activateIfLatest == false || isLatestAlarm(alarm, activeAlarms)))                 // Alarm does not need to be the latest of the day, or it is
      {
        if (alarm.ignoreTriggers > 0) {
          alarm.ignoreTriggers--;
          // UPDATE UI
        } else {
          // SOUND THE ALARM
        }
      }

      for (Policy policy in alarmPolicies)
      {
        if (policy.evaluate() == false) { continue; }
        switch (policy.effect)
        {
          case EffectType.delete:
            alarms.remove(alarm);
            // UPDATE UI
            break;
          case EffectType.deactivate:
            alarm.isActive = false;
            // UPDATE UI
            break;
          default:
            break;
        }
      }
    }
  }
}

class Alarm
{
  /*
    Alarm class that contains a name, trigger time, active status, ignore triggers count, and policies
    All policies are evaluated to determine if the alarm should trigger
    ignoreTriggers is used to prevent the alarm from triggering for a set number of times
    Alarm can be set to only trigger if it is the earliest and/or latest alarm of the day
  */
  String alarmName;
  DateTime triggerTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0, 0, 0);
  bool isActive = true;
  int ignoreTriggers = 0;
  bool activateIfEarliest = false;  // Alarm will only trigger if it is the earliest alarm of the day
  bool activateIfLatest = false;  // Alarm will only trigger if it is the latest alarm of the day
  List<Policy> policies = [];

  Alarm(this.alarmName);

  void addPolicy(Policy policy)
  {
    policies.add(policy);
  }
  void modifyPolicy(Policy policy, Policy newPolicy)
  {
    policies[policies.indexOf(policy)] = newPolicy;
  }
  void removePolicy(Policy policy)
  {
    policies.remove(policy);
  }
}

class Policy
{
  /*
    Policy class that contains a condition to be met and an effect to be executed for an alarm
    Policies can be associated with other policies to create complex conditions
  */
  ConditionType condition;
  EffectType effect;
  List<Policy> associatedPolicies = [];
  List<dynamic> parameters = [];

  Policy(this.condition, this.effect);

  bool evaluate()
  {
    for (Policy policy in associatedPolicies)
    {
      if (policy.evaluate() == false) { return false; }
    }

    switch (condition)
    {
      case ConditionType.none:
        return true;
      case ConditionType.ifBeforeDate:
        // parameters[0] is a DateTime representing the target date
        return DateTime.now().isBefore(parameters[0]);
      case ConditionType.ifAfterDate:
        // parameters[0] is a DateTime representing the target date
        return DateTime.now().isAfter(parameters[0]);
      case ConditionType.onDaysOfTheWeek:
        // parameters[0] is a List<int> containing the days of the week
        return parameters[0].contains(DateTime.now().weekday);
      case ConditionType.onDaysOfTheMonth:
        // parameters[0] is a List<int> containing the days of the month
        return parameters[0].contains(DateTime.now().day);
      case ConditionType.onDaysOfTheYear:
        // parameters[0] is a List<DateTime> containing the days of the year
        return parameters[0].any((dateTime) => isSameDay(DateTime.now(), dateTime));
      // case ConditionType.onHolidays:  // For a future update
      //   return false;
      default:
        return false;
    }
  }
  void addAssociatedPolicy(Policy policy)
  {
    associatedPolicies.add(policy);
  }
  void modifyAssociatedPolicy(Policy policy, Policy newPolicy)
  {
    associatedPolicies[associatedPolicies.indexOf(policy)] = newPolicy;
  }
  void removeAssociatedPolicy(Policy policy)
  {
    associatedPolicies.remove(policy);
  }
}