package se.assets;

import se.resource.Blob;
import se.resource.Resource;

@:forward()
@:forward.new
extern abstract BlobAsset(BlobAssetData) {
	@:from
	public static inline function get(source:String):BlobAsset {
		return new BlobAsset(source);
	}

	@:to
	public inline function toAsset():Blob {
		return this.asset;
	}
}

private class BlobAssetData extends AssetData<Blob> {
	function _get(?done:Blob->Void, ?failed:ResourceError->Void):Void {
		Resource.getBlob(source, done, failed);
	}

	function _reload(?done:Blob->Void, ?failed:ResourceError->Void):Void {
		Resource.reloadBlob(source, done, failed);
	}
}
