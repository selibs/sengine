package s.assets;

import kha.Blob;

typedef AssetError = {
	var source:String;
	var message:String;
}

@:build(s.macro.AssetsMacro.build())
class Assets {
	static final logger = new s.Log.Logger("ASSETS");

	static function loadBlob(source:String, done:Blob->Void, ?failed:AssetError->Void, ?pos:haxe.PosInfos) {
		final reporter = err -> {
			if (failed != null)
				failed({source: source, message: err.error});
			logger.error('Failed to load asset "$source": ${err.error}');
		}
		final loader = blob -> try {
			done(blob);
			logger.debug('Loaded asset "$source"');
		} catch (e)
			reporter({error: e.message});
		logger.info('Loading asset "$source"');
		if (source.indexOf("/") + source.indexOf("\\") + source.indexOf(".") > -3)
			kha.Assets.loadBlobFromPath(source, loader, reporter, pos);
		else
			kha.Assets.loadBlob(source, loader, reporter, pos);
	}
}
