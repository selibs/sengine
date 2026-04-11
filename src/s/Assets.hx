package s;

@:access(s.assets.internal.Asset)
@:build(s.macro.AssetsMacro.build())
class Assets {
	static final logger = new Log.Logger("ASSETS");
}
