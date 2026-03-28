package s.graphics.shaders;

import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;

abstract class TexturedShader extends Shader2D {
	var sourceTU:TextureUnit;
	var clipRectCL:ConstantLocation;

	function new(frag:String = "texture2d", vert:String = "texture2d") {
		super(frag, vert);
	}

	override function setup() {
		super.setup();
		sourceTU = pipeline.getTextureUnit("source");
		clipRectCL = pipeline.getConstantLocation("clipRect");
	}
}
