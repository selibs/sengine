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
		function makeFunction(loadName, args, f, iter, call, waitForLoad:Bool) {
			var exprs = [];
			exprs.push(macro var total = 0);
			exprs.push(macro var progress = 0.0);

			for (a in assetTypes.keyValueIterator()) {
				var listName = a.key;
				exprs.push(macro var $listName = shelf.$listName);
				exprs.push(macro if ($i{listName} != null) for (_ in ${iter(listName)})
					total++);
			}

			for (a in assetTypes.keyValueIterator()) {
				var listName = a.key;
				if (waitForLoad)
					exprs.push(macro if ($i{listName} != null) {
						for (name in ${iter(listName)}) {
							var asset = ${call(f(a.value), listName)};
							if (asset.isLoaded) {
								if (onProgress != null)
									onProgress(progress += 1 / total);
							} else
								asset.onLoaded(() -> {
									if (onProgress != null)
										onProgress(progress += 1 / total);
								});
						}
					});
				else
					exprs.push(macro if ($i{listName} != null) {
						for (name in ${iter(listName)}) {
							${call(f(a.value), listName)};
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

		function mapIter(listName)
			return macro $i{listName}.keys();

		function mapCall(f, listName)
			return macro $i{f}(name, $i{listName}.get(name));

		function arrIter(listName)
			return macro $i{listName};

		function arrCall(f, listName)
			return macro $i{f}(name);

		var shelfArg = {
			name: "shelf",
			type: TAnonymous([
				for (a in assetTypes.keyValueIterator())
					{
						name: a.key,
						kind: FVar(macro :StringMap<String>),
						meta: [{name: ":optional", pos: Context.currentPos()}],
						pos: Context.currentPos()
					}
			])
		};
		var shelfArrArg = {
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
		var failedArg = {name: "onFailed", type: macro :s.Assets.AssetError->Void, opt: true};

		makeFunction("loadShelf", [shelfArg, progressArg, failedArg], v -> v.load, mapIter, mapCall, true);
		makeFunction("reloadShelf", [shelfArg, progressArg, failedArg], v -> v.reload, mapIter, mapCall, false);
		makeFunction("unloadShelf", [shelfArrArg, progressArg], v -> v.unload, arrIter, arrCall, false);

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

		var resName = switch capName {
			case "Video", "Image", "Sound", "Font":
				capName;
			default:
				"Blob";
		}
		var resType = TPath({
			pack: ["kha"],
			name: resName
		});

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
			public static inline function get(value:String)
				return load(value);

			@:from
			static inline function fromResource(value:$resType):$abstractType {
				var asset = new $tPath();
				@:privateAccess asset.fromResource(value);
				return asset;
			}

			@:to
			inline function toResource():$resType {
				return @:privateAccess this.toResource();
			}

			public static inline function load(name:String, ?location:s.Assets.AssetLocation, ?failed:s.Assets.AssetError->Void):$abstractType
				return s.Assets.$loadName(name, location, failed);

			public var location(get, set):s.Assets.AssetLocation;

			public inline function reload(?location):Void
				s.Assets.$reloadName(this.location, location);

			public inline function unload():Bool {
				if (location != null)
					return s.Assets.$unloadName(location);
				return false;
			}

			private inline function get_location():s.Assets.AssetLocation
				return this.location;

			private inline function set_location(value:s.Assets.AssetLocation):s.Assets.AssetLocation {
				reload(value);
				return value;
			}
		}).fields);

		Compiler.addGlobalMetadata(path, '@:build(s.macro.AssetsMacro.buildAssetType("$capName"))');
		try {
			Context.getType(path);
		} catch (e) {
			#if (display_details != 1)
			Context.onAfterInitMacros(() -> Context.defineType({
				pack: abstractTypePath.pack,
				name: abstractTypePath.name,
				doc: "",
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
				fields: [],
				pos: pos
			}));
			#end
		}

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
			kind: FProp("default", "never", macro :s.Assets.AssetList<$abstractType>, macro new s.Assets.AssetList()),
			pos: Context.currentPos()
		});

		var nameArg = {name: "name", type: macro :String};
		var locationArg = {name: "location", type: macro :s.Assets.AssetLocation, opt: true};
		var failedArg = {name: "failed", type: macro :s.Assets.AssetError->Void, opt: true};

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
						expr: macro {
							new $typePath(asset).decode(data.bytes);
						}
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
						$i{listName}.add(name, asset);
						location = location ?? (name : s.Assets.AssetLocation);
						${loadBytes(resName, decode)};
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
					if (location == null)
						location = asset != null ? asset.location : (name : s.Assets.AssetLocation);
					${loadBytes(resName, decode)};
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

	static function loadBytes(resName:String, loadBlob:Expr) {
		function load(l)
			return macro data -> try {
				$l;
				(cast asset).location = location;
				asset.loaded();
				logger.debug('Loaded asset "$location"');
			} catch (e)
				reporter({error: e.message});

		resName = "load" + resName;

		return macro {
			var reporter = err -> {
				if (failed != null)
					failed({location: location, message: err.error});
				logger.error('Failed to load asset "$location": ${err.error}');
			}
			logger.info('Loading asset "$location"');
			switch (location : AssetLocationType) {
				case Resource(name):
					kha.Assets.$resName(name, ${load(macro asset.fromResource(data))}, reporter);
				case File(path):
					kha.Assets.loadBlobFromPath(path, ${load(loadBlob)}, reporter);
				case Web(url):
					throw new haxe.exceptions.NotImplementedException("Web assets are not yet implemented");
			}
		}
	}
	#end
}
