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
					for (source in shelf.$listName) {
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
		var posArg = {name: "pos", type: macro :haxe.PosInfos, opt: true};

		makeFunction("loadShelf", [shelfArg, progressArg, failedArg, posArg], [macro source, macro onFailed, macro pos], v -> v.load);
		makeFunction("reloadShelf", [shelfArg, progressArg, failedArg, posArg], [macro source, macro onFailed, macro pos], v -> v.reload);
		makeFunction("unloadShelf", [shelfArg, progressArg], [macro source], v -> v.unload);

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

			public static inline function load(source:String, ?done:$abstractType->Void, ?failed:s.assets.Assets.AssetError->Void):$abstractType
				return s.assets.Assets.$loadName(source, failed);

			public var source(get, set):String;

			public inline function new(?source:String)
				this = new $tPath(source);

			public inline function reload(?newSource):Void
				s.assets.Assets.$reloadName(source, newSource);

			public inline function unload():Bool {
				if (this.source != null)
					return s.assets.Assets.$unloadName(this.source);
				return false;
			}

			inline function get_source():String
				return this.source;

			inline function set_source(value:String):String {
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
			kind: FProp("default", "never", macro :s.assets.AssetList<$abstractType>),
			pos: Context.currentPos()
		});

		var assetArg = {name: "asset", type: abstractType};
		var sourceArg = {name: "source", type: macro :String};
		var newSourceArg = {name: "newSource", type: macro :String, opt: true};
		var failedArg = {name: "failed", type: macro :s.assets.Assets.AssetError->Void, opt: true};
		var posArg = {name: "pos", type: macro :haxe.PosInfos, opt: true};

		var decode = {
			expr: ESwitch(macro ext, [
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
			], macro throw "Unknown format: " + ext),
			pos: pos
		}

		// load
		assetsFields.push({
			name: loadName,
			access: [APublic, AStatic],
			kind: FFun({
				args: [sourceArg, failedArg, posArg],
				ret: abstractType,
				expr: macro {
					var asset = $i{listName}.get(source);
					if (asset == null) {
						asset = new $abstractTypePath(source);
						loadBytes(source, bytes -> {
							$i{listName}.add(source, asset);
							var ext = haxe.io.Path.extension(source ?? "");
							$decode;
						}, failed, pos);
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
				args: [sourceArg],
				ret: macro :Bool,
				expr: macro return $i{listName}.unload(source)
			}),
			pos: Context.currentPos()
		});

		// reload
		assetsFields.push({
			name: reloadName,
			access: [APublic, AStatic],
			kind: FFun({
				args: [sourceArg, newSourceArg, failedArg, posArg],
				ret: macro :Void,
				expr: macro {
					newSource = newSource ?? source;
					loadBytes(newSource, bytes -> {
						var asset = $i{listName}.extract(source);
						if (asset == null)
							asset = new $abstractTypePath(newSource);
						$i{listName}.add(newSource, asset);
						var ext = haxe.io.Path.extension(source ?? "");
						$decode;
						(asset : Asset).source = newSource ?? source;
					}, failed, pos);
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
