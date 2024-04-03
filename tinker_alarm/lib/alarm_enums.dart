enum ConditionType
{
  none,
  ifEarlierAlarmPresent,
  ifLaterAlarmPresent,
  ifBeforeDate,
  ifAfterDate,
  onDaysOfTheWeek,
  onDaysOfTheMonth,
  onDaysOfTheYear,
  onHolidays,
}

enum EffectType
{
  alarm,
  delete,
  deactivate,
  reactivate,
}