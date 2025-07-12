class_name Translator
extends Object

# Arrays of objects cannot be declared as constant since constructors cannot be
# declared as constant in gdscript
static var _words: Array[WordReplacement] = [
	# Ages
	WordReplacement.new('bois', 'wood'),
	WordReplacement.new('boi', 'wood'),
	WordReplacement.new('pier', 'stone'),
	WordReplacement.new('pie', 'stone'),
	WordReplacement.new('bron', 'bronze'),
	WordReplacement.new('fer',  'iron'),
	WordReplacement.new('ferr',  'iron'),
	WordReplacement.new('poud', 'powder'),
	WordReplacement.new('char', 'coal'),
	WordReplacement.new('elec', 'electrical'),
	WordReplacement.new('petr', 'oil'),
	WordReplacement.new('pet', 'oil'),
	WordReplacement.new('uran', 'uranium'),
	WordReplacement.new('cybe', 'cyber'),
	WordReplacement.new('stel', 'stellar'),
	
	# Materials/resources
	WordReplacement.new('brut', 'raw'),
	WordReplacement.new('gise', 'deposit'),
	WordReplacement.new('pois', 'fish'),
	WordReplacement.new('ress', 'resource'),
	
	# Buildings
	WordReplacement.new('graal', 'grailstone'),
	WordReplacement.new('depo', 'store'),
	WordReplacement.new('forge', 'workshop'),
	WordReplacement.new('forg', 'workshop'),
	WordReplacement.new('atel', 'armoury'),
	WordReplacement.new('hang', 'civil port'),
	WordReplacement.new('garde', 'watchtower'),
	WordReplacement.new('gard', 'watchtower'),
	WordReplacement.new('aero', 'airport'),
	WordReplacement.new('ecol', 'labratory'),
	WordReplacement.new('hutp', 'house'),
	WordReplacement.new('vila', 'house'),
	WordReplacement.new('usin', 'civil factory'),
	WordReplacement.new('usim', 'military factory'),
	WordReplacement.new('mura', 'wall'),
	
	# Weapons/tools/equipment
	WordReplacement.new('jave', 'javelin'),
	WordReplacement.new('bouc', 'shield'),
	WordReplacement.new('mass', 'club'),
	WordReplacement.new('armu', 'armor'),
	WordReplacement.new('fusi', 'rifle'),
	
	# Vehicles
	WordReplacement.new('rado', 'raft'),
	WordReplacement.new('avio', 'plane'),
	WordReplacement.new('fort', 'fortress'),
	WordReplacement.new('freg', 'frigate'),
	WordReplacement.new('soni', 'super-sonic aircraft'),
	WordReplacement.new('grav', 'anti-grav vehicle'),
	WordReplacement.new('vais', 'transporter'),
	WordReplacement.new('tank', 'tank'), # duh
	
	# Misc
	WordReplacement.new('boulet', 'ball'),
]

static func translate(text: String) -> String:
	return ' '.join(_translate_words(text)).strip_edges(false, true)

static func _translate_words(text: String) -> Array[String]:
	var words: Array[String] = []
	
	var remaing_text = text.to_lower()
	while !remaing_text.is_empty():
		var word_replaced = false
		for word in _words:
			var to_find = word.to_find()
			var replace_with = word.replace_with()
			if remaing_text.begins_with(to_find):
				words.append(replace_with)
				
				var pos = remaing_text.find(to_find)
				remaing_text = remaing_text.erase(pos, to_find.length())
				
				word_replaced = true
				break
		
		if !word_replaced:
			break
	
	words.append(remaing_text)
	return words


class WordReplacement:
	var _find: String
	var _replace_with: String
	
	func _init(find: String, replacement: String):
		_find = find
		_replace_with = replacement
	
	
	func to_find() -> String:
		return _find
	
	
	func replace_with() -> String:
		return _replace_with
