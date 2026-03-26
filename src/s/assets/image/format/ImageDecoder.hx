package s.assets.image.format;

import haxe.io.Bytes;
import s.assets.AssetFormat;
import s.assets.image.Image;

abstract class ImageDecoder extends AssetFormat<Image> {
	public var width:Int = 0;
	public var height:Int = 0;
	public var pixels:Bytes = null;

	public inline function finish():Void {
		if (width <= 0 || height <= 0)
			DecodeTools.fail('Invalid image size: ${width}x$height');

		final expectedLength = width * height * 4;
		if (pixels == null || pixels.length < expectedLength)
			DecodeTools.fail("Decoder did not produce RGBA pixels");

		@:privateAccess asset.image = kha.Image.fromBytes(pixels, width, height);
	}

	public function encode():Bytes {
		return null; // TODO
	}
}
