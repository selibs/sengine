package s.assets;

import haxe.io.Bytes;

@:allow(s.assets.Assets)
@:allow(s.assets.AssetList)
abstract class Asset implements s.shortcut.Shortcut {
	var bytes:Bytes;

	public var source:String;

	@:signal public function loaded():Void;

	public function new(blob:Bytes, ?source:String) {
		this.source = source;
		load(blob);
	}

	function load(bytes:Bytes) {
		this.bytes = bytes;
		process();
		loaded();
	}

	abstract function process():Void;

	function unload():Void {
		bytes = null;
	}
}
