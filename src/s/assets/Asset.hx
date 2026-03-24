package s.assets;

import kha.Blob;

@:allow(s.assets.Assets)
@:allow(s.assets.AssetList)
abstract class Asset implements s.shortcut.Shortcut {
	var blob:Blob;

	public var source:String;

	@:signal public function loaded():Void;

	public function new(blob:Blob, ?source:String) {
		this.source = source;
		load(blob);
	}

	function load(blob:Blob) {
		this.blob = blob;
		process();
		loaded();
	}

	abstract function process():Void;

	function unload():Void {
		blob = null;
	}
}
