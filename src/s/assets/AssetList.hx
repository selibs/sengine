package s.assets;

import haxe.ds.StringMap;

@:forward.new
abstract AssetList<T:Resource>(StringMap<T>) {
	public function has(key:String):Bool
		return this.exists(key);

	@:op(a.b) @:op([])
	public function get(key:String):T
		return this.get(key);

	@:op(a.b) @:op([])
	public function add(key:String, value:T):Void
		if (value != null)
			this.set(key, value);
		else
			unload(key);

	public function extract(key:String) {
		var asset = get(key);
		this.remove(key);
		return asset;
	}

	public function unload(key:String):Bool {
		get(key)?.unload();
		return this.remove(key);
	}
}
