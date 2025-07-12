class_name ScriptFile
extends Object
## Represents a .ASM or .DEF script file.

const LIST_MORPHO: String = 'MORPHO'
const LIST_BORDER: String = 'TABLOBORD'
const LIST_MAP_TEXTURE: String = 'MAPLAND'
const LIST_SOUND: String = 'SOUND'
const LIST_SCRIPT: String = 'SCRIPT'
const LIST_STATUS: String = 'STATUS'
const LIST_ANIMATION_SPEED: String = 'SPEEDANIM'
const LIST_MIDI: String = 'ZICMIDI'
const LIST_HNM: String = 'HNM'
const _COMMENT_CHARACTER: String = ';'
const _BEGIN_VARIABLES_SECTION: String = '#VAR'
const _BEGIN_PHRASE_LISTS_SECTION: String = '#PHRASE'
const _BEGIN_LIST_SECTION: String = '#LISTE'
const _BEGIN_STRUCT_SECTION: String = '#STRUC'
const _END_SECTION: String = '#ENDS'
const _LIST_DESERIALIZERS = {
	LIST_MORPHO: Callable(MorphoList, 'deserialize'),
	LIST_MAP_TEXTURE: Callable(MapTextureList, 'deserialize')
}
const _STRUCT_DESERIALIZERS = {
	
}

var _variables: Variables = null
var _phrase_lists: PhraseLists = null
var _lists: Dictionary = {}
var _structs: Dictionary = {}

## Attempts to deserialize a script file from the provided context.
static func deserialize(context: ScriptParseContext) -> ScriptFile:
	var variables = null
	var phrase_lists = null
	var lists = {}
	var structs = {}
	
	while context.has_line():
		var section = _get_next_section(context)
		if section != null:
			var name = section.get_name()
			var lines = section.get_lines()
			match section.get_type():
				Section.Type.VARIABLES:
					variables = Variables.deserialize(lines)
				Section.Type.PHRASE_LISTS:
					phrase_lists = PhraseLists.deserialize(lines)
				Section.Type.LIST:
					if _LIST_DESERIALIZERS.has(name):
						lists[name] = _LIST_DESERIALIZERS[name].call(lines)
				Section.Type.STRUCT:
					if _STRUCT_DESERIALIZERS.has(name):
						structs[name] = _STRUCT_DESERIALIZERS[name].call(lines)
	
	var script = ScriptFile.new()
	script._variables = variables
	script._phrase_lists = phrase_lists
	script._lists = lists
	script._structs = structs
	return script


## Gets the next section from the context, if any.
static func _get_next_section(context: ScriptParseContext) -> Section:
	var type = null
	var name = ''
	var section_lines: Array[String] = []
	var section_started = false
	var section_closed = false
	
	var comment_regex = RegEx.create_from_string(_COMMENT_CHARACTER + '.*$')
	
	while context.has_line():
		var raw_line = context.get_next_line()
		if !raw_line.begins_with(_COMMENT_CHARACTER):
			var line = comment_regex.sub(raw_line, '', true).strip_edges()
			if section_started:
				if line.begins_with(_END_SECTION):
					section_closed = true
					break
				elif !line.is_empty():
					section_lines.append(line)
			elif line.begins_with(_BEGIN_VARIABLES_SECTION):
				type = Section.Type.VARIABLES
				section_started = true
			elif line.begins_with(_BEGIN_PHRASE_LISTS_SECTION):
				type = Section.Type.PHRASE_LISTS
				section_started = true
			elif line.begins_with(_BEGIN_LIST_SECTION):
				type = Section.Type.LIST
				name = line.replace(_BEGIN_LIST_SECTION, '').strip_edges()
				section_started = true
			elif line.begins_with(_BEGIN_STRUCT_SECTION):
				type = Section.Type.STRUCT
				name = line.replace(_BEGIN_STRUCT_SECTION, '').strip_edges()
				section_started = true
	
	if section_closed:
		return Section.new(type, name, section_lines)
	
	return null


## Returns the script's variables or null if none were defined.
func get_variables() -> Variables:
	return _variables


## Returns the script's phrase lists or null if none were defined.
func get_phrase_lists() -> PhraseLists:
	return _phrase_lists


## Returns the list with the given name or null if it doesn't exist.
func get_list(name: String) -> List:
	if _lists.has(name):
		return _lists[name]
	return null


## Returns the struct with the given name or null if it doesn't exist.
func get_struct(name: String) -> Struct:
	if _structs.has(name):
		return _structs[name]
	return null


## Represents the parse context for a script file.
class ScriptParseContext:
	var _lines: PackedStringArray
	var line_index: int
	
	## Creates a new parse context from a file.
	static func from_file(file_path: String) -> ScriptParseContext:
		var lines = PackedStringArray([])
		var file_bytes = FileAccess.get_file_as_bytes(file_path)
		var file_text = file_bytes.get_string_from_ascii()
		
		for line in file_text.split('\n'):
			lines.append(line.strip_edges())
		
		var context = ScriptParseContext.new()
		context._lines = lines
		context.line_index = 0
		
		return context
	
	
	## Returns the next line in the context.
	func get_next_line() -> String:
		if line_index < _lines.size():
			var line = _lines[line_index]
			line_index += 1
			return line
		
		return ''
	
	
	## Returns whether the context has another line.
	func has_line() -> bool:
		return line_index < _lines.size()


## Represents a section of a script file.
class Section:
	var _type: Type
	var _name: String
	var _lines: Array[String]
	
	## Constructs a new section from the provided details.
	func _init(type: Type, name: String, lines: Array[String]):
		_type = type
		_name = name
		_lines = lines
	
	
	## Returns the type of the section.
	func get_type() -> Type:
		return _type
	
	
	## Returns the name of the section.
	func get_name() -> String:
		return _name
	
	
	## Returns a copy of the section lines.
	func get_lines() -> Array[String]:
		return _lines.duplicate()
	
	
	## The allowable section types.
	enum Type {
		VARIABLES,
		PHRASE_LISTS,
		LIST,
		STRUCT
	}


## Represents a script's variables section.
class Variables:
	const _MAP_FILE_KEY: String = 'NOMTOTALMAP'
	const _SKY_IMAGE_KEY: String = 'NOMCIEL'
	
	var _properties: Properties
	
	## Deserializes variables from the given lines.
	static func deserialize(lines: Array[String]) -> Variables:
		var variables = Variables.new()
		variables._properties = Properties.deserialize(lines)
		return variables
	
	
	## Returns the path to the map geometry file.
	func get_map_file_path() -> String:
		return _properties.get_property(_MAP_FILE_KEY).as_string()
	
	
	## Returns the path to the sky image.
	func get_sky_image_path() -> String:
		return _properties.get_property(_SKY_IMAGE_KEY).as_string()
	
	
	# TODO add getters for known variabls
	# TODO COEFRECYCLEARME
	# TODO COEFRECYCLEOUTIL
	# TODO DISTSPEAKINDIVIDU
	# TODO LISTEAPLAT
	# TODO MORPHOPTI
	# TODO NOMBIN
	# TODO NOMCLICTER
	# TODO NOMCOORD
	# TODO NOMDRAWTER
	# TODO NOMHNMLEVEL
	# TODO NOMINTER
	# TODO NOMLANDALT
	# TODO NOMLANDMAP
	# TODO NOMOBJETCLIC
	# TODO NOMOBJETPOINTE
	# TODO NOMPHRASE
	# TODO NOMREFLET
	# TODO NOMSONINTERBUILD
	# TODO NOMSONINTERCLOSE
	# TODO NOMSONINTERERR
	# TODO NOMSONINTEROPEN
	# TODO NOMTERCOUL
	# TODO NOMTRACKINFO
	# TODO NOMTRAJRAWMER
	# TODO NOMTRAJRAWTER
	# TODO NOMTRAJZONMER
	# TODO NOMTRAJZONTER
	# TODO NOMVAGUE
	# TODO PHRASECAPTURE
	# TODO REFLETALT
	# TODO REFLETEAU
	# TODO SELMAP
	# TODO VITESSEJEU


## Represents a script's phrase lists section.
class PhraseLists:
	var _properties: Properties
	
	## Deserializes phrase lists from the given lines.
	static func deserialize(lines: Array[String]) -> PhraseLists:
		var phrase_lists = PhraseLists.new()
		phrase_lists._properties = Properties.deserialize(lines)
		return phrase_lists
	
	
	# TODO add getters for known properties
	# TODO LISTEPHRASEACTION
	# TODO LISTEPHRASEARBREGUS
	# TODO LISTEPHRASEAVENTURE
	# TODO LISTEPHRASEDIPLO
	# TODO LISTEPHRASEERREUR
	# TODO LISTEPHRASEETATCONST
	# TODO LISTEPHRASEEXPLO
	# TODO LISTEPHRASEGRAAL
	# TODO LISTEPHRASEGUS
	# TODO LISTEPHRASEINGE
	# TODO LISTEPHRASEMARCH
	# TODO LISTEPHRASEMILIT
	# TODO LISTEPHRASENOMAVENTURE
	# TODO LISTEPHRASENOMDIPLO
	# TODO LISTEPHRASENOMEXPLO
	# TODO LISTEPHRASENOMINGE
	# TODO LISTEPHRASENOMMARCH
	# TODO LISTEPHRASENOMMILIT
	# TODO LISTEPHRASERIVERTYPE
	# TODO LISTEPHRASETYPEBAT
	# TODO LISTEPHRASETYPEGUS
	pass


## Represents an arbitrary list of values.
class List:
	var _values: Array[Value]
	
	## Constructs a new list from the given values.
	func _init(values: Array[Value]):
		_values = values
	
	
	## Returns a copy of the list values.
	func elements() -> Array[Value]:
		return _values.duplicate()
	
	
	## Returns teh number of elements in the list.
	func size() -> int:
		return _values.size()


## Represents a list of morphs.
class MorphoList extends List:
	## Deserializes a list of morphs.
	static func deserialize(lines: Array[String]) -> MorphoList:
		return MorphoList.new(Value.deserialize_lines(lines))


class BorderList extends List:
	# TODO
	pass


## Represents a list of map textures.
class MapTextureList extends List:
	## Deserializes a list of map textures.
	static func deserialize(lines: Array[String]) -> MapTextureList:
		return MapTextureList.new(Value.deserialize_lines(lines))
	
	
	## Returns the texture pair for the given index.
	func get_texture_pair(index: int) -> MapTexturePair:
		var columns = elements()[index].as_list()
		
		if columns and columns.size() == 4:
			var base_texture = MapTexture.new(columns[0],
					bool(columns[2].to_int()))
			var reflection_texture = MapTexture.new(columns[1],
					bool(columns[3].to_int()))
			return MapTexturePair.new(base_texture, reflection_texture)
		
		return null
	
	
	## Represents the pair of map textures for normal and reflection modes.
	class MapTexturePair:
		var _base_texture: MapTexture
		var _reflection_texture: MapTexture
	
		## Constructs a new map texture.
		func _init(base_texture: MapTexture, reflection_texture: MapTexture):
			_base_texture = base_texture
			_reflection_texture = reflection_texture
		
		
		## Returns the texture used when reflections are disabled.
		func get_base_texture() -> MapTexture:
			return _base_texture
		
		
		## Returns the texture used when reflections are enabled.
		func get_reflection_texture() -> MapTexture:
			return _reflection_texture
	
	
	## Represents a map texture.
	class MapTexture:
		var _image: String
		var _is_water: bool
		
		## Constructs a map texture.
		func _init(image: String, represents_water: bool):
			_image = image
			_is_water = represents_water
		
		
		## Returns the map image.
		func get_image() -> String:
			return _image
		
		
		## Returns whether the texture represents water.
		func is_water() -> bool:
			return _is_water


class SoundList extends List:
	# TODO
	pass


class ScriptList extends List:
	# TODO
	pass


class StatusList extends List:
	# TODO
	pass


class AnimationSpeedList extends List:
	# TODO
	pass


class MidiList extends List:
	# TODO
	pass


class HnmList extends List:
	# TODO
	pass


class Struct:
	var _properties: Properties
	
	static func deserialize(type: String, lines: Array[String]) -> Struct:
		# TODO
		# PERSO
		# TERRITOIRE
		# TYPEAGE
		# TYPEVEHICULE
		# TYPEBATIMENT
		# TYPEINDIVIDU
		# TYPEOUTIL
		# TYPEARME
		# VEGET
		return null
	
	# TODO
	pass


class PersonStruct extends Struct:
	# TODO add getters for known properties
	# TODO AGE
	# TODO DEGAT
	# TODO DISTCIBLE
	# TODO DISTFIRE
	# TODO DISTFOLLOW
	# TODO DISTMINFIRE
	# TODO FREQFIRE
	# TODO FREQFOLLOW
	# TODO LAND
	# TODO LIFE
	# TODO LIFEMAX
	# TODO LISTEANIM
	# TODO LISTESCIENCEPERSO
	# TODO MORPH
	# TODO NBMAXAMI
	# TODO NBMAXCIBLE
	# TODO NBMAXLOCK
	# TODO NBMAXLOCKAMI
	# TODO NOM
	# TODO NOMSONDEAD
	# TODO NOMSONFIRE
	# TODO NOMSONHIT
	# TODO NOMSONNAGE
	# TODO NOMTEXT
	# TODO PHRASEAMIPERSO
	# TODO PHRASEPASSEPERSO
	# TODO PHRASEPRESENTPERSO
	# TODO PROTEC
	# TODO PSYCHO
	# TODO TYPEPERSO
	# TODO VALCAPTURE
	# TODO VITESSE
	pass


class TerritoryStruct extends Struct:
	# TODO add getters for known properties
	# TODO AGE
	# TODO APPARTIENT
	# TODO DISTCAPTURE
	# TODO DISTCIBLE
	# TODO GISEMENT
	# TODO LAND
	# TODO LIFE
	# TODO LIFEMAX
	# TODO NBMAXAMI
	# TODO NBMAXCIBLE
	# TODO NBMAXLOCK
	# TODO NBMAXLOCKAMI
	# TODO NOM
	# TODO NOMSONCUT
	# TODO NOMSONDEAD
	# TODO NOMSONFIRE
	# TODO NOMSONHIT
	# TODO NOMSONMOVE
	# TODO NOMSONNAGE
	# TODO NOMSONWORK
	# TODO NOMTEXT
	# TODO NOMXXX
	# TODO OBJET
	pass


class VegetationStruct extends Struct:
	# TODO add getters for known properties
	# TODO NBTREE
	# TODO NOM
	# TODO NOMXXX
	# TODO ONMAP
	# TODO TYPETREE
	pass


class AgeTypeStruct extends Struct:
	# TODO add getters for known properties
	# TODO LAND
	# TODO LISTEAGE
	# TODO NOM
	# TODO NOMICONEAGE
	# TODO NOMICONEGISE
	# TODO NOMRESBRING
	# TODO NOMRESBRUT
	# TODO NOMSONNEXTTYPEAGE
	# TODO NOMTEXT
	# TODO NOMTEXTRES
	# TODO NOMTEXTRESBRUT
	# TODO NOMXXX
	# TODO NUMSPRITETECHNOAGE
	# TODO PHRASEAGEAVENTUREAGE
	# TODO PHRASEAVENTUREAGE
	# TODO PHRASEBUILDAVENTUREAGE
	# TODO PHRASEDEJAAGEAGE
	# TODO PHRASEINFOAVENTUREAGE
	# TODO PHRASEPASAGEAGE
	# TODO PHRASEPASTERRITOIREAGE
	# TODO PHRASEUSE1AVENTUREAGE
	# TODO PHRASEUSE2AVENTUREAGE
	# TODO PHRASEUSE3AVENTUREAGE
	# TODO PHRASEUSE4AVENTUREAGE
	# TODO PHRASEWAITAVENTUREAGE
	# TODO PHRASEWHATUSEAVENTUREAGE
	# TODO QUESTIONHOWAVENTUREAGE
	pass


class VehicleTypeStruct extends Struct:
	# TODO add getters for known properties
	# TODO AGE
	# TODO ARBRE
	# TODO COST
	# TODO COURBEOVNI
	# TODO DEGAT
	# TODO DISTCIBLE
	# TODO DISTFIRE
	# TODO DISTFOLLOW
	# TODO DISTIN
	# TODO DISTMINFIRE
	# TODO DISTOUT
	# TODO FREQFIRE
	# TODO FREQFOLLOW
	# TODO LAND
	# TODO LIFEMAX
	# TODO NBMAXAMI
	# TODO NBMAXCIBLE
	# TODO NBMAXLOCK
	# TODO NBMAXLOCKAMI
	# TODO NBMAXWORK
	# TODO NOM
	# TODO NOMEXPLOEND
	# TODO NOMEXPLOSTART
	# TODO NOMOVNI
	# TODO NOMSONDEAD
	# TODO NOMSONFIRE
	# TODO NOMSONHIT
	# TODO NOMSONMOVE
	# TODO NOMSONWAIT
	# TODO NOMTEXT
	# TODO NOMXXX
	# TODO PROTEC
	# TODO PSYCHO
	# TODO SPEEDOVNI
	# TODO TABLOBORD
	# TODO VITESSE
	pass


class BuildingTypeStruct extends Struct:
	# TODO add getters for known properties
	# TODO AGE
	# TODO ARBRE
	# TODO COST
	# TODO DEGAT
	# TODO DISTCIBLE
	# TODO DISTFIRE
	# TODO DISTMINFIRE
	# TODO FREQFIRE
	# TODO LAND
	# TODO LIFEMAX
	# TODO LISTEPROD
	# TODO NBMAXAMI
	# TODO NBMAXCIBLE
	# TODO NBMAXLOCK
	# TODO NBMAXLOCKAMI
	# TODO NBMAXRES
	# TODO NBMAXWORK
	# TODO NOM
	# TODO NOMSONDEAD
	# TODO NOMSONHIT
	# TODO NOMSONWORK
	# TODO NOMTEXT
	# TODO NOMXXX
	# TODO PROTEC
	# TODO PSYCHO
	pass


class IndividualTypeStruct extends Struct:
	# TODO add getters for known properties
	# TODO AGE
	# TODO ARBRE
	# TODO COSTPRODEQUIP
	# TODO DEGAT
	# TODO DISTCIBLE
	# TODO DISTFIRE
	# TODO DISTFOLLOW
	# TODO DISTMINFIRE
	# TODO FREQFIRE
	# TODO FREQFOLLOW
	# TODO LAND
	# TODO LIFEMAX
	# TODO LISTEANIM
	# TODO LISTEMORPH
	# TODO NBBRINGRES
	# TODO NBMAXAMI
	# TODO NBMAXCIBLE
	# TODO NBMAXLOCK
	# TODO NBMAXLOCKAMI
	# TODO NBWORKRES
	# TODO NOM
	# TODO NOMSONCUT
	# TODO NOMSONDEAD
	# TODO NOMSONFIRE
	# TODO NOMSONHIT
	# TODO NOMSONNAGE
	# TODO NOMSONWORK
	# TODO NOMTEXT
	# TODO PROTEC
	# TODO PSYCHO
	# TODO VITESSE
	pass


class ToolTypeStruct extends Struct:
	# TODO add getters for known properties
	# TODO AGE
	# TODO MEMBRE
	# TODO NOM
	# TODO NOMXXX
	pass


class WeaponTypeStruct extends Struct:
	# TODO add getters for known properties
	# TODO AGE
	# TODO MEMBRE
	# TODO NOM
	# TODO NOMXXX
	pass


## Represents a collection of script properties.
class Properties:
	var _props: Dictionary
	
	## Deserializes properties from the given lines.
	static func deserialize(lines: Array[String]) -> Properties:
		var properties = Properties.new()
		properties._props = {}
		
		for line in lines:
			var key_value = line.split('=', false, 1)
			if key_value.size() == 2:
				var key = key_value[0].strip_edges()
				var value = key_value[1].strip_edges()
				properties._props[key] = Value.deserialize(value)
			
		return properties
	
	
	## Returns the property with th given name or null if it doesn't exist.
	func get_property(key: String) -> Value:
		if _props.has(key):
			return _props[key]
		return null


## Represents a property or list value.
class Value:
	var _value: String
	
	## Deserialize a value from the given line.
	static func deserialize(line: String) -> Value:
		var val = Value.new()
		val._value = line
		return val
	
	## Deserializes the given lines as values.
	static func deserialize_lines(lines: Array[String]) -> Array[Value]:
		var values: Array[Value] = []
		
		for line in lines:
			values.append(Value.deserialize(line))
		
		return values
	
	## Returns the value as a string.
	func as_string() -> String:
		return _value
	
	
	## Returns the value as an integer or -1 if it could not be parsed.
	func as_int() -> int:
		if _value.is_valid_int():
			return _value.to_int()
		return -1
	
	
	## Returns the value as a list.
	func as_list() -> Array:
		var list = _value.split(',')
		for i in list.size():
			list[i] = list[i].strip_edges()
		
		return list
	
	
	## Returns the value as a dictionary.
	func as_dictionary() -> Dictionary:
		var list = as_list()
		var dictionary = {}
		
		for element in list:
			var key_value = element.split(':', true, 1)
			if key_value.size() == 2:
				var key = key_value[0].strip_edges()
				var value = key_value[1].strip_edges()
				dictionary[key] = value
		
		return dictionary
