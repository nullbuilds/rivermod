## Defines the bindings for an injector.
class_name InjectionBinder
extends Object

var _class_provider_mapping: Dictionary[Object, Callable] = {}

## Binds a class type to an instance created by the given provider.
## 
## The first argument to the provider must be a reference to the injector.
## 
## If the injected class has a property named "_injector", the injector will
## inject itself directly into that variable after calling the provider.
func bind(clazz: Object, provider: Callable) -> void:
	assert(clazz, "clazz must not be null")
	assert(provider, "provider must not be null")
	_class_provider_mapping.set(clazz, provider)


## Gets the binding for the given class or null if one does not exist.
func get_binding(clazz: Object) -> Callable:
	return _class_provider_mapping.get(clazz)
