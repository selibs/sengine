package s.assets;

@:forward()
@:forward.new
extern abstract Font(s.assets.font.Font) to s.assets.font.Font {
	@:from
	private static inline function fromKhaFont(value:kha.Font) {
		var font = new Font();
		@:privateAccess font.blob = value.blob;
		return font;
	}

	@:to
	private inline function toKhaFont():kha.Font {
		return @:privateAccess new kha.Font(this.blob);
	}
}
