package s.assets;

@:allow(s.assets.Assets)
@:allow(s.assets.AssetList)
abstract class Asset implements s.shortcut.Shortcut {
	public var source:String;
	public var isLoaded(get, never):Bool;

	@:signal public function loaded():Void;

	public function new(?source:String) {
		this.source = source;
	}

	abstract function unload():Void;

	abstract function get_isLoaded():Bool;
}
