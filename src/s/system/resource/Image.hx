package s.system.resource;

import s.system.resource.Resource;

@:forward(width, height, format, unload, at, fromImage, fromCanvas, fromVideo, fromBytes, fromBytes3D, fromEncodedBytes)
extern abstract Image(kha.Image) from kha.Image to kha.Image {
	@:from
	public static inline function get(source:String):Image {
		return Resource.getImage(source);
	}

	public static inline function load(source:String, done:Image->Void, ?failed:ResourceError->Void):Void {
		Resource.loadImage(source, done, failed);
	}

	public static inline function reload(source:String, done:Image->Void, ?failed:ResourceError->Void) {
		Resource.reloadImage(source, done, failed);
	}
}
