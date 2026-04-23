package s.assets.internal.image;

class Image extends Asset<kha.Image> implements s.shortcut.Shortcut {
	var image(default, set):kha.Image;

	@:readonly @:alias public var width:Int = image?.width;
	@:readonly @:alias public var height:Int = image?.height;

	public function generateMipmaps(levels:Int)
		image.generateMipmaps(levels);

	public function setMipmaps(mipmaps:Array<Image>)
		image.setMipmaps(mipmaps.map(m -> m.image));

	function unload() {
		if (!isLoaded)
			return;
		image.unload();
		image = null;
	}

	function fromResource(resource:kha.Image):Void
		image = resource;

	function toResource():kha.Image
		return image;

	inline function set_image(value:kha.Image) {
		image?.unload();
		if ((image = value) != null)
			loaded();
		return image;
	}

	function get_isLoaded():Bool
		return image != null;
}
