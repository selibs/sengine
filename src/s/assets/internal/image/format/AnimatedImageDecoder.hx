package s.assets.internal.image.format;

import s.assets.internal.image.AnimatedImage;

abstract class AnimatedImageDecoder extends ImageDecoder<AnimatedImage> {
	var frameWidth = 0;
	var frameHeight = 0;
	var durations:Array<Float> = [];
	var atlasColumns = 0;
	var atlasRows = 0;

	override function finish():Void @:privateAccess {
		super.finish();

		asset.frameWidth = frameWidth;
		asset.frameHeight = frameHeight;
		asset.atlasColumns = atlasColumns > 0 ? atlasColumns : durations.length > 0 ? durations.length : 1;
		asset.atlasRows = atlasRows > 0 ? atlasRows : 1;
		asset.frames.resize(0);
		asset.duration = 0;
		
		for (i in 0...durations.length) {
			final col = i % asset.atlasColumns;
			final row = Std.int(i / asset.atlasColumns);
			final x = frameWidth * col;
			final y = frameHeight * row;
			var duration = durations[i];
			asset.frames.push({
				x: x,
				y: y,
				u: x / width,
				v: y / height,
				uw: frameWidth / width,
				vh: frameHeight / height,
				duration: duration,
				time: asset.duration
			});
			asset.duration += duration;
		}

		asset.currentIndex = asset.currentIndex;
	}
}
