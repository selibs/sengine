package s.assets;

import haxe.io.Bytes;

typedef AssetError = {
	var location:AssetLocation;
	var message:String;
}

@:build(s.macro.AssetsMacro.build())
class Assets {
	static final logger = new s.Log.Logger("ASSETS");

	static function loadBytes(location:AssetLocation, done:Bytes->Void, ?failed:AssetError->Void, ?pos:haxe.PosInfos) {
		final reporter = err -> {
			if (failed != null)
				failed({location: location, message: err.error});
			logger.error('Failed to load asset "$location": ${err.error}');
		}
		final loader = blob -> try {
			done(blob.bytes);
			logger.debug('Loaded asset "$location"');
		} catch (e)
			reporter({error: e.message});
		logger.info('Loading asset "$location"');
		switch (location : AssetLocation.AssetLocationType) {
			case Resource(name):
				kha.Assets.loadBlob(name, loader, reporter, pos);
			case File(path):
				kha.Assets.loadBlobFromPath(path, loader, reporter, pos);
			case Web(url):
				throw new haxe.exceptions.NotImplementedException("Web assets are not yet implemented");
		}
	}
}
