package se.resource;

import se.resource.Resource;

@:forward()
extern abstract Font(kha.Font) from kha.Font to kha.Font {
	@:from
	public static inline function get(source:String):Font {
		return Resource.getFont(source);
	}

	public static inline function load(source:String, done:Font->Void, ?failed:ResourceError->Void):Void {
		Resource.loadFont(source, done, failed);
	}

	public static inline function reload(source:String, done:Font->Void, ?failed:ResourceError->Void) {
		Resource.reloadFont(source, done, failed);
	}
}
