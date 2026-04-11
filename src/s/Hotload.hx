package s;

#if HOTLOAD
import haxe.Json;
import haxe.rtti.Meta;
#if kha
import haxe.io.Path;
import haxe.crypto.Base64;
import kha.Image;
import kha.Assets;
#end

typedef Message = {
	type:String,
	?patch:Patch,
	?error:String
}

typedef Patch = {
	type:String,
	// classes
	?klass:Klass,
	// enums
	?enumeration:Enumeration,
	// fields
	?className:String,
	?name:String,
	?nameId:String,
	?value:String,
	?isStatic:Bool,
	?reason:String,
	// constructor
	?classId:String,
	// functions
	?func:Func,
	// assets
	?path:String,
	?data:String
}

typedef Enumeration = {
	name:String,
	nameId:String,
	body:String,
	?constructs:String
}

typedef Func = {
	name:String,
	args:Array<String>,
	body:String,
	?isStatic:Bool
}

typedef Klass = {
	name:String,
	?nameId:String,
	?parent:String,
	?interfaces:String,
	methods:Map<String, Func>,
	staticVars:Map<String, String>
}

class Hotload extends s.net.ws.WebSocketClient {
	static var client:Hotload;

	var queuedPatches:Map<String, Array<Patch>> = [];

	public static function start(?host:String, port = 3220)
		client = new Hotload(host, port);

	function new(?host:String, port = 3220) {
		if (host == null)
			host = js.Browser.location.hostname;
		if (host == "")
			host = "localhost";
		super('ws://$host:$port', "HOTLOAD");
	}

	function applyPatch(patch:Patch):Void {
		if (shouldReloadPatch(patch)) {
			fullReload(getReloadReason(patch));
			return;
		}

		if (shouldSkipPatch(patch)) {
			queueSkippedPatch(patch);
			return;
		}

		switch (patch.type) {
			case "addClass":
				addClass(patch.klass);
			case "staticVar":
				setStaticVar(patch.className, patch.name, patch.value);
				if (patch.name == "__meta__")
					flushQueuedPatches(patch.className);
			case "deleteStaticVar":
				deleteStaticVar(patch.className, patch.name);
				if (patch.name == "__meta__")
					flushQueuedPatches(patch.className);
			case "deleteClass":
				deleteClass(patch.classId, patch.className);
			case "constructor":
				setConstructor(patch.classId, patch.className, patch.func);
			case "func":
				setFunction(patch.className, patch.func);
			case "deleteFunc":
				deleteFunction(patch.className, patch.name, patch.isStatic);
			case "addEnum":
				setEnum(patch.enumeration);
			case "deleteEnum":
				deleteEnum(patch.name, patch.nameId);
			case "reloadAsset":
				#if kha
				reloadAsset(patch.path, patch.data);
				#else
				logger.error("Asset reloader not found");
				#end
			case "fullReload":
				fullReload(patch.reason);
		}
	}

	@:slot(text)
	function processText(text:String) {
		var messages:Array<Message> = Json.parse(text);
		for (m in messages) {
			try {
				switch m.type {
					case "patch":
						{
							applyPatch(m.patch);
						}
					case "error":
						logger.error(m.error);
				}
			} catch (e)
				logger.error('Patch apply failed: $e');
		}
	}
}

function getFuncMap(data:Dynamic):Map<String, Func>
	return [for (field in Reflect.fields(data.h)) field => Reflect.field(data.h, field)];

function getStringMap(data:Dynamic):Map<String, String>
	return [for (field in Reflect.fields(data.h)) field => Reflect.field(data.h, field)];

function getTypeContext(className:String):Dynamic {
	#if js_classic
	final classes:Dynamic = untyped $hxClasses;
	if (untyped classes[className] == null && Reflect.hasField(js.Browser.window, className))
		return js.Browser.window;
	return classes;
	#else
	return untyped $hxClasses;
	#end
}

function getType(className:String):Dynamic
	return untyped getTypeContext(className)[className];

function hasNoHotload(meta:Dynamic):Bool
	return meta != null && Reflect.hasField(meta, "hotload.skip");

function hasHotloadReload(meta:Dynamic):Bool
	return meta != null && Reflect.hasField(meta, "hotload.reload");

function getTypeMeta(className:String):Dynamic {
	final type = getType(className);
	if (type == null)
		return null;
	try {
		return Meta.getType(type);
	} catch (_:Any) {
		return null;
	}
}

function getFieldMeta(className:String, fieldName:String, isStatic = false):Dynamic {
	final type = getType(className);
	if (type == null)
		return null;
	try {
		final meta = isStatic ? Meta.getStatics(type) : Meta.getFields(type);
		return Reflect.field(meta, !isStatic && fieldName == "new" ? "_" : fieldName);
	} catch (_:Any) {
		return null;
	}
}

function isTypeNoHotload(className:String):Bool
	return hasNoHotload(getTypeMeta(className));

function isFieldNoHotload(className:String, fieldName:String, isStatic = false):Bool
	return isTypeNoHotload(className) || hasNoHotload(getFieldMeta(className, fieldName, isStatic));

function isTypeHotReload(className:String):Bool
	return hasHotloadReload(getTypeMeta(className));

function isFieldHotReload(className:String, fieldName:String, isStatic = false):Bool
	return isTypeHotReload(className) || hasHotloadReload(getFieldMeta(className, fieldName, isStatic));

function patchClassNoHotload(klass:Klass):Bool {
	final staticVars = getStringMap(klass.staticVars);
	if (!staticVars.exists("__meta__"))
		return false;
	final meta:Dynamic = evalValue(staticVars["__meta__"]);
	return hasNoHotload(Reflect.field(meta, "obj"));
}

function patchClassHotReload(klass:Klass):Bool {
	final staticVars = getStringMap(klass.staticVars);
	if (!staticVars.exists("__meta__"))
		return false;
	final meta:Dynamic = evalValue(staticVars["__meta__"]);
	return hasHotloadReload(Reflect.field(meta, "obj"));
}

function getPatchClassName(patch:Patch):Null<String> {
	return switch (patch.type) {
		case "addClass":
			patch.klass?.nameId;
		case "staticVar", "deleteStaticVar", "deleteClass", "constructor", "func", "deleteFunc":
			patch.className;
		default:
			null;
	}
}

function isMetaPatch(patch:Patch):Bool
	return (patch.type == "staticVar" || patch.type == "deleteStaticVar") && patch.name == "__meta__";

function getReloadReason(patch:Patch):String {
	return switch (patch.type) {
		case "addClass":
			'Type `${patch.klass?.nameId ?? patch.klass?.name}` is marked with @hotload.reload';
		case "staticVar":
			if (patch.name == "__meta__")
				'Type `${patch.className}` metadata is marked with @hotload.reload';
			else
				'Static field `${patch.className}.${patch.name}` is marked with @hotload.reload';
		case "deleteStaticVar":
			if (patch.name == "__meta__")
				'Type `${patch.className}` metadata is marked with @hotload.reload';
			else
				'Static field `${patch.className}.${patch.name}` is marked with @hotload.reload';
		case "deleteClass":
			'Type `${patch.className}` is marked with @hotload.reload';
		case "constructor":
			'Constructor `${patch.className}.new` is marked with @hotload.reload';
		case "func":
			final name = patch.func?.name;
			final isStatic = !!patch.func?.isStatic;
			isStatic
				? 'Static function `${patch.className}.${name}` is marked with @hotload.reload'
				: 'Function `${patch.className}.${name}` is marked with @hotload.reload';
		case "deleteFunc":
			patch.isStatic
				? 'Static function `${patch.className}.${patch.name}` is marked with @hotload.reload'
				: 'Function `${patch.className}.${patch.name}` is marked with @hotload.reload';
		default:
			"Patched declaration is marked with @hotload.reload";
	}
}

function shouldReloadPatch(patch:Patch):Bool {
	return switch (patch.type) {
		case "addClass":
			patchClassHotReload(patch.klass);
		case "staticVar", "deleteStaticVar":
			if (patch.name == "__meta__") {
				if (patch.type == "staticVar" && patch.value != null) {
					final meta:Dynamic = evalValue(patch.value);
					hasHotloadReload(Reflect.field(meta, "obj"));
				} else
					isTypeHotReload(patch.className);
			} else
				isFieldHotReload(patch.className, patch.name, true);
		case "deleteClass":
			isTypeHotReload(patch.className);
		case "constructor":
			isFieldHotReload(patch.className, "new");
		case "func":
			isFieldHotReload(patch.className, patch.func.name, !!patch.func.isStatic);
		case "deleteFunc":
			isFieldHotReload(patch.className, patch.name, patch.isStatic);
		default:
			false;
	}
}

function shouldSkipPatch(patch:Patch):Bool {
	return switch (patch.type) {
		case "addClass":
			patchClassNoHotload(patch.klass);
		case "staticVar", "deleteStaticVar": patch.name != "__meta__" && isFieldNoHotload(patch.className, patch.name, true);
		case "deleteClass":
			isTypeNoHotload(patch.className);
		case "constructor":
			isFieldNoHotload(patch.className, "new");
		case "func":
			isFieldNoHotload(patch.className, patch.func.name, !!patch.func.isStatic);
		case "deleteFunc":
			isFieldNoHotload(patch.className, patch.name, patch.isStatic);
		default:
			false;
	}
}

@:access(s.Hotload)
function queueSkippedPatch(patch:Patch):Void {
	final className = getPatchClassName(patch);
	if (className == null)
		return;
	var queuedPatch = patch;
	if (patch.type == "addClass" && patch.klass != null) {
		final staticVars = getStringMap(patch.klass.staticVars);
		staticVars.remove("__meta__");
		queuedPatch = {
			type: patch.type,
			klass: {
				name: patch.klass.name,
				nameId: patch.klass.nameId,
				parent: patch.klass.parent,
				interfaces: patch.klass.interfaces,
				methods: patch.klass.methods,
				staticVars: staticVars,
			},
		};
	}
	var patches = Hotload.client.queuedPatches[className];
	if (patches == null)
		patches = [];
	if (patch.type == "addClass" || patch.type == "deleteClass")
		patches = [queuedPatch];
	else
		patches.push(queuedPatch);
	Hotload.client.queuedPatches[className] = patches;
}

@:access(s.Hotload)
function flushQueuedPatches(className:String):Void {
	final queued = Hotload.client.queuedPatches[className];
	if (queued == null || queued.length == 0)
		return;
	Hotload.client.queuedPatches.remove(className);
	for (patch in queued)
		Hotload.client.applyPatch(patch);
}

function hasOwnField(target:Dynamic, field:String):Bool
	return js.Syntax.code("Object.prototype.hasOwnProperty.call({0}, {1})", target, field);

function deleteField(target:Dynamic, field:String):Void
	js.Syntax.code("delete {0}[{1}]", target, field);

function setObjectPrototype(target:Dynamic, proto:Dynamic):Void
	js.Syntax.code("Object.setPrototypeOf({0}, {1})", target, proto);

function isPlainObject(value:Dynamic):Bool
	return js.Syntax.code("{0} != null && typeof {0} === 'object' && !Array.isArray({0})", value);

function evalValue(code:String):Dynamic
	return js.Syntax.code("eval('(' + {0} + ')')", code);

function syncObjectFields(source:Dynamic, target:Dynamic):Void {
	final seen = new Map<String, Bool>();
	for (field in Reflect.fields(source)) {
		seen[field] = true;
		final nextValue = Reflect.field(source, field);
		final currentValue = Reflect.field(target, field);
		if (isPlainObject(nextValue) && isPlainObject(currentValue))
			syncObjectFields(nextValue, currentValue);
		else
			Reflect.setField(target, field, nextValue);
	}
	for (field in Reflect.fields(target))
		if (!seen.exists(field))
			deleteField(target, field);
}

@:access(s.Hotload)
function fullReload(?reason:String):Void {
	if (Hotload.client != null && reason != null && reason != "")
		Hotload.client.logger.warning('Fallback to full reload: $reason');
	final bridge:Dynamic = Reflect.field(js.Browser.window, "electronHotload");
	if (bridge != null) {
		final reloadWindow = Reflect.field(bridge, "reloadWindow");
		if (reloadWindow != null) {
			Reflect.callMethod(bridge, reloadWindow, []);
			return;
		}
	}
	js.Browser.window.location.reload();
}

@:access(s.Hotload)
function addClass(klass:Klass):Void {
	final name = klass.nameId;
	final methods = getFuncMap(klass.methods);
	final staticVars = getStringMap(klass.staticVars);
	final previousType:Dynamic = getType(name);
	final previousStaticFields = previousType != null ? Reflect.fields(previousType) : [];
	final previousPrototype:Dynamic = previousType != null ? untyped previousType.prototype : null;
	final hasMeta = staticVars.exists("__meta__");
	final incomingNoHotload = patchClassNoHotload(klass);

	if (previousType != null) {
		if (hasMeta)
			setStaticVar(name, "__meta__", staticVars["__meta__"]);
		else
			deleteStaticVar(name, "__meta__");
	}
	staticVars.remove("__meta__");

	if (incomingNoHotload || (previousType != null && isTypeNoHotload(name)))
		return;

	addConstructor(klass.name, name, methods["new"]);
	final currentType:Dynamic = getType(name);
	if (currentType == null) {
		Hotload.client.logger.error('Type not found after addClass: $name');
		return;
	}
	if (previousPrototype != null)
		untyped currentType.prototype = previousPrototype;
	else if (untyped currentType.prototype == null)
		untyped currentType.prototype = {};
	final prototype:Dynamic = untyped currentType.prototype;

	if (klass.parent != null) {
		final parentType:Dynamic = untyped $hxClasses[klass.parent];
		if (parentType != null) {
			setObjectPrototype(prototype, untyped parentType.prototype);
			untyped currentType.__super__ = parentType;
		}
	} else
		deleteField(currentType, "__super__");

	for (field in Reflect.fields(prototype)) {
		if (field == "__class__")
			continue;
		final value = Reflect.field(prototype, field);
		if (js.Syntax.code("typeof {0} === 'function'", value) && !methods.exists(field))
			deleteField(prototype, field);
	}

	for (func in methods) {
		if (func.name == "new")
			continue;
		if (isFieldNoHotload(name, func.name, !!func.isStatic))
			continue;
		setFunction(name, func);
	}

	if (klass.interfaces != null)
		untyped currentType.__interfaces__ = evalValue(klass.interfaces);
	else
		deleteField(currentType, "__interfaces__");

	for (field in previousStaticFields) {
		if (field == "prototype" || field == "__name__" || field == "__super__" || field == "__interfaces__" || field == "__meta__")
			continue;
		if (!staticVars.exists(field) && !methods.exists(field))
			deleteField(currentType, field);
	}

	if (hasMeta)
		setStaticVar(name, "__meta__", getStringMap(klass.staticVars)["__meta__"]);

	for (key in staticVars.keys()) {
		if (isFieldNoHotload(name, key, true))
			continue;
		setStaticVar(name, key, staticVars[key]);
	}
	Hotload.client.queuedPatches.remove(name);
}

function addConstructor(classId:String, className:String, func:Func):Void
	untyped window[classId] = $hxClasses[className] = makeFunc(func);

@:access(s.Hotload)
function setConstructor(classId:String, className:String, func:Func):Void {
	#if !js_classic
	logger.error("Constructor patching unsupported without js_classic define");
	untyped if (window[classId] == null)
		window[classId] = {};
	#end
	final obj:Dynamic = {};
	// backup and restore fields and prototype
	copyObjectFields(untyped window[classId], obj);
	final proto = untyped window[classId].prototype;
	addConstructor(classId, className, func);
	if (proto != null)
		untyped window[classId].prototype = proto;
	copyObjectFields(obj, untyped window[classId]);

	// making instance of class to get all field values in constructor
	// and set it to prototype for previous runtime objects
	try {
		// try-catch in case if constructor has args field access
		final instance = js.Syntax.code("new window[{0}];", classId);
		copyObjectFields(instance, untyped window[classId].prototype);
	} catch (ex:Any) {}
}

function copyObjectFields(from:{}, to:{}):Void
	js.Syntax.code("for (var key in {0}) if (Object.prototype.hasOwnProperty.call({0}, key)) {1}[key] = {0}[key]", from, to);

@:access(s.Hotload)
function setFunction(className:String, func:Func):Void {
	final ctx = getTypeContext(className);
	final type = untyped ctx[className];
	if (type == null) {
		Hotload.client.logger.error('Type not found: $className');
		return;
	}
	if (func.isStatic)
		untyped type[func.name] = makeFunc(func);
	else
		untyped type.prototype[func.name] = makeFunc(func);
}

@:access(s.Hotload)
function deleteFunction(className:String, name:String, isStatic = false):Void {
	final type = getType(className);
	if (type == null) {
		Hotload.client.logger.error('Type not found: $className');
		return;
	}
	if (isStatic)
		deleteField(type, name);
	else if (untyped type.prototype != null)
		deleteField(untyped type.prototype, name);
}

@:access(s.Hotload)
function setStaticVar(className:String, name:String, value:String):Void {
	final type = getType(className);
	if (type == null) {
		Hotload.client.logger.error('Type not found: $className');
		return;
	}
	untyped type[name] = evalValue(value);
}

@:access(s.Hotload)
function deleteStaticVar(className:String, name:String):Void {
	final type = getType(className);
	if (type == null) {
		Hotload.client.logger.error('Type not found: $className');
		return;
	}
	deleteField(type, name);
}

@:access(s.Hotload)
function deleteClass(classId:String, className:String):Void {
	deleteField(untyped $hxClasses, className);
	if (classId != null && hasOwnField(js.Browser.window, classId))
		deleteField(js.Browser.window, classId);
	Hotload.client.queuedPatches.remove(className);
}

function makeFunc(func:Func):js.lib.Function {
	#if js_classic
	return js.Syntax.code("new Function(...{0}, {1})", func.args, func.body);
	#end
	var args = "";
	if (func.args.length > 0)
		args += func.args[0];
	for (i in 1...func.args.length)
		args += "," + func.args[i];
	final code = '(function ($args) {${func.body}})';
	return js.Syntax.code("eval({0})", code);
}

function makeObj(code:String):js.lib.Object {
	final code = '({$code})';
	return js.Syntax.code("eval({0})", code);
}

function setEnum(en:Enumeration):Void {
	final next:Dynamic = makeObj(en.body);
	final current:Dynamic = untyped $hxEnums[en.nameId];
	if (current == null) {
		untyped window[en.nameId] = $hxEnums[en.nameId] = next;
		return;
	}
	for (field in Reflect.fields(next)) {
		if (field == "__constructs__")
			continue;
		final nextValue = Reflect.field(next, field);
		final currentValue = Reflect.field(current, field);
		if (isPlainObject(nextValue) && isPlainObject(currentValue))
			syncObjectFields(nextValue, currentValue);
		else
			Reflect.setField(current, field, nextValue);
	}
	for (field in Reflect.fields(current))
		if (field != "__constructs__" && !hasOwnField(next, field))
			deleteField(current, field);
	final nextConstructs:Array<Dynamic> = en.constructs != null ? cast evalValue(en.constructs) : null;
	if (nextConstructs == null)
		Reflect.setField(current, "__constructs__", null);
	else {
		final currentConstructs:Array<Dynamic> = [];
		for (item in nextConstructs) {
			final name:String = Reflect.field(item, "_hx_name");
			final currentItem = name != null ? Reflect.field(current, name) : null;
			currentConstructs.push(currentItem != null ? currentItem : item);
		}
		Reflect.setField(current, "__constructs__", currentConstructs);
	}
	untyped window[en.nameId] = $hxEnums[en.nameId] = current;
}

function deleteEnum(name:String, nameId:String):Void {
	deleteField(untyped $hxEnums, nameId);
	if (name != null && hasOwnField(js.Browser.window, name))
		deleteField(js.Browser.window, name);
}

#if kha
function reloadAsset(path:String, base64:String):Void {
	final ext = Path.extension(path);
	var name = Path.withoutExtension(path);
	name = ~/(-|\/)/g.replace(name, "_");
	final data = Base64.decode(base64);
	switch (ext) {
		case "png", "jpg", "hdr":
			// Assets.loadImageFromPath(path, false, (img) -> {
			Image.fromEncodedBytes(data, ext, (img) -> {
				final current = Assets.images.get(name);
				if (current == null) {
					Assets.loadImage(name, (img) -> {});
					return;
				}
				untyped current.image = img.image;
				untyped current.texture = img.texture;
				untyped current.myWidth = img.myWidth;
				untyped current.myHeight = img.myHeight;
			}, (e) -> Log.error(e));
		case "mp3", "wav", "ogg", "flac":
		case "mp4":
		case "ttf":
		default:
			if (ext.length > 0)
				name += '_$ext';
			final blob = Assets.blobs.get(name);
			if (blob == null) {
				Assets.loadBlob(name, (blob) -> {});
				return;
			}
			@:privateAccess blob.bytes = data;
	}
}
#end
#end
