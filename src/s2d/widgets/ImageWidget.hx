package s2d.widgets;

import se.Texture;
import se.assets.ImageAsset;
import se.resource.Image;
import s2d.DrawableElement;
import s2d.geometry.Rect;

class ImageWidget extends DrawableElement {
	var asset:ImageAsset = new ImageAsset();
	@:readonly @:alias var image:Image = asset.asset;

	@:alias public var source:String = asset.source;
	@:readonly @:alias public var isLoaded:Bool = asset.isLoaded;

	public var sourceClip:Rect = new Rect(0.0, 0.0, 0.0, 0.0);
	public var fillMode:ImageFillMode = Stretch;

	public function new(source:String) {
		super();
		this.source = source;
	}

	@:slot(asset.assetLoaded)
	function __syncAsset__(img:Image) {
		sourceClip.x = 0.0;
		sourceClip.y = 0.0;
		sourceClip.width = img.width;
		sourceClip.height = img.height;
	}

	function draw(target:Texture) {
		if (image != null) {
			switch fillMode {
				case Pad:
					target.context2D.drawSubImage(image, absX, absY, sourceClip.x, sourceClip.y, sourceClip.width, sourceClip.height);
				case Stretch:
					target.context2D.drawScaledSubImage(image, sourceClip.x, sourceClip.y, sourceClip.width, sourceClip.height, absX, absY, width, height);
				case Cover:
					var scale = Math.max(width / sourceClip.width, height / sourceClip.height);
					var scaledWidth = sourceClip.width * scale;
					var scaledHeight = sourceClip.height * scale;
					var offsetX = (scaledWidth - width) / 2;
					var offsetY = (scaledHeight - height) / 2;
					target.context2D.drawScaledSubImage(image, sourceClip.x + offsetX / scale, sourceClip.y + offsetY / scale, width / scale, height / scale,
						absX, absY, width, height);
				case Contain:
					var scale = Math.min(width / sourceClip.width, height / sourceClip.height);
					var scaledWidth = sourceClip.width * scale;
					var scaledHeight = sourceClip.height * scale;
					var offsetX = (width - scaledWidth) / 2;
					var offsetY = (height - scaledHeight) / 2;
					target.context2D.drawScaledSubImage(image, sourceClip.x, sourceClip.y, sourceClip.width, sourceClip.height, absX + offsetX,
						absY + offsetY, scaledWidth, scaledHeight);
				default:
					throw new haxe.exceptions.NotImplementedException("This fill mode is not yet implemented");
			}
		}
	}
}

enum ImageFillMode {
	/**
	 * The image is not transformed
	 */
	Pad;

	/**
	 * The image is scaled to fit
	 */
	Stretch;

	/**
	 * The image is scaled uniformly to fill, cropping if necessary
	 */
	Cover;

	/**
	 * The image is scaled uniformly to fit without cropping
	 */
	Contain;

	/**
	 * The image is duplicated horizontally and vertically
	 */
	Tile;

	/**
	 * The image is stretched horizontally and tiled vertically
	 */
	TileVertically;

	/**
	 * The image is stretched vertically and tiled horizontally
	 */
	TileHorizontally;
}
