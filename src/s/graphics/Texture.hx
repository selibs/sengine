package s.graphics;

import s.assets.Image;
import s.graphics.Context1D;
import s.graphics.Context2D;
import s.graphics.Context3D;

typedef MipMapFilter = kha.graphics4.MipMapFilter;
typedef TextureAddressing = kha.graphics4.TextureAddressing;
typedef TextureFilter = kha.graphics4.TextureFilter;
typedef TextureFormat = kha.graphics4.TextureFormat;
typedef DepthStencilFormat = kha.graphics4.DepthStencilFormat;

/**
 * Sampler parameters used when binding a texture.
 *
 * These values describe how texture coordinates outside the `0..1` range are
 * handled and which filters are used when sampling.
 */
typedef TextureParameters = {
	/** Horizontal texture addressing mode. */
	var ?uAddressing:TextureAddressing;

	/** Vertical texture addressing mode. */
	var ?vAddressing:TextureAddressing;

	/** Filter used when the texture is sampled smaller than its native size. */
	var ?minificationFilter:TextureFilter;

	/** Filter used when the texture is sampled larger than its native size. */
	var ?magnificationFilter:TextureFilter;

	/** Filter used when choosing between mip levels. */
	var ?mipmapFilter:MipMapFilter;
}

/**
 * Render-target texture wrapper with access to 1D, 2D, and 3D graphics contexts.
 *
 * `Texture` is a lightweight abstraction over `kha.Image` for render targets.
 * It is commonly used as an intermediate buffer, post-processing target, or
 * off-screen drawing surface.
 *
 * Typical usage:
 * ```haxe
 * var target = new Texture(512, 512);
 * target.context2D.begin();
 * // draw into the texture
 * target.context2D.end();
 * ```
 */
@:forward(width, height, unload, generateMipmaps)
extern abstract Texture(Image) from Image to Image {
	private var self(get, set):kha.Image;

	@:to
	private inline function get_self():kha.Image
		return @:privateAccess this.image;

	private inline function set_self(value:kha.Image):kha.Image
		return @:privateAccess this.image = value;

	/**
	 * 1D graphics context for this texture.
	 *
	 * Use this when you need low-level access to the 1D drawing API exposed by Kha.
	 */
	public var context1D(get, never):Context1D;

	/**
	 * 2D graphics context for this texture.
	 *
	 * This is the most common entry point when drawing UI, sprites, and text into
	 * an off-screen target.
	 */
	public var context2D(get, never):Context2D;

	/**
	 * 3D graphics context for this texture.
	 *
	 * Use this for custom GPU rendering passes targeting the texture.
	 */
	public var context3D(get, never):Context3D;

	/**
	 * Creates a render-target texture.
	 *
	 * The created texture is backed by a `Image` render target and can be used
	 * immediately as a draw destination.
	 *
	 * @param width Texture width in pixels.
	 * @param height Texture height in pixels.
	 * @param format Optional texture format.
	 * @param depthStencil Optional depth/stencil format.
	 * @param aaSamples Multisample count.
	 */
	public inline function new(width:Int, height:Int, ?format:TextureFormat, ?depthStencil:DepthStencilFormat, aaSamples:Int = 1) {
		this = new Image();
		self = kha.Image.createRenderTarget(width, height, format, depthStencil, aaSamples);
	}

	public inline function setDepthStencilFrom(image:Image)
		self.setDepthStencilFrom(image);

	private inline function get_context1D():Context1D
		return self.g1;

	private inline function get_context2D():Context2D
		return self.g2;

	private inline function get_context3D():Context3D
		return self.g4;
}
