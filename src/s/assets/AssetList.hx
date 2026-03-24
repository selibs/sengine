package s.assets;

import haxe.ds.StringMap;

@:forward.new
extern abstract AssetList<T:Asset>(StringMap<T>) {
	public var sources(get, never):Array<String>;

	public inline function has(key:String):Bool
		return this.exists(key);

	@:op(a.b) @:op([])
	public inline function get(key:String):T
		return this.get(key);

	@:op(a.b) @:op([])
	public inline function add(key:String, value:T):Void
		if (value != null)
			this.set(key, value);
		else
			unload(key);

	public inline function unload(key:String):Bool {
		get(key)?.unload();
		return this.remove(key);
	}

	private inline function get_sources():Array<String>
		return [
			for (source in this.keys())
				source
		];
}
