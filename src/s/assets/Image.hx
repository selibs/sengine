package s.assets;

import s.assets.internal.image.Image as Internal;

@:forward()
@:forward.new
@:build(s.macro.AssetsMacro.buildAssetType("Image"))
abstract Image(Internal) from Internal to Internal {}
