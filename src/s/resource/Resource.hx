package s.resource;

typedef ResourceError = {
	var source:String;
	var message:String;
}

private typedef KhaFResource<T:kha.Resource> = (source:String, done:T->Void, ?failed:kha.AssetError->Void, ?pos:haxe.PosInfos) -> Void;
private typedef FResource<T:kha.Resource> = (source:String, done:T->Void, ?failed:ResourceError->Void) -> Void;

class Resource {
	public static var blobs(default, never) = new ResourceList<Blob>();
	public static var fonts(default, never) = new ResourceList<Font>();
	public static var images(default, never) = new ResourceList<Image>();
	public static var sounds(default, never) = new ResourceList<Sound>();
	public static var videos(default, never) = new ResourceList<Video>();

	public static function getShelf(list:ResourceShelfSources, done:ResourceShelf->Void, ?onProgress:Float->Void, ?failed:ResourceError->Void):Void {
		inline wrapShelf(list, {
			blobs: getBlob,
			fonts: getFont,
			images: getImage,
			sounds: getSound,
			videos: getVideo
		}, done, onProgress, failed);
	}

	public static function getBlob(source:String, ?done:Blob->Void, ?failed:ResourceError->Void):Null<Blob> {
		return inline wrapGet(loadBlob, source, blobs, done, failed);
	}

	public static function getFont(source:String, ?done:Font->Void, ?failed:ResourceError->Void):Null<Font> {
		return inline wrapGet(loadFont, source, fonts, done, failed);
	}

	public static function getImage(source:String, ?done:Image->Void, ?failed:ResourceError->Void):Null<Image> {
		return inline wrapGet(loadImage, source, images, done, failed);
	}

	public static function getSound(source:String, ?done:Sound->Void, ?failed:ResourceError->Void):Null<Sound> {
		return inline wrapGet(loadSound, source, sounds, done, failed);
	}

	public static function getVideo(source:String, ?done:Video->Void, ?failed:ResourceError->Void):Null<Video> {
		return inline wrapGet(loadVideo, source, videos, done, failed);
	}

	public static function loadShelf(list:ResourceShelfSources, done:ResourceShelf->Void, ?onProgress:Float->Void, ?failed:ResourceError->Void):Void {
		inline wrapShelf(list, {
			blobs: loadBlob,
			fonts: loadFont,
			images: loadImage,
			sounds: loadSound,
			videos: loadVideo
		}, done, onProgress, failed);
	}

	public static function loadBlob(source:String, ?done:Blob->Void, ?failed:ResourceError->Void):Void {
		inline wrapLoad(kha.Assets.loadBlobFromPath, kha.Assets.loadBlob, source, blobs, done, failed);
	}

	public static function loadFont(source:String, ?done:Font->Void, ?failed:ResourceError->Void):Void {
		inline wrapLoad(kha.Assets.loadFontFromPath, kha.Assets.loadFont, source, fonts, done, failed);
	}

	public static function loadImage(source:String, ?done:Image->Void, ?failed:ResourceError->Void):Void {
		inline wrapLoad((s, d, ?f, ?p) -> kha.Assets.loadImageFromPath(s, false, d, f, p), kha.Assets.loadImage, source, images, done, failed);
	}

	public static function loadSound(source:String, ?done:Sound->Void, ?failed:ResourceError->Void):Void {
		inline wrapLoad(kha.Assets.loadSoundFromPath, kha.Assets.loadSound, source, sounds, done, failed);
	}

	public static function loadVideo(source:String, ?done:Video->Void, ?failed:ResourceError->Void):Void {
		inline wrapLoad(kha.Assets.loadVideoFromPath, kha.Assets.loadVideo, source, videos, done, failed);
	}

	public static function unloadBlob(source:String):Bool {
		return blobs.unload(source);
	}

	public static function unloadFont(source:String):Bool {
		return fonts.unload(source);
	}

	public static function unloadImage(source:String):Bool {
		return images.unload(source);
	}

	public static function unloadSound(source:String):Bool {
		return sounds.unload(source);
	}

	public static function unloadVideo(source:String):Bool {
		return videos.unload(source);
	}

	public static function reloadShelf(list:ResourceShelfSources, ?done:ResourceShelf->Void, ?onProgress:Float->Void, ?failed:ResourceError->Void):Void {
		inline wrapShelf(list, {
			blobs: reloadBlob,
			fonts: reloadFont,
			images: reloadImage,
			sounds: reloadSound,
			videos: reloadVideo
		}, done, onProgress, failed);
	}

	public static function reloadBlob(source:String, ?done:Blob->Void, ?failed:ResourceError->Void):Bool {
		if (unloadBlob(source)) {
			loadBlob(source, done, failed);
			return true;
		}
		return false;
	}

	public static function reloadFont(source:String, ?done:Font->Void, ?failed:ResourceError->Void):Bool {
		if (unloadFont(source)) {
			loadFont(source, done, failed);
			return true;
		}
		return false;
	}

	public static function reloadImage(source:String, ?done:Image->Void, ?failed:ResourceError->Void):Bool {
		if (unloadImage(source)) {
			loadImage(source, done, failed);
			return true;
		}
		return false;
	}

	public static function reloadSound(source:String, ?done:Sound->Void, ?failed:ResourceError->Void):Bool {
		if (unloadSound(source)) {
			loadSound(source, done, failed);
			return true;
		}
		return false;
	}

	public static function reloadVideo(source:String, ?done:Video->Void, ?failed:ResourceError->Void):Bool {
		if (unloadVideo(source)) {
			loadVideo(source, done, failed);
			return true;
		}
		return false;
	}

	static function wrapGet<T:kha.Resource>(l:FResource<T>, source:String, list:ResourceList<T>, ?done:T->Void, ?failed:ResourceError->Void):Null<T> {
		if (list.has(source)) {
			final a = list[source];
			if (done != null)
				done(a);
			return a;
		}
		l(source, done ?? _ -> {}, failed);
		return null;
	}

	static function wrapLoad<T:kha.Resource>(p:KhaFResource<T>, n:KhaFResource<T>, source:String, list:ResourceList<T>, ?done:T->Void,
			?failed:ResourceError->Void) {
		final isPath = source.indexOf("/") + source.indexOf("\\") + source.indexOf(".") > -3;
		(isPath ? p : n)(source, asset -> {
			list.add(source, asset);
			if (done != null)
				done(asset);
		}, err -> {
			if (failed != null)
				failed({
					source: source,
					message: Std.string(err.error)
				});
			else
				Log.error('Failed to load asset $source');
		});
	}

	static function wrapShelf(list:ResourceShelfSources, f:ResourceShelfWrapper, ?done:ResourceShelf->Void, ?onProgress:Float->Void,
			?failed:ResourceError->Void):Void {
		list = {
			blobs: list.blobs ?? [],
			fonts: list.fonts ?? [],
			images: list.images ?? [],
			sounds: list.sounds ?? [],
			videos: list.videos ?? []
		}

		final total = list.blobs.length + list.fonts.length + list.images.length + list.sounds.length + list.videos.length;
		final shelf = new ResourceShelf();
		var progress = 0;

		function adjust() {
			final p = ++progress / total;
			if (onProgress != null)
				onProgress(p);
			if (progress == total && done != null)
				done(shelf);
		}

		function loadList<T:kha.Resource>(src:Array<String>, tgt:ResourceList<T>, f:FResource<T>) {
			for (source in src)
				f(source, asset -> {
					tgt.add(source, asset);
					adjust();
				}, err -> {
					if (failed != null)
						failed(err);
					else
						Log.error('Failed to load asset "$source": $err');
					adjust();
				});
		}

		loadList(list.blobs, shelf.blobs, f.blobs);
		loadList(list.fonts, shelf.fonts, f.fonts);
		loadList(list.images, shelf.images, f.images);
		loadList(list.sounds, shelf.sounds, f.sounds);
		loadList(list.videos, shelf.videos, f.videos);
	}
}

@:forward()
extern abstract ResourceShelf(ResourceShelfData) from ResourceShelfData to ResourceShelfData {
	@:from
	public static inline function get(sources:ResourceShelfSources):ResourceShelf {
		var shelf = new ResourceShelf();
		Resource.getShelf(sources, s -> {
			shelf.blobs = s.blobs;
			shelf.fonts = s.fonts;
			shelf.images = s.images;
			shelf.sounds = s.sounds;
			shelf.videos = s.videos;
		});
		return shelf;
	}

	public inline function new(?blobs:ResourceList<Blob>, ?fonts:ResourceList<Font>, ?images:ResourceList<Image>, ?sounds:ResourceList<Sound>,
			?videos:ResourceList<Video>) {
		this = {
			blobs: blobs ?? new ResourceList(),
			fonts: fonts ?? new ResourceList(),
			images: images ?? new ResourceList(),
			sounds: sounds ?? new ResourceList(),
			videos: videos ?? new ResourceList()
		}
	}

	public inline function load(list:ResourceShelfSources) {
		Resource.loadShelf({
			blobs: list.blobs,
			fonts: list.fonts,
			images: list.images,
			sounds: list.sounds,
			videos: list.videos
		}, s -> {
			this.blobs = s.blobs;
			this.fonts = s.fonts;
			this.images = s.images;
			this.sounds = s.sounds;
			this.videos = s.videos;
		});
	}

	public inline function reload() {
		Resource.reloadShelf({
			blobs: this.blobs.sources,
			fonts: this.fonts.sources,
			images: this.images.sources,
			sounds: this.sounds.sources,
			videos: this.videos.sources
		}, s -> {
			this.blobs = s.blobs;
			this.fonts = s.fonts;
			this.images = s.images;
			this.sounds = s.sounds;
			this.videos = s.videos;
		});
	}
}

@:forward.new
extern abstract ResourceList<T:kha.Resource>(Map<String, T>) {
	public var sources(get, never):Array<String>;

	public inline function has(key:String):Bool {
		return this.exists(key);
	}

	@:op(a.b) @:op([])
	public inline function get(key:String):T {
		return this.get(key);
	}

	@:op(a.b) @:op([])
	public inline function add(key:String, value:T):Void {
		if (value != null)
			this.set(key, value);
		else
			unload(key);
	}

	public inline function unload(key:String):Bool {
		if (has(key)) {
			get(key).unload();
			this.remove(key);
			return true;
		}
		return false;
	}

	private inline function get_sources():Array<String> {
		return [
			for (source in this.keys())
				source
		];
	}
}

typedef ResourceShelfSources = {
	var ?blobs:Array<String>;
	var ?fonts:Array<String>;
	var ?images:Array<String>;
	var ?sounds:Array<String>;
	var ?videos:Array<String>;
}

private typedef ResourceShelfData = {
	var blobs:ResourceList<Blob>;
	var fonts:ResourceList<Font>;
	var images:ResourceList<Image>;
	var sounds:ResourceList<Sound>;
	var videos:ResourceList<Video>;
}

private typedef ResourceShelfWrapper = {
	var blobs:FResource<Blob>;
	var fonts:FResource<Font>;
	var images:FResource<Image>;
	var sounds:FResource<Sound>;
	var videos:FResource<Video>;
}
