package s.macro;

#if macro
import haxe.ds.StringMap;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
#end

class AssetsMacro {
	#if macro
	static var assetsFields:Array<Field> = [];
	static var assetTypes:StringMap<{
		type:ComplexType,
		load:String,
		reload:String,
		unload:String
	}> = new StringMap();
	static var assetTypeFields:StringMap<Array<Field>> = new StringMap();

	public static function build():Array<Field> {
		function makeFunction(loadName, args, params, f) {
			var exprs = [];
			exprs.push(macro var total = 0);
			exprs.push(macro var progress = 0.0);

			for (a in assetTypes.keyValueIterator()) {
				var listName = a.key;
				exprs.push(macro total += shelf?.$listName.length);
			}

			for (a in assetTypes.keyValueIterator()) {
				var listName = a.key;
				exprs.push(macro if (shelf.$listName != null) {
					for (location in shelf.$listName) {
						$i{f(a.value)}($a{params});
						if (onProgress != null)
							onProgress(progress += 1 / total);
					}
				});
			}
			assetsFields.push({
				name: loadName,
				access: [APublic, AStatic],
				kind: FFun({
					args: args,
					ret: macro :Void,
					expr: macro $b{exprs}
				}),
				pos: Context.currentPos()
			});
		}

		var shelfArg = {
			name: "shelf",
			type: TAnonymous([
				for (a in assetTypes.keyValueIterator())
					{
						name: a.key,
						kind: FVar(macro :Array<String>),
						meta: [{name: ":optional", pos: Context.currentPos()}],
						pos: Context.currentPos()
					}
			])
		};

		var progressArg = {name: "onProgress", type: macro :Float->Void, opt: true};
		var failedArg = {name: "onFailed", type: macro :s.assets.Assets.AssetError->Void, opt: true};

		makeFunction("loadShelf", [shelfArg, progressArg, failedArg], [macro location, macro onFailed], v -> v.load);
		makeFunction("reloadShelf", [shelfArg, progressArg, failedArg], [macro location, macro onFailed], v -> v.reload);
		makeFunction("unloadShelf", [shelfArg, progressArg], [macro location], v -> v.unload);

		for (field in Context.getBuildFields())
			assetsFields.push(field);

		return assetsFields;
	}

	public static function addAssetType(name:String, type:String, formats:Array<{extension:String, type:String}>) {
		var pos = Context.currentPos();

		name = name.toLowerCase();
		var listName = name + "s";
		var capName = name.charAt(0).toUpperCase() + name.substr(1);

		var loadName = "load" + capName;
		var reloadName = "reload" + capName;
		var unloadName = "unload" + capName;

		// abstract
		var abstractTypePath = {pack: ["s", "assets"], name: capName};
		var abstractType = TPath(abstractTypePath);
		var path = type.split(".");
		var tPath = {
			pack: path.slice(0, path.length - 1),
			name: path[path.length - 1]
		};
		var t = TPath(tPath);

		var path = abstractTypePath.pack.concat([abstractTypePath.name]).join(".");
		assetTypeFields.set(capName, (macro class Fields {
			@:from
			public static inline function fromString(value:String)
				return load(value);

			public static inline function load(name:String, ?location:s.assets.AssetLocation, ?failed:s.assets.Assets.AssetError->Void):$abstractType
				return s.assets.Assets.$loadName(name, location, failed);

			public var location(get, set):s.assets.AssetLocation;

			public inline function reload(?location):Void
				s.assets.Assets.$reloadName(this.location, location);

			public inline function unload():Bool {
				if (location != null)
					return s.assets.Assets.$unloadName(location);
				return false;
			}

			private inline function get_location():s.assets.AssetLocation
				return this.location;

			private inline function set_location(value:s.assets.AssetLocation):s.assets.AssetLocation {
				reload(value);
				return value;
			}
		}).fields);

		Compiler.addGlobalMetadata(path, '@:build(s.macro.AssetsMacro.buildAssetType("$capName"))');
		try {
			Context.getType(path);
		} catch (e)
			Context.onAfterInitMacros(() -> Context.defineType({
				pack: abstractTypePath.pack,
				name: abstractTypePath.name,
				doc: "",
				pos: pos,
				isExtern: true,
				meta: [
					{
						name: ":forward",
						pos: pos
					},
					{
						name: ":forward.new",
						pos: pos
					}
				],
				params: [],
				kind: TDAbstract(t, [AbFrom(t), AbTo(t)], [t], [t]),
				fields: []
			}));

		assetTypes.set(listName, {
			type: abstractType,
			load: loadName,
			reload: reloadName,
			unload: unloadName
		});

		// list
		assetsFields.push({
			name: listName,
			access: [APublic, AStatic],
			kind: FProp("default", "never", macro :s.assets.AssetList<$abstractType>, macro new s.assets.AssetList()),
			pos: Context.currentPos()
		});

		var nameArg = {name: "name", type: macro :String};
		var locationArg = {name: "location", type: macro :s.assets.AssetLocation, opt: true};
		var failedArg = {name: "failed", type: macro :s.assets.Assets.AssetError->Void, opt: true};

		var decode = {
			expr: ESwitch(macro location.extension, [
				for (f in formats) {
					var path = f.type.split(".");
					var typePath = {
						pack: path.slice(0, path.length - 1),
						name: path[path.length - 1]
					}
					{
						values: f.extension.split(",").map(ext -> macro $v{ext}),
						expr: macro new $typePath(asset).decode(bytes)
					}
				}
			], macro throw "Unknown format: " + location.extension),
			pos: pos
		}

		// load
		assetsFields.push({
			name: loadName,
			access: [APublic, AStatic],
			kind: FFun({
				args: [nameArg, locationArg, failedArg],
				ret: abstractType,
				expr: macro {
					var asset = $i{listName}.get(name);
					if (asset == null) {
						asset = new $abstractTypePath(name);
						loadBytes(location, bytes -> {
							$i{listName}.add(name, asset);
							$decode;
							(asset : Asset).location = location;
						}, failed);
					}
					return asset;
				}
			}),
			pos: Context.currentPos()
		});

		// unload
		assetsFields.push({
			name: unloadName,
			access: [APublic, AStatic],
			kind: FFun({
				args: [nameArg],
				ret: macro :Bool,
				expr: macro return $i{listName}.unload(name)
			}),
			pos: Context.currentPos()
		});

		// reload
		assetsFields.push({
			name: reloadName,
			access: [APublic, AStatic],
			kind: FFun({
				args: [nameArg, locationArg, failedArg],
				ret: macro :Void,
				expr: macro {
					var asset = $i{listName}.get(name);
                    location = location ?? asset.location;
					loadBytes(location, bytes -> {
						if (asset == null) {
							asset = new $abstractTypePath(name);
							$i{listName}.add(name, asset);
						}
						$decode;
						(asset : Asset).location = location;
					}, failed);
				}
			}),
			pos: Context.currentPos()
		});
	}

	public static function buildAssetType(name:String) {
		var t = Context.getLocalType();
		if (t == null)
			Context.error("Type expected", Context.currentPos());

		var fields = Context.getBuildFields();
		switch t {
			case TInst(t, _):
				var cls = t.get();
				if (cls.name.substr(0, cls.name.length - 6) == name) {
					var assetFields = assetTypeFields.get(name);
					for (field in assetFields) {
						var exists = false;
						for (f in fields)
							if (f.name == field.name) {
								exists = true;
								break;
							}
						if (!exists) {
							field.pos = cls.pos;
							fields.push(field);
						}
					}
				}
			default:
		}

		return fields;
	}
	#end
}
