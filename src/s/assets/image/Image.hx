package s.assets.image;

class Image extends Asset implements s.shortcut.Shortcut {
	var image(default, set):kha.Image;

	@:readonly @:alias public var width:Int = image.width;
	@:readonly @:alias public var height:Int = image.height;

	function unload() {
		image?.unload();
		image = null;
	}

	inline function set_image(value:kha.Image) {
		unload();
		return image = value;
	}

	function get_isLoaded():Bool {
		return image != null;
	}
}
