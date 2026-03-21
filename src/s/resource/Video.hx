package s.resource;

import s.resource.Resource;

@:forward()
abstract Video(kha.Video) from kha.Video to kha.Video {
	@:from
	public static inline function get(source:String):Video {
		return Resource.getVideo(source);
	}

	public static inline function load(source:String, done:Video->Void, ?failed:ResourceError->Void):Void {
		Resource.loadVideo(source, done, failed);
	}

	public static inline function reload(source:String, done:Video->Void, ?failed:ResourceError->Void) {
		Resource.reloadVideo(source, done, failed);
	}
}
