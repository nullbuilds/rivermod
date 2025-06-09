## A basic singleton dependency inector.
class_name Injector
extends Object

var _class_instance_mapping: Dictionary[Object, Object] = {}
var _binder: InjectionBinder = null

## Creates a new injector from the given context.
static func create(context: InjectionContext) -> Injector:
	var binder: InjectionBinder = InjectionBinder.new()
	
	var start_time_ms: int = Time.get_ticks_msec()
	context.configure_bindings(binder)
	var total_time_ms: int = Time.get_ticks_msec() - start_time_ms
	print("Injector configured in %dms" % [total_time_ms])
	
	return Injector.new(binder)


## Creates a new injector with the given binder.
func _init(binder: InjectionBinder) -> void:
	assert(binder != null, "binder must not be null")
	_binder = binder


## Provides an instance of the given class.
## 
## After the provider is invoked, an Injector will automatically inject an
## instance of itself into any field of the instanciated class typed as an
## Injector.
func provide(clazz: Object) -> Object:
	assert(clazz != null, "clazz must not be null")
	
	if not _class_instance_mapping.has(clazz):
		var instance: Object = _create_instance(clazz)
		_class_instance_mapping.set(clazz, instance)
	
	return _class_instance_mapping.get(clazz)


## Creates a new instance of the provided class and injects itself.
func _create_instance(clazz: Object) -> Object:
	var instance: Object = null
	
	var provider: Callable = _binder.get_binding(clazz)
	assert(provider != null, "Attempted to inject an instance of a class for which no provider exists")
	
	instance = provider.call(self)
	_inject_properties(instance)
	_class_instance_mapping.set(clazz, instance)
	
	return instance


## Injects properties into the given object.
func _inject_properties(instance: Object) -> void:
	var injector_class_name: String = get_script().get_global_name()
	for property in instance.get_property_list():
		if property.class_name == injector_class_name:
			instance.set(property.name, self)
