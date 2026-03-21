package s.assets;

import s.resource.Image;
import s.resource.Resource;

@:forward()
@:forward.new
extern abstract ImageAsset(ImageAssetData) {
	@:from
	public static inline function get(source:String):ImageAsset {
		return new ImageAsset(source);
	}

	@:to
	public inline function toAsset():Image {
		return this.asset;
	}
}

private class ImageAssetData extends AssetData<Image> {
	function _get(?done:Image->Void, ?failed:ResourceError->Void):Void {
		Resource.getImage(source, done, failed);
	}

	function _reload(?done:Image->Void, ?failed:ResourceError->Void):Void {
		Resource.reloadImage(source, done, failed);
	}
}
