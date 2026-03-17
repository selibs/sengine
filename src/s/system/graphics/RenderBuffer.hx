package s.system.graphics;

class RenderBuffer {
	// ping-pong
	var srcInd:Int = 0;
	var tgtInd:Int = 1;
	var buffer:Array<Texture> = [];

	public var src(get, never):Texture;
	public var tgt(get, never):Texture;

	public var depthMap:Texture;
	#if (S2D_LIGHTING == 1)
	#if (S2D_LIGHTING_DEFERRED == 1)
	public var albedoMap:Texture;
	public var normalMap:Texture;
	public var emissionMap:Texture;
	#if (S2D_LIGHTING_PBR == 1)
	public var ormMap:Texture;
	#end
	#end
	#if (S2D_LIGHTING_SHADOWS == 1)
	public var shadowMap:Texture;
	#end
	#end
	public function new() {}

	public function resize(width:Int, heigth:Int) {
		if (!(width > 0))
			width = 1;
		if (!(heigth > 0))
			heigth = 1;

		// ping-pong
		buffer.pop()?.unload();
		buffer.pop()?.unload();
		buffer.push(new Texture(width, heigth, RGBA128));
		buffer.push(new Texture(width, heigth, RGBA128));
		#if (S2D_LIGHTING == 1)
		#if (S2D_LIGHTING_DEFERRED == 1)
		// gbuffer
		depthMap?.unload();
		depthMap = new Texture(width, heigth, A32, DepthOnly);
		albedoMap?.unload();
		albedoMap = new Texture(width, heigth, RGBA32);
		normalMap?.unload();
		normalMap = new Texture(width, heigth, RGBA32);
		emissionMap?.unload();
		emissionMap = new Texture(width, heigth, RGBA32);
		#if (S2D_LIGHTING_PBR == 1)
		ormMap?.unload();
		ormMap = new Texture(width, heigth, RGBA32);
		#end
		#end
		#if (S2D_LIGHTING_SHADOWS == 1)
		shadowMap?.unload();
		shadowMap = new Texture(width, heigth, L8);
		#end
		#end
	}

	public function swap() {
		srcInd = 1 - srcInd;
		tgtInd = 1 - tgtInd;
	}

	function get_src():Texture {
		return buffer[srcInd];
	}

	function get_tgt():Texture {
		return buffer[tgtInd];
	}
}
