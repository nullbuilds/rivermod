class_name DeserializationContext
extends Object
## Similar to PackedByteArray but with added support for creating read-only
## windows into a parent context for efficient parsing within bounds in addition
## to support for logging contextual messages.

var _buffer: PackedByteArray
var _start_cursor: int
var _current_position: int
var _end_cursor: int
var _messages: Array[ContextMessage]

## Creates a deserialization context from the bytes of a file.
## 
## Returns null when an error is encountered loading the file.
static func from_file(file_path: String) -> DeserializationContext:
	assert(!file_path.strip_edges().is_empty(), 'File path must not be empty')
	
	var buffer = FileAccess.get_file_as_bytes(file_path)
	if buffer.is_empty():
		var error = FileAccess.get_open_error()
		if error != OK:
			push_error('Error %d encountered while loading bytes from "%s"' % \
					[error, file_path])
			return null
	
	var context: DeserializationContext = DeserializationContext.new()
	context._buffer = buffer.duplicate()
	context._start_cursor = 0
	context._current_position = 0
	context._end_cursor = buffer.size()
	context._messages = []
	
	return context


## Creates a new deserialization context from the current position of a parent
## context up to a specified number of bytes.
## 
## The returned context shares the parent's internal data making it more memory
## efficient. This does not consume the bytes from the parent context.
## 
## Any logged context messages will be automatically included in the parent
## context.
static func from_parent(parent: DeserializationContext, \
		window_size: int) -> DeserializationContext:
	assert(parent != null, 'Parent context must not be null')
	
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
	
	var context = DeserializationContext.new()
	context._buffer = parent._buffer
	context._start_cursor = parent._current_position
	context._current_position = parent._current_position
	context._end_cursor = end_cursor
	context._messages = parent._messages
	
	return context


## Returns the number of bytes left in the context.
func get_remaining_bytes() -> int:
	return _end_cursor - _current_position


## Returns the number of bytes read from this context.
func get_read_bytes() -> int:
	return _current_position - _start_cursor


## Returns whether this context has at least the provided number of bytes
## remaining.
func has_remaining_bytes(bytes: int = 1) -> bool:
	return get_remaining_bytes() >= bytes


## Consumes the provided number of bytes and returns a new child context bound
## to those bytes.
func child_context(size: int) -> DeserializationContext:
	if size < 0:
		push_error('Desired window size (%d) cannot be negative; adjusted to 0' % \
				size)
		size = 0
	
	if !has_remaining_bytes(size):
		var remaining_bytes = get_remaining_bytes()
		push_error('Desired window size of %d is greater than the number of remaining bytes; the window size has been truncated to %d' % \
				[size, remaining_bytes])
		size = remaining_bytes
	
	var window = DeserializationContext.from_parent(self, size)
	_current_position += size
	return window


## Returns the next 32-bit litte-endian encoded unsigned integer from the
## context and advances the cursor.
func next_u32le() -> int:
	assert(has_remaining_bytes(4), 'Insufficient bytes remaining to decode a u32le; %d remaining' % \
			get_remaining_bytes())
	
	var value = _buffer.decode_u32(_current_position)
	_current_position += 4
	return value


## Returns the next 16-bit litte-endian encoded unsigned integer from the
## context and advances the cursor.
func next_u16le() -> int:
	assert(has_remaining_bytes(2), 'Insufficient bytes remaining to decode a u16le; %d remaining' % \
			get_remaining_bytes())
	
	var value = _buffer.decode_u16(_current_position)
	_current_position += 2
	return value


## Returns the next 8-bit litte-endian encoded unsigned integer from the context
## and advances the cursor.
func next_u8le() -> int:
	assert(has_remaining_bytes(1), 'Insufficient bytes remaining to decode a u8le; %d remaining' % \
			get_remaining_bytes())
	
	var value = _buffer.decode_u8(_current_position)
	_current_position += 1
	return value


## Returns the next 16-bit litte-endian encoded signed integer from the context
## and advances the cursor.
func next_s16le() -> int:
	assert(has_remaining_bytes(2), 'Insufficient bytes remaining to decode a s16le; %d remaining' % \
			get_remaining_bytes())
	
	var value = _buffer.decode_s16(_current_position)
	_current_position += 2
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


## Returns the next null-terminated ASCII string and advances the cursor.
## 
## The terminator is read but not included in the returned string.
func next_c_string() -> String:
	var terminator_position = _buffer.find(0, _current_position)
	var string_bytes: PackedByteArray
	if terminator_position > 0:
		# Read the string
		var to_read = terminator_position - _current_position
		string_bytes = next_bytes(to_read)
		
		# Read the terminator
		next_u8le()
	else:
		var remaining_bytes = get_remaining_bytes()
		push_error('No null terminator was present; all remaining bytes (%d) will be read' % remaining_bytes)
		string_bytes = next_bytes(remaining_bytes)
	
	return string_bytes.get_string_from_ascii()


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
	_log_message(ContextMessage.Level.WARNING, message)


## Logs an error to the context.
func log_error(message: String):
	_log_message(ContextMessage.Level.ERROR, message)


## Returns all context messages logged.
## 
## Note that this includes any messages logged to the parent context as well.
func get_messages() -> Array[ContextMessage]:
	# Duplicate to prevent external modification
	return _messages.duplicate()


## Logs a message to the context.
func _log_message(level: ContextMessage.Level, message: String):
	_messages.append(ContextMessage.new(level, message))


## Represents a message recorded during the processing of a
## DeserializationContext.
class ContextMessage:
	## Represents the level of a ContextMessage.
	enum Level {
		## The event is non-critical but may result in a unexpected behavior.
		WARNING,
		
		## The event indicates an error likely to cause an issue has ocurred.
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
