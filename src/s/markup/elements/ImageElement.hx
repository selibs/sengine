package s.markup.elements;

import s.Texture.TextureParameters;
import kha.graphics4.TextureAddressing;
import kha.graphics4.MipMapFilter;
import kha.graphics4.TextureFilter;
import s.math.Vec4;
import s.assets.ImageAsset;
import s.resource.Image;
import s.markup.geometry.Rect;

/**
 * Texture sampling presets for [`ImageElement`](s.markup.elements.ImageElement).
 *
 * These presets combine nearest/linear sampling with optional mipmapping.
 */
enum ImageSampling {
	/** Nearest-neighbor sampling without mipmaps. */
	Nearest;

	/** Linear sampling without mipmaps. */
	Bilinear;

	/** Nearest-neighbor sampling with mipmaps enabled. */
	Prefiltered;

	/** Linear sampling with linear mip blending. */
	Trilinear;
}

/**
 * Image-based drawable markup element.
 *
 * `ImageElement` renders a [`s.resource.Image`](s.resource.Image) inside the
 * rectangular bounds inherited from [`Element`](s.markup.Element). The image is
 * loaded through an internal [`ImageAsset`](s.assets.ImageAsset), can be
 * restricted to a source sub-rectangle with
 * [`sourceClipRect`](s.markup.elements.ImageElement.sourceClipRect), fitted by
 * [`fillMode`](s.markup.elements.ImageElement.fillMode), aligned by
 * [`alignment`](s.markup.elements.ImageElement.alignment), and sampled with
 * configurable texture sampling through
 * [`smooth`](s.markup.elements.ImageElement.smooth),
 * [`mipmap`](s.markup.elements.ImageElement.mipmap), or the higher-level
 * [`sampling`](s.markup.elements.ImageElement.sampling) preset.
 *
 * Fill-mode behavior overview:
 *
 * - [`Pad`](s.markup.FillMode.Pad)
 *   Keeps the source at its natural size relative to the element. This may
 *   leave empty space around the image or cause the image to extend beyond the
 *   element if the source is larger than the destination.
 * - [`Stretch`](s.markup.FillMode.Stretch)
 *   Scales the sampled source rectangle to exactly match the element bounds.
 * - [`Cover`](s.markup.FillMode.Cover)
 *   Scales uniformly to fill the element bounds, cropping the source rectangle
 *   when aspect ratios differ.
 * - [`Contain`](s.markup.FillMode.Contain)
 *   Scales uniformly to fit inside the element bounds without cropping,
 *   potentially leaving empty space.
 * - [`Tile`](s.markup.FillMode.Tile)
 *   Repeats the source horizontally and vertically.
 * - [`TileVertically`](s.markup.FillMode.TileVertically)
 *   Stretches horizontally and repeats vertically.
 * - [`TileHorizontally`](s.markup.FillMode.TileHorizontally)
 *   Repeats horizontally and stretches vertically.
 *
 * Alignment behavior overview:
 *
 * - in `Pad` and `Contain`, alignment places the image inside the remaining
 *   free space
 * - in `Cover`, alignment selects which part of the cropped source remains
 *   visible
 * - in tiled modes, alignment offsets the tile phase when the element size is
 *   not an integer multiple of the tile size
 * - in `Stretch`, alignment has no visible effect because the image always
 *   fills the full destination area
 *
 * The final sampled color is multiplied by the color property and by the
 * element opacity during rendering.
 *
 * Typical usage:
 * ```haxe
 * var image = new ImageElement("ui/logo");
 * image.width = 320;
 * image.height = 180;
 * image.fillMode = Contain;
 * image.alignment = AlignCenter;
 * image.sampling = Trilinear;
 * ```
 *
 * Example using a texture atlas region:
 * ```haxe
 * var icon = new ImageElement("atlas/ui");
 * icon.width = 32;
 * icon.height = 32;
 * icon.sourceClipRect = new Rect(64, 0, 32, 32);
 * icon.fillMode = Stretch;
 * ```
 *
 * Loading is asynchronous from the point of view of the element API. Until the
 * asset is available, [`isLoaded`](s.markup.elements.ImageElement.isLoaded) is
 * `false` and the element skips rendering.
 *
 * `ImageElement` otherwise behaves like any other
 * [`DrawableElement`](s.markup.elements.DrawableElement): it participates in
 * layout, anchoring, z-ordering, color modulation, visibility, opacity, and
 * child rendering.
 *
 * @see s.resource.Image
 * @see s.assets.ImageAsset
 * @see s.markup.FillMode
 * @see s.markup.Alignment
 * @see s.markup.geometry.Rect
 */
@:allow(s.markup.graphics.ImageElementDrawer)
class ImageElement extends DrawableElement {
	var asset:ImageAsset = new ImageAsset();
	@:marker var assetIsDirty:Bool = false;

	@:readonly @:alias var image:Image = asset.asset;

	var parameters:TextureParameters = {
		uAddressing: Clamp,
		vAddressing: Clamp,
		minificationFilter: LinearFilter,
		magnificationFilter: LinearFilter,
		mipmapFilter: NoMipFilter
	}

	var rect:Vec4 = new Vec4(0.0, 0.0, 1.0, 1.0);
	var clipRect:Vec4 = new Vec4(0.0, 0.0, 1.0, 1.0);

	/**
	 * Whether the image referenced by
	 * [`source`](s.markup.elements.ImageElement.source) has been loaded.
	 *
	 * When this is `false`, the element has no texture to draw and therefore
	 * contributes no pixels.
	 */
	@:readonly @:alias public var isLoaded:Bool = asset.isLoaded;

	/**
	 * Resource key or path of the image to display.
	 *
	 * Assigning this field forwards the value to the internal
	 * [`ImageAsset`](s.assets.ImageAsset). The exact naming scheme depends on the
	 * project's resource pipeline, but it typically matches the engine's image
	 * identifiers such as `"ui/logo"` or `"atlas/icons"`.
	 */
	@:alias public var source:String = asset.source;

	/**
	 * Optional source-space clipping rectangle in image pixels.
	 *
	 * When `null`, the full source image is used. When non-null, the element
	 * first restricts sampling to this rectangle and only then applies the
	 * current fill-mode logic.
	 *
	 * Coordinates are expressed in source image pixels:
	 *
	 * - `x`, `y`: top-left corner within the image
	 * - `width`, `height`: size of the source region
	 *
	 * This is primarily useful for atlas-backed UI icons, spritesheet frames, or
	 * reusable image slices.
	 *
	 * @default `null`
	 */
	@:attr public var sourceClipRect:Rect = null;

	/**
	 * Whether the image should use mipmaps when sampled smaller than its native
	 * size.
	 *
	 * When enabled, the element generates a mip chain for the current image and
	 * uses linear mip selection. When disabled, mip levels are removed and only
	 * the base image is sampled.
	 *
	 * @default `false`
	 */
	@:attr public var mipmap(get, set):Bool;

	/**
	 * Whether the image should use linear filtering inside each sampled mip
	 * level.
	 *
	 * When `false`, sampling remains pixel-sharp. When `true`, the image is
	 * filtered smoothly.
	 *
	 * @default `true`
	 */
	public var smooth(get, set):Bool;

	/**
	 * Convenience preset that configures [`smooth`](s.markup.elements.ImageElement.smooth)
	 * and [`mipmap`](s.markup.elements.ImageElement.mipmap) together.
	 *
	 * Use this when you want a named sampling mode instead of managing the two
	 * low-level flags separately.
	 *
	 * @default `Bilinear`
	 */
	public var sampling(get, set):ImageSampling;

	/**
	 * Defines how the image is fitted, cropped, or tiled inside the element.
	 *
	 * The chosen mode affects the derived destination rectangle
	 * ([`rect`](s.markup.elements.ImageElement.rect)), the derived source
	 * rectangle ([`clipRect`](s.markup.elements.ImageElement.clipRect)), and the
	 * sampler addressing mode used at draw time.
	 *
	 * @default `Stretch`
	 */
	@:attr public var fillMode:FillMode = Stretch;

	/**
	 * Alignment policy used together with
	 * [`fillMode`](s.markup.elements.ImageElement.fillMode).
	 *
	 * Horizontal flags (`AlignLeft`, `AlignHCenter`, `AlignRight`) and vertical
	 * flags (`AlignTop`, `AlignVCenter`, `AlignBottom`) are interpreted according
	 * to the active fill mode:
	 *
	 * - `Pad` and `Contain`: place the rendered image inside the leftover space
	 * - `Cover`: choose the visible side of the cropped source
	 * - `Tile*`: offset the repeated texture pattern phase
	 *
	 * `Stretch` ignores alignment because the image always covers the whole
	 * destination area.
	 *
	 * @default `AlignCenter`
	 */
	@:attr public var alignment:Alignment = AlignCenter;

	/**
	 * Creates a new image element bound to the given source asset.
	 *
	 * @param source Resource key or path used to resolve the image asset.
	 */
	public function new(source:String) {
		super();
		this.source = source;
		asset.onAssetLoaded(_ -> assetIsDirty = true);
	}

	override function sync() {
		super.sync();

		if (!isLoaded)
			return;

		if (assetIsDirty || mipmapIsDirty)
			if (mipmap)
				(image : kha.Image).generateMipmaps(1);
			else
				(image : kha.Image).setMipmaps([]);

		if (!(assetIsDirty || sourceClipRectIsDirty || fillModeIsDirty || alignmentIsDirty || widthIsDirty || heightIsDirty))
			return;

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
				parameters.uAddressing = Repeat;
				parameters.vAddressing = Repeat;
			case TileVertically:
				parameters.uAddressing = Clamp;
				parameters.vAddressing = Repeat;
			case TileHorizontally:
				parameters.uAddressing = Repeat;
				parameters.vAddressing = Clamp;
			case _:
				parameters.uAddressing = Clamp;
				parameters.vAddressing = Clamp;
		}

		if (width == 0.0 || height == 0.0 || sourceWidth == 0.0 || sourceHeight == 0.0)
			return;

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

	inline function get_mipmap():Bool
		return parameters.mipmapFilter == LinearMipFilter;

	inline function set_mipmap(value:Bool):Bool {
		parameters.mipmapFilter = value ? LinearMipFilter : NoMipFilter;
		return value;
	}

	inline function get_smooth():Bool
		return parameters.minificationFilter == LinearFilter && parameters.magnificationFilter == LinearFilter;

	inline function set_smooth(value:Bool):Bool {
		if (value) {
			parameters.minificationFilter = LinearFilter;
			parameters.magnificationFilter = LinearFilter;
		} else {
			parameters.minificationFilter = PointFilter;
			parameters.magnificationFilter = PointFilter;
		}
		return value;
	}

	inline function get_sampling():ImageSampling
		return mipmap ? (smooth ? Trilinear : Prefiltered) : (smooth ? Bilinear : Nearest);

	inline function set_sampling(value:ImageSampling):ImageSampling {
		switch value {
			case Nearest:
				mipmap = false;
				smooth = false;
			case Bilinear:
				mipmap = false;
				smooth = true;
			case Prefiltered:
				mipmap = true;
				smooth = false;
			case Trilinear:
				mipmap = true;
				smooth = true;
		}
		return value;
	}
}
