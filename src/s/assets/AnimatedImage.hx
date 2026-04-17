package s.assets;

import s.assets.internal.image.AnimatedImage as Internal;

@:forward()
@:forward.new
@:build(s.macro.AssetsMacro.buildAssetType("AnimatedImage"))
abstract AnimatedImage(Internal) from Internal to Internal {
	@:to
	inline function toImage():Image
		return this;
}
