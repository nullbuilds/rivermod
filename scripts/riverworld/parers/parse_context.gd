class_name ParseContext
extends Object
## Similar to PackedByteArray but with added support for creating read-only
## windows into a parent context for efficient parsing within bounds in addition
## to support for logging contextual messages.

var _buffer: PackedByteArray
var _start_cursor: int
var _current_position: int
var _end_cursor: int
var _events: Array[ContextEvent]

## Creates a parse context from a copy of the given byte array.
static func from_bytes(bytes: PackedByteArray) -> ParseContext:
	assert(bytes != null, "bytes must not be null")
	
	var context: ParseContext = ParseContext.new()
	context._buffer = bytes.duplicate()
	context._start_cursor = 0
	context._current_position = 0
	context._end_cursor = bytes.size()
	context._events = []
	
	return context


## Creates a new parse context from the current position of a parent
## context up to a specified number of bytes.
## 
## The returned context shares the parent's internal data making it more memory
## efficient. This does not consume the bytes from the parent context.
## 
## Any logged context messages will be automatically included in the parent
## context.
static func from_parent(parent: ParseContext, \
		window_size: int) -> ParseContext:
	assert(parent != null, 'parent context must not be null')
	
	if window_size < 0:
		push_error('Desired window size (%d) cannot be negative; adjusted to 0' % \
				window_size)
		window_size = 0
	
	var end_cursor = parent._current_position + window_size
	if end_cursor > parent._end_cursor:
		end_cursor = parent._end_cursor
		var new_size = end_cursor - parent._current_position
		push_error('Desired window size of %d would exceed the remaining size of the parent context; the window size has been truncated to %d' % \
				[window_size, new_size])
	
	var context = ParseContext.new()
	context._buffer = parent._buffer
	context._start_cursor = parent._current_position
	context._current_position = parent._current_position
	context._end_cursor = end_cursor
	context._messages = parent._messages
	
	return context


## Returns the number of bytes left in the context.
func get_remaining_bytes() -> int:
	return _end_cursor - _current_position


## Returns whether this context has at least the provided number of bytes
## remaining.
func has_remaining_bytes(bytes: int = 1) -> bool:
	return get_remaining_bytes() >= bytes


## Returns the next 32-bit litte-endian encoded unsigned integer from the
## context and advances the cursor.
func next_u32le() -> int:
	assert(has_remaining_bytes(4), 'Insufficient bytes remaining to decode a u32le; %d remaining' % \
			get_remaining_bytes())
	
	var value = _buffer.decode_u32(_current_position)
	_current_position += 4
	return value


## Returns the next n bytes as an ASCII string and advances the cursor.
func next_fixed_length_string(length: int) -> String:
	if length < 0:
		push_error('Length %d cannot be less than 0; adjusted to 0' % length)
		length = 0
	
	if !has_remaining_bytes(length):
		var remaining_bytes = get_remaining_bytes()
		push_error('Desired length of %d is greater than the number of remaining bytes; truncated to %d' % \
				[length, remaining_bytes])
		length = remaining_bytes
	
	return next_bytes(length).get_string_from_ascii()


## Returns the next n bytes as an array and advances the cursor
func next_bytes(length: int) -> PackedByteArray:
	if length < 0:
		push_error('Length %d cannot be less than 0; adjusted to 0' % length)
		length = 0
	
	if !has_remaining_bytes(length):
		var remaining_bytes = get_remaining_bytes()
		push_error('Desired length of %d is greater than the number of remaining bytes; truncated to %d' % \
				[length, remaining_bytes])
		length = remaining_bytes
	
	var end_position = _current_position + length
	var bytes = _buffer.slice(_current_position, end_position)
	_current_position += length
	return bytes


## Logs a warning to the context.
func log_warning(message: String):
	_log_event(ContextEvent.Level.WARNING, message)


## Logs an error to the context.
func log_error(message: String):
	_log_event(ContextEvent.Level.ERROR, message)


## Returns all context events logged.
## 
## Note that this includes any events logged to the parent context as well.
func get_events() -> Array[ContextEvent]:
	# Duplicate to prevent external modification
	return _events.duplicate()


## Logs an event to the context.
func _log_event(level: ContextEvent.Level, message: String):
	_events.append(ContextEvent.new(level, message))


## Represents an event recorded during the processing of a
## ParseContext.
class ContextEvent:
	## Represents the level of a ContextEvent.
	enum Level {
		## The event is non-critical but may result in a unexpected behavior.
		WARNING,
		
		## The event indicates an error preventing parsing.
		ERROR
	}
	
	var _level: Level
	var _message: String
	
	## Construct a new message at the given level.
	func _init(level: Level, message: String):
		_level = level
		_message = message
	
	
	## Returns the message level.
	func get_level() -> Level:
		return _level
	
	
	## Returns the message.
	func get_message() -> String:
		return _message
