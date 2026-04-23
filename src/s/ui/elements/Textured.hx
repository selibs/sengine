package s.ui.elements;

import s.graphics.RenderTarget;
import s.graphics.TextureSampling;
import s.graphics.TextureParameters;
import s.assets.internal.image.Image;

@:allow(s.ui.graphics.ImageElementDrawer)
abstract class Textured<T:Image = Image> extends Drawable {
	@:attr var texture(default, set):T;
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
	}

	function draw(target:RenderTarget) {
		if (!isLoaded)
			return;
		
		s.ui.graphics.TexturedDrawer.shader.render(target, cast this);
	}

	function loadTexture()
		textureDirty = true;

	function set_texture(value:T) {
		texture?.offLoaded(loadTexture);
		value?.onLoaded(loadTexture);
		return texture = value;
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
