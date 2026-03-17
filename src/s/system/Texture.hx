package s.system;

import kha.graphics4.MipMapFilter;
import kha.graphics4.TextureFilter;
import kha.graphics4.TextureFormat;
import kha.graphics4.TextureAddressing;
import kha.graphics4.DepthStencilFormat;
import s.system.graphics.Context1D;
import s.system.graphics.Context2D;
import s.system.graphics.Context3D;
import s.system.resource.Image;

@:forward(unload, width, height, generateMipmaps)
extern abstract Texture(Image) from Image to Image {
	private var self(get, never):kha.Image;

	@:to
	private inline function get_self():kha.Image {
		return this;
	}

	public var context1D(get, never):Context1D;
	public var context2D(get, never):Context2D;
	public var context3D(get, never):Context3D;

	public inline function new(width:Int, height:Int, ?format:TextureFormat, ?depthStencil:DepthStencilFormat, aaSamples:Int = 1) {
		this = kha.Image.createRenderTarget(width, height, format, depthStencil, aaSamples);
	}

	public inline function setDepthStencilFrom(image:Image) {
		self.setDepthStencilFrom(image);
	}

	private inline function get_context1D():Context1D {
		return self.g1;
	}

	private inline function get_context2D():Context2D {
		return self.g2;
	}

	private inline function get_context3D():Context3D {
		return self.g4;
	}
}

typedef TextureParameters = {
	var ?uAddressing:TextureAddressing;
	var ?vAddressing:TextureAddressing;
	var ?minificationFilter:TextureFilter;
	var ?magnificationFilter:TextureFilter;
	var ?mipmapFilter:MipMapFilter;
}
