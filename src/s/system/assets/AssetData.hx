package s.system.assets;

import s.system.resource.Resource;

abstract class AssetData<T:kha.Resource> implements s.shortcut.Shortcut {
	public var asset(default, null):T = null;
	public var source(default, set):String = "";

	public var isLoaded(get, never):Bool;

	@:signal public function assetLoaded(asset:T):Void;

	public inline function new(?source:String) {
		this.source = source;
	}

	abstract function _get(?done:T->Void, ?failed:ResourceError->Void):Void;

	abstract function _reload(?done:T->Void, ?failed:ResourceError->Void):Void;

	public inline function delay(f:T->Void, waitForLoaded:Bool = true) {
		if (isLoaded)
			f(asset);
		else if (waitForLoaded)
			// TODO: once signals
			assetLoaded.connect(f);
	}

	public inline function reload(?done:T->Void, ?failed:ResourceError->Void) {
		_reload(a -> {
			this.asset = a;
			this.assetLoaded(asset);
		});
	}

	inline function set_source(value:String):String {
		value = value ?? "";
		if (value != source) {
			source = value;
			if (source != "")
				_get(a -> {
					asset = a;
					assetLoaded(this.asset);
				});
			else
				asset = null;
		}
		return source;
	}

	inline function get_isLoaded():Bool {
		return this.asset != null;
	}
}
