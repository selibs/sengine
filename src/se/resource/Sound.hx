package se.resource;

import se.resource.Resource;

@:forward()
abstract Sound(kha.Sound) from kha.Sound to kha.Sound {
	@:from
	public static inline function get(source:String):Sound {
		return Resource.getSound(source);
	}

	public static inline function load(source:String, done:Sound->Void, ?failed:ResourceError->Void):Void {
		Resource.loadSound(source, done, failed);
	}

	public static inline function reload(source:String, done:Sound->Void, ?failed:ResourceError->Void) {
		Resource.reloadSound(source, done, failed);
	}
}
