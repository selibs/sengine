package s.ui.elements;

import s.graphics.RenderTarget;
import kha.Image;
import s.math.Mat3;
import s.geometry.ISize;
import s.graphics.Context2D;
import s.graphics.RenderTarget.RenderTargetData;
import s.graphics.TextureFormat;
import s.graphics.DepthStencilFormat;
import s.ui.elements.Drawable;

typedef CanvasAttributes = {
	> DrawableAttributes,
	?format:TextureFormat,
	?samples:Int,
	?depthStencil:DepthStencilFormat,
	?textureSize:ISize
}

class Canvas extends Textured<RenderTargetData> {
	public static inline function setAttributes(x:Canvas, a:CanvasAttributes) {
		Drawable.setAttributes(x, a);
		if (a.format != null)
			x.format = a.format;
		if (a.samples != null)
			x.samples = a.samples;
		if (a.depthStencil != null)
			x.depthStencil = a.depthStencil;
		if (a.textureSize != null)
			x.textureSize = a.textureSize;
	}

	@:attr(textureParameters) var size:ISize;

	@:attr public var textureSize:ISize;
	@:attr(textureParameters) public var format:TextureFormat = TextureFormat.RGBA32;
	@:attr(textureParameters) public var samples:Int = 1;
	@:attr(textureParameters) public var depthStencil:DepthStencilFormat = NoDepthAndStencil;

	public inline function paint(f:Context2D->Void):Void
		texture?.context2D.draw(true, color, f);

	override function update() {
		super.update();

		if (textureSizeDirty || textureSize == null && (widthDirty || heightDirty))
			if (textureSize == null)
				size = new ISize(width, height);
			else
				size = textureSize;

		if (!textureParametersDirty)
			return;

		var tex = texture;

		texture = new RenderTarget(size.width, size.height, format, depthStencil, samples);
		if (Image.renderTargetsInvertedY())
			texture.context2D.transform.setFrom(Mat3.orthogonalProjection(0, width, 0, height));
		else
			texture.context2D.transform.setFrom(Mat3.orthogonalProjection(0, width, height, 0));

		if (tex == null)
			return;

		texture.context2D.draw(false, Transparent, ctx -> {
			ctx.style.color = White;
			ctx.drawScaledImage(tex, 0.0, 0.0, width, height);
		});
		tex.unload();
	}
}
