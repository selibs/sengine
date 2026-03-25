package s.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.ds.StringMap;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
#end

class AssetsMacro {
	#if macro
	static var assetFields:Array<Field> = [];
	static var assetTypes:StringMap<{
		type:ComplexType,
		load:String,
		reload:String,
		unload:String
	}> = new StringMap();

	public static function build():Array<Field> {
		function makeFunction(loadName, args, params, f) {
			var exprs = [];
			for (a in assetTypes.keyValueIterator()) {
				var listName = a.key;
				exprs.push(macro if (shelf.$listName != null) for (source in shelf.$listName)
					$i{f(a.value)}($a{params}));
			}
			assetFields.push({
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
		var doneArg = {name: "done", type: macro :s.assets.Asset->Void, opt: true};
		var failedArg = {name: "failed", type: macro :s.assets.Assets.AssetError->Void, opt: true};
		var posArg = {name: "pos", type: macro :haxe.PosInfos, opt: true};

		makeFunction("loadShelf", [shelfArg, doneArg, failedArg, posArg], [macro source, macro done, macro failed, macro pos], v -> v.load);
		makeFunction("reloadShelf", [shelfArg, doneArg, failedArg, posArg], [macro source, macro done, macro failed, macro pos], v -> v.reload);
		makeFunction("unloadShelf", [shelfArg], [macro source], v -> v.unload);

		for (field in Context.getBuildFields())
			assetFields.push(field);

		return assetFields;
	}

	public static function addAssetType(name:String, typeName:String) {
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
		var path = typeName.split(".");
		var t = TPath({
			pack: path.slice(0, path.length - 1),
			name: path[path.length - 1]
		});
		Context.onAfterInitMacros(() -> {
			Context.defineType({
				pack: abstractTypePath.pack,
				name: abstractTypePath.name,
				doc: "",
				pos: pos,
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
				fields: (macro class Fields {
					@:from
					public static function fromString(value:String)
						return load(value);

					public static function load(source:String, ?done:$abstractType->Void, ?failed:s.assets.Assets.AssetError->Void):$abstractType
						return s.assets.Assets.$loadName(source, done, failed);

					public var source(get, set):String;
					public var isLoaded(get, never):Bool;

					public function reload():Void
						if (this.source != null)
							s.assets.Assets.$reloadName(this.source);

					public function unload():Bool {
						if (this.source != null)
							return s.assets.Assets.$unloadName(this.source);
						return false;
					}

					inline function get_source():String {
						return this.source;
					}

					inline function set_source(value:String):String {
						this.source = value;
						reload();
						return value;
					}

					inline function get_isLoaded():Bool {
						return @:privateAccess this.bytes != null;
					}
				}).fields
			});
		});

		assetTypes.set(listName, {
			type: abstractType,
			load: loadName,
			reload: reloadName,
			unload: unloadName
		});

		// list
		assetFields.push({
			name: listName,
			access: [APublic, AStatic],
			kind: FProp("default", "never", macro :s.assets.AssetList<$abstractType>),
			pos: Context.currentPos()
		});

		var sourceArg = {name: "source", type: macro :String};
		var doneArg = {name: "done", type: macro :$abstractType->Void, opt: true};
		var failedArg = {name: "failed", type: macro :s.assets.Assets.AssetError->Void, opt: true};
		var posArg = {name: "pos", type: macro :haxe.PosInfos, opt: true};

		// load
		assetFields.push({
			name: loadName,
			access: [APublic, AStatic],
			kind: FFun({
				args: [sourceArg, doneArg, failedArg, posArg],
				ret: abstractType,
				expr: macro {
					final a = $i{listName}.get(source);
					if (a != null) {
						if (done != null)
							done(a);
						return a;
					}
					loadBytes(source, bytes -> {
						var a = new $abstractTypePath(bytes, source);
						$i{listName}.add(source, a);
						if (done != null)
							done(a);
					}, failed, pos);
					return null;
				}
			}),
			pos: Context.currentPos()
		});

		// unload
		assetFields.push({
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
		assetFields.push({
			name: reloadName,
			access: [APublic, AStatic],
			kind: FFun({
				args: [sourceArg, doneArg, failedArg, posArg],
				ret: macro :Void,
				expr: macro loadBytes(source, bytes -> {
					var a = $i{listName}.get(source);
					if (a != null)
						a.load(bytes);
					else {
						a = new $abstractTypePath(bytes, source);
						$i{listName}.add(source, a);
					}
					if (done != null)
						done(a);
				}, failed, pos)
			}),
			pos: Context.currentPos()
		});
	}
	#end
}
