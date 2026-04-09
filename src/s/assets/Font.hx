package s.assets;

import s.assets.internal.font.Font as Internal;

@:forward()
@:forward.new
@:build(s.macro.AssetsMacro.buildAssetType("Font"))
abstract Font(Internal) from Internal to Internal {}
