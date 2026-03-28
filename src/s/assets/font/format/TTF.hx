package s.assets.font.format;

import s.Assets;
import haxe.io.Bytes;

class TTF extends AssetFormat<Font> {
	public function decode(bytes:Bytes) {
		@:privateAccess asset.blob = kha.Blob.fromBytes(bytes);
	}

	public function encode():Bytes {
		return null; // TODO
	}
}
