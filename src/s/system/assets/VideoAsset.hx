package s.system.assets;

import s.system.resource.Video;
import s.system.resource.Resource;

@:forward()
@:forward.new
extern abstract VideoAsset(VideoAssetData) {
	@:from
	public static inline function get(source:String):VideoAsset {
		return new VideoAsset(source);
	}

	@:to
	public inline function toAsset():Video {
		return this.asset;
	}
}

private class VideoAssetData extends AssetData<Video> {
	function _get(?done:Video->Void, ?failed:ResourceError->Void):Void {
		Resource.getVideo(source, done, failed);
	}

	function _reload(?done:Video->Void, ?failed:ResourceError->Void):Void {
		Resource.reloadVideo(source, done, failed);
	}
}
