package se.assets;

import se.resource.Sound;
import se.resource.Resource;

@:forward()
@:forward.new
extern abstract SoundAsset(SoundAssetData) {
	@:from
	public static inline function get(source:String):SoundAsset {
		return new SoundAsset(source);
	}

	@:to
	public inline function toAsset():Sound {
		return this.asset;
	}
}

private class SoundAssetData extends AssetData<Sound> {
	function _get(?done:Sound->Void, ?failed:ResourceError->Void):Void {
		Resource.getSound(source, done, failed);
	}

	function _reload(?done:Sound->Void, ?failed:ResourceError->Void):Void {
		Resource.reloadSound(source, done, failed);
	}
}
