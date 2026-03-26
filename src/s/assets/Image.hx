package s.assets;

@:forward()
@:forward.new
extern abstract Image(s.assets.image.Image) to s.assets.image.Image {
	private var self(get, set):kha.Image;

	@:to
	private inline function get_self():kha.Image
		return @:privateAccess this.image;

	private inline function set_self(value:kha.Image):kha.Image
		return @:privateAccess this.image = value;

	public inline function generateMipmaps(levels:Int)
		self.generateMipmaps(levels);

	public inline function setMipmaps(mipmaps:Array<Image>)
		self.setMipmaps(mipmaps.map(m -> m.self));
}
