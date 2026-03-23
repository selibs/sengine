package s.markup.graphics;

import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import s.markup.elements.DrawableElement;

@:allow(s.markup.elements.DrawableElement)
abstract class TexturedElementDrawer<T:DrawableElement> extends ElementDrawer<T> {
	var sourceTU:TextureUnit;
	var sourceRectCL:ConstantLocation;
	var sourceClipRectCL:ConstantLocation;

	function new(?frag:String, ?vert:String) {
		super(frag ?? "texture", vert ?? "texture");
	}

	override function setup() {
		super.setup();
		sourceTU = pipeline.getTextureUnit("source");
		sourceRectCL = pipeline.getConstantLocation("sourceRect");
		sourceClipRectCL = pipeline.getConstantLocation("sourceClipRect");
	}
}
