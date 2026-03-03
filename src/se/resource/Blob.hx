package se.resource;

import se.resource.Resource;

@:forward()
extern abstract Blob(kha.Blob) from kha.Blob to kha.Blob {
	@:from
	public static inline function get(source:String):Blob {
		return Resource.getBlob(source);
	}

	public static inline function load(source:String, done:Blob->Void, ?failed:ResourceError->Void):Void {
		Resource.loadBlob(source, done, failed);
	}

	public static inline function reload(source:String, done:Blob->Void, ?failed:ResourceError->Void) {
		Resource.reloadBlob(source, done, failed);
	}
}
