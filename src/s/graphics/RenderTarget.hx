package s.graphics;

import s.assets.Image;
import s.graphics.Context1D;
import s.graphics.Context2D;
import s.graphics.Context3D;

/**
 * Render-target texture wrapper with access to 1D, 2D, and 3D graphics contexts.
 *
 * `RenderTarget` is a lightweight abstraction over `kha.Image` for render targets.
 * It is commonly used as an intermediate buffer, post-processing target, or
 * off-screen drawing surface.
 *
 * Typical usage:
 * ```haxe
 * var target = new RenderTarget(512, 512);
 * target.context2D.begin();
 * // draw into the texture
 * target.context2D.end();
 * ```
 */
@:forward
extern abstract RenderTarget(RenderTargetData) from RenderTargetData to RenderTargetData {
	/**
	 * Creates a render-target texture.
	 *
	 * The created texture is backed by a `Image` render target and can be used
	 * immediately as a draw destination.
	 *
	 * @param width RenderTarget width in pixels.
	 * @param height RenderTarget height in pixels.
	 * @param format Optional texture format.
	 * @param depthStencil Optional depth/stencil format.
	 * @param antiAliasingSamples Multisample count.
	 */
	overload public inline function new()
		this = new RenderTargetData();

	/**
	 * Creates a render-target texture.
	 *
	 * The created texture is backed by a `Image` render target and can be used
	 * immediately as a draw destination.
	 *
	 * @param width RenderTarget width in pixels.
	 * @param height RenderTarget height in pixels.
	 * @param format Optional texture format.
	 * @param depthStencil Optional depth/stencil format.
	 * @param antiAliasingSamples Multisample count.
	 */
	overload public inline function new(width:Int, height:Int, ?format:TextureFormat, ?depthStencil:DepthStencilFormat, antiAliasingSamples:Int = 1) {
		this = new RenderTargetData();
		setParameters(width, height, format, depthStencil, antiAliasingSamples);
	}

	public inline function setParameters(width:Int, height:Int, ?format:TextureFormat, ?depthStencil:DepthStencilFormat, antiAliasingSamples:Int = 1)
		@:privateAccess this.image = kha.Image.createRenderTarget(width, height, format, depthStencil, antiAliasingSamples);

	public inline function setDepthStencilFrom(image:Image)
		@:privateAccess this.image.setDepthStencilFrom(image);

	@:to
	private inline function toResource():kha.Image
		return @:privateAccess this.image;

	@:to
	private inline function toCanvas():kha.Canvas
		return toResource();

	@:to
	private inline function toAsset():s.assets.Image
		return this;
}

class RenderTargetData extends s.assets.internal.image.Image {
	/**
	 * 1D graphics context for this texture.
	 *
	 * Use this when you need low-level access to the 1D drawing API exposed by Kha.
	 */
	public var context1D:Context1D;

	/**
	 * 2D graphics context for this texture.
	 *
	 * This is the most common entry point when drawing UI, sprites, and text into
	 * an off-screen target.
	 */
	public var context2D:Context2D;

	/**
	 * 3D graphics context for this texture.
	 *
	 * Use this for custom GPU rendering passes targeting the texture.
	 */
	public var context3D:Context3D;

	@:slot(loaded)
	function updateContext()
		if (isLoaded) {
			context3D = new Context3D(image.g4);
			context2D = new Context2D(context3D);
			context1D = image.g1;
		}
}
