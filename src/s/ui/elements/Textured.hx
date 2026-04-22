package s.ui.elements;

import s.math.Vec4;
import s.geometry.Rect;
import s.graphics.RenderTarget;
import s.graphics.TextureSampling;
import s.graphics.TextureParameters;
import s.assets.internal.image.Image;

@:allow(s.ui.graphics.ImageElementDrawer)
abstract class Textured<T:Image = Image> extends Drawable {
	@:attr var texture:T;
	@:attr var rect:Vec4 = new Vec4(0.0, 0.0, 1.0, 1.0);
	@:attr var clipRect:Vec4 = new Vec4(0.0, 0.0, 1.0, 1.0);
	final parameters:TextureParameters = {
		uAddressing: Clamp,
		vAddressing: Clamp,
		minificationFilter: LinearFilter,
		magnificationFilter: LinearFilter,
		mipmapFilter: NoMipFilter
	}

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
	 * Convenience preset that configures [`smooth`](s.ui.elements.ImageElement.smooth)
	 * and [`mipmap`](s.ui.elements.ImageElement.mipmap) together.
	 *
	 * Use this when you want a named sampling mode instead of managing the two
	 * low-level flags separately.
	 *
	 * @default `Bilinear`
	 */
	public var sampling(get, set):TextureSampling;

	/**
	 * Defines how the image is fitted, cropped, or tiled inside the element.
	 *
	 * The chosen mode affects the derived destination rectangle
	 * ([`rect`](s.ui.elements.ImageElement.rect)), the derived texture
	 * rectangle ([`clipRect`](s.ui.elements.ImageElement.clipRect)), and the
	 * sampler addressing mode used at draw time.
	 *
	 * @default `Stretch`
	 */
	@:attr public var fillMode:FillMode = Stretch;

	/**
	 * Optional texture-space clipping rectangle in image pixels.
	 *
	 * When `null`, the full texture image is used. When non-null, the element
	 * first restricts sampling to this rectangle and only then applies the
	 * current fill-mode logic.
	 *
	 * Coordinates are expressed in texture image pixels:
	 *
	 * - `x`, `y`: top-left corner within the image
	 * - `width`, `height`: size of the texture region
	 *
	 * This is primarily useful for atlas-backed UI icons, spritesheet frames, or
	 * reusable image slices.
	 *
	 * @default `null`
	 */
	@:attr public var sourceClipRect:Rect;

	/**
	 * Alignment policy used together with
	 * [`fillMode`](s.ui.elements.ImageElement.fillMode).
	 *
	 * Horizontal flags (`AlignLeft`, `AlignHCenter`, `AlignRight`) and vertical
	 * flags (`AlignTop`, `AlignVCenter`, `AlignBottom`) are interpreted according
	 * to the active fill mode:
	 *
	 * - `Pad` and `Contain`: place the rendered image inside the leftover space
	 * - `Cover`: choose the visible side of the cropped texture
	 * - `Tile*`: offset the repeated texture pattern phase
	 *
	 * `Stretch` ignores alignment because the image always covers the whole
	 * destination area.
	 *
	 * @default `AlignCenter`
	 */
	@:attr public var alignment:Alignment = AlignCenter;

	/**
	 * Whether the image referenced by
	 * [`texture`](s.ui.elements.ImageElement.texture) has been loaded.
	 *
	 * When this is `false`, the element has no texture to draw and therefore
	 * contributes no pixels.
	 */
	@:readonly @:alias extern public var isLoaded:Bool = texture?.isLoaded;

	override function update() {
		super.update();

		if (!isLoaded)
			return;

		if (textureDirty || mipmapDirty)
			mipmap ? texture.generateMipmaps(1) : texture.setMipmaps([]);

		final hBoundsDirty = left.positionDirty || right.positionDirty;
		final vBoundsDirty = top.positionDirty || bottom.positionDirty;

		if (!(textureDirty || fillModeDirty || sourceClipRectDirty || alignmentDirty || hBoundsDirty || vBoundsDirty))
			return;

		final imageWidth = texture.width;
		final imageHeight = texture.height;
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

		rect = new Rect(left.position, top.position, width, height);
		clipRect = new Rect(baseClipX, baseClipY, baseClipW, baseClipH);

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
				rect.z = sourceWidth;
				rect.w = sourceHeight;
				rect.x = left.position + (width - rect.z) * alignX;
				rect.y = top.position + (height - rect.w) * alignY;
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
					rect.z = height * sourceAspect;
					rect.x = left.position + (width - rect.z) * alignX;
				} else if (targetAspect < sourceAspect) {
					rect.w = width / sourceAspect;
					rect.y = top.position + (height - rect.w) * alignY;
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

	function draw(target:RenderTarget) {
		if (!isLoaded)
			return;
		s.ui.graphics.TexturedDrawer.shader.render(target, cast this);
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

	inline function get_sampling():TextureSampling
		return mipmap ? (smooth ? Trilinear : Prefiltered) : (smooth ? Bilinear : Nearest);

	inline function set_sampling(value:TextureSampling):TextureSampling {
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
