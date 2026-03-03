package se.assets;

import se.resource.Font;
import se.resource.Resource;

@:forward()
@:forward.new
extern abstract FontAsset(FontAssetData) {
	@:from
	public static inline function get(source:String):FontAsset {
		return new FontAsset(source);
	}

	@:to
	public inline function toAsset():Font {
		return this.asset;
	}
}

private class FontAssetData extends AssetData<Font> {
	function _get(?done:Font->Void, ?failed:ResourceError->Void):Void {
		Resource.getFont(source, done, failed);
	}

	function _reload(?done:Font->Void, ?failed:ResourceError->Void):Void {
		Resource.reloadFont(source, done, failed);
	}
}
