package s.graphics.shaders;

import kha.graphics4.TextureUnit;

abstract class TexturedShader extends Shader2D {
	var sourceTU:TextureUnit;

	function new(frag:String = "texture2d", vert:String = "shader2d") {
		super(frag, vert);
	}

	override function setup() {
		super.setup();
		sourceTU = pipeline.getTextureUnit("source");
	}
}
