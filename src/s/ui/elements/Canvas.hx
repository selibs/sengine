package s.ui.elements;

import kha.Image;
import s.math.Mat3;
import s.geometry.ISize;
import s.graphics.Context2D;
import s.graphics.RenderTarget;

class Canvas extends Drawable {
	var texture:RenderTarget;
	@:attr var size:ISize;

	@:attr public var format:TextureFormat = TextureFormat.RGBA32;
	@:attr public var samples:Int = 1;
	@:attr public var depthStencil:DepthStencilFormat = NoDepthAndStencil;
	@:attr public var textureSize:ISize;

	public inline function paint(f:Context2D->Void):Void
		texture?.context2D.draw(true, color, f);

	override function update() {
		super.update();

		if (textureSizeDirty || textureSize == null && (widthDirty || heightDirty))
			if (textureSize == null)
				size = new ISize(width, height);
			else
				size = textureSize;

		if (sizeDirty || formatDirty || depthStencilDirty || samplesDirty) {
			var tex = texture;

			texture = new RenderTarget(size.width, size.height, format, depthStencil, samples);
			if (Image.renderTargetsInvertedY())
				texture.context2D.transform.setFrom(Mat3.orthogonalProjection(0, width, 0, height));
			else
				texture.context2D.transform.setFrom(Mat3.orthogonalProjection(0, width, height, 0));
			if (tex != null) {
				texture.context2D.draw(false, Transparent, ctx -> {
					ctx.style.color = White;
					ctx.drawScaledImage(tex, 0.0, 0.0, width, height);
				});
				tex.unload();
			}
		}
	}

	function draw(target:RenderTarget) {
		if (texture == null)
			return;
		final ctx = target.context2D;
		ctx.style.color = realColor;
		ctx.pushTransform(globalTransform);
		ctx.drawImage(texture, left.position, top.position);
		ctx.popTransform();
	}
}
