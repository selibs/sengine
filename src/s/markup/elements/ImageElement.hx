package s.markup.elements;

import kha.graphics4.TextureAddressing;
import kha.graphics4.MipMapFilter;
import kha.graphics4.TextureFilter;
import s.math.Vec4;
import s.assets.ImageAsset;
import s.resource.Image;
import s.markup.geometry.Rect;

@:allow(s.markup.graphics.ImageElementDrawer)
class ImageElement extends DrawableElement {
	var asset:ImageAsset = new ImageAsset();
	@:marker var assetIsDirty:Bool = false;

	var uAddressing:TextureAddressing = Clamp;
	var vAddressing:TextureAddressing = Clamp;
	var rect:Vec4 = new Vec4(0.0, 0.0, 1.0, 1.0);
	var clipRect:Vec4 = new Vec4(0.0, 0.0, 1.0, 1.0);
	@:readonly @:alias var image:Image = asset.asset;

	@:readonly @:alias public var isLoaded:Bool = asset.isLoaded;
	@:alias public var source:String = asset.source;
	@:attr public var sourceClipRect:Rect = null;
	@:attr public var mipmap:Bool = false;
	@:attr public var fillMode:FillMode = Stretch;
	@:attr public var alignment:Alignment = AlignCenter;

	public var mipmapFilter:MipMapFilter = PointMipFilter;
	public var textureFilter:TextureFilter = AnisotropicFilter;

	public function new(source:String) {
		super();
		this.source = source;
		asset.onAssetLoaded(_ -> assetIsDirty = true);
	}

	override function sync() {
		super.sync();

		if (!isLoaded)
			return;

		final assetDirty = assetIsDirty;
		final clipDirty = assetDirty || sourceClipRectIsDirty;
		final fillDirty = clipDirty || fillModeIsDirty || alignmentIsDirty || widthIsDirty || heightIsDirty;

		if (mipmap && (assetDirty || mipmapIsDirty))
			(image : kha.Image).generateMipmaps(1);

		if (!fillDirty) {
			assetIsDirty = false;
			return;
		}

		final imageWidth = image.width;
		final imageHeight = image.height;
		var sourceWidth:Float = imageWidth;
		var sourceHeight:Float = imageHeight;
		var baseClipX = 0.0;
		var baseClipY = 0.0;
		var baseClipW = 1.0;
		var baseClipH = 1.0;

		if (sourceClipRect != null) {
			sourceWidth = sourceClipRect.width;
			sourceHeight = sourceClipRect.height;
			baseClipX = sourceClipRect.x / imageWidth;
			baseClipY = sourceClipRect.y / imageHeight;
			baseClipW = sourceClipRect.width / imageWidth;
			baseClipH = sourceClipRect.height / imageHeight;
		}

		rect.x = 0.0;
		rect.y = 0.0;
		rect.z = 1.0;
		rect.w = 1.0;
		clipRect.x = baseClipX;
		clipRect.y = baseClipY;
		clipRect.z = baseClipW;
		clipRect.w = baseClipH;

		switch fillMode {
			case Tile:
				uAddressing = Repeat;
				vAddressing = Repeat;
			case TileVertically:
				uAddressing = Clamp;
				vAddressing = Repeat;
			case TileHorizontally:
				uAddressing = Repeat;
				vAddressing = Clamp;
			case _:
				uAddressing = Clamp;
				vAddressing = Clamp;
		}

		if (width == 0.0 || height == 0.0 || sourceWidth == 0.0 || sourceHeight == 0.0) {
			assetIsDirty = false;
			return;
		}

		final alignX = (alignment & Alignment.AlignRight) != 0 ? 1.0 : (alignment & Alignment.AlignHCenter) != 0 ? 0.5 : 0.0;
		final alignY = (alignment & Alignment.AlignBottom) != 0 ? 1.0 : (alignment & Alignment.AlignVCenter) != 0 ? 0.5 : 0.0;
		final sourceAspect = sourceWidth / sourceHeight;
		final targetAspect = width / height;

		switch fillMode {
			case Pad:
				rect.z = sourceWidth / width;
				rect.w = sourceHeight / height;
				rect.x = (1.0 - rect.z) * alignX;
				rect.y = (1.0 - rect.w) * alignY;
			case Cover:
				if (targetAspect > sourceAspect) {
					clipRect.w = baseClipH * sourceAspect / targetAspect;
					clipRect.y += (baseClipH - clipRect.w) * alignY;
				} else if (targetAspect < sourceAspect) {
					clipRect.z = baseClipW * targetAspect / sourceAspect;
					clipRect.x += (baseClipW - clipRect.z) * alignX;
				}
			case Contain:
				if (targetAspect > sourceAspect) {
					rect.z = sourceAspect / targetAspect;
					rect.x = (1.0 - rect.z) * alignX;
				} else if (targetAspect < sourceAspect) {
					rect.w = targetAspect / sourceAspect;
					rect.y = (1.0 - rect.w) * alignY;
				}
			case Tile:
				final repeatX = width / sourceWidth;
				final repeatY = height / sourceHeight;
				clipRect.x += baseClipW * (Math.ceil(repeatX) - repeatX) * alignX;
				clipRect.y += baseClipH * (Math.ceil(repeatY) - repeatY) * alignY;
				clipRect.z = baseClipW * repeatX;
				clipRect.w = baseClipH * repeatY;
			case TileVertically:
				final repeatY = height / sourceHeight;
				clipRect.y += baseClipH * (Math.ceil(repeatY) - repeatY) * alignY;
				clipRect.w = baseClipH * repeatY;
			case TileHorizontally:
				final repeatX = width / sourceWidth;
				clipRect.x += baseClipW * (Math.ceil(repeatX) - repeatX) * alignX;
				clipRect.z = baseClipW * repeatX;
			case Stretch:
		}
	}

	function draw(target:Texture) {
		if (!isLoaded)
			return;
		s.markup.graphics.ImageElementDrawer.shader.render(target, this);
	}
}
