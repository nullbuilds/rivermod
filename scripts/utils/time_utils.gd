class_name TimeUtils
extends Object
## Utilities for dealing with time.

## Gets the string representation of the given date.
static func get_local_date_time(utc_timestamp: int, utc_offset: int) -> String:
	var adjusted_timestamp: int = utc_timestamp + utc_offset * 60
	
	var parts: Dictionary = Time.get_datetime_dict_from_unix_time(adjusted_timestamp)
	var year: int = parts.year
	var month: int = parts.month
	var day: int = parts.day
	var hour: int = parts.hour
	var minute: int = parts.minute
	var second: int = parts.second
	
	var date_string: String = _format_date_iso_8601(year, month, day)
	var time_string: String = _format_time_12_hour(hour, minute, second)
	
	return "%s %s" % [date_string, time_string]


## Gets the string representation of the given time.
static func get_local_time(utc_timestamp: int, utc_offset: int) -> String:
	var adjusted_timestamp: int = utc_timestamp + utc_offset * 60
	
	var parts: Dictionary = Time.get_time_dict_from_unix_time(adjusted_timestamp)
	var hour: int = parts.hour
	var minute: int = parts.minute
	var second: int = parts.second
	
	return _format_time_12_hour(hour, minute, second)


## Formats an hour, minute, and second into a 12 hour format.
static func _format_time_12_hour(hour: int, minute: int, second: int) -> String:
	var elapsed_seconds: int = hour * 3600 + minute * 60 + second
	var meridiem: String = "AM"
	
	if hour == 0:
		hour = 12
	if elapsed_seconds > 43200:
		hour -= 12
		meridiem = "PM"
	
	return "%02d:%02d:%02d %s" % [hour, minute, second, meridiem]


## Formats a year, month, and day into ISO-8601 format
static func _format_date_iso_8601(year: int, month: int, day: int) -> String:
	return "%04d-%02d-%02d" % [year, month, day]
