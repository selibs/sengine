package s.ui.elements;

import s.graphics.RenderTarget;
import s.assets.internal.image.Image;

/**
 * RenderTarget sampling presets for [`ImageElement`](s.ui.elements.ImageElement).
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

@:allow(s.ui.graphics.ImageElementDrawer)
class Icon<T:Image = Image> extends Drawable {
	final parameters:TextureParameters = {
		uAddressing: Clamp,
		vAddressing: Clamp,
		minificationFilter: LinearFilter,
		magnificationFilter: LinearFilter,
		mipmapFilter: NoMipFilter
	}

	/**
	 * Whether the image referenced by
	 * [`source`](s.ui.elements.ImageElement.source) has been loaded.
	 *
	 * When this is `false`, the element has no texture to draw and therefore
	 * contributes no pixels.
	 */
	@:readonly @:alias public var isLoaded:Bool = source?.isLoaded == true;

	/**
	 * Asset key or path of the image to display.
	 *
	 * Assigning this field forwards the value to the internal
	 * [`ImageAsset`](s.assets.ImageAsset). The exact naming scheme depends on the
	 * project's asset pipeline, but it typically matches the engine's image
	 * identifiers such as `"ui/logo"` or `"atlas/icons"`.
	 */
	@:attr(sourceAsset) public var source(default, set):T;

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
	@:attr(sampling) public var mipmap(get, set):Bool;

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
	public var sampling(get, set):ImageSampling;

	/**
	 * Creates a new image element bound to the given source asset.
	 *
	 * @param source Asset key or path used to resolve the image asset.
	 */
	public function new(?source:T) {
		super();
		this.source = source;
	}

	function loadSource()
		sourceDirty = true;

	override function update() {
		super.update();

		if (isLoaded && (sourceAssetDirty || samplingDirty))
			if (mipmap)
				source.generateMipmaps(1);
			else
				source.setMipmaps([]);
	}

	function draw(target:RenderTarget) {
		if (!isLoaded)
			return;
		s.ui.graphics.ImageElementDrawer.shader.render(target, cast this); // TODO: no singletone shader instances. just classes
	}

	inline function set_source(value:T) {
		source?.offLoaded(loadSource);
		value?.onLoaded(loadSource);
		return source = value;
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
