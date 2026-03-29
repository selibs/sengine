package s.graphics;

import haxe.Timer;
import kha.arrays.Int32Array;
import kha.arrays.Float32Array;
import kha.graphics4.Graphics;
import kha.graphics4.TextureUnit;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.ConstantLocation;
import s.Log;
import s.math.Vec2;
import s.math.Vec3;
import s.math.Vec4;
import s.math.Mat3;
import s.math.Mat4;
import s.math.Vec2I;
import s.math.Vec3I;
import s.math.Vec4I;
import s.math.SMath;
import s.assets.Image;
import s.graphics.RenderTarget;
import s.graphics.VertexBuffer;

private final logger:Logger = new Logger("RENDER");

@:structInit
class DrawCommand {
	public var pipeline:PipelineState = null;
	public var indexBuffer:IndexBuffer = null;
	public var vertexBuffer:VertexBuffer = null;
	public var vertexBuffers:Array<VertexBuffer> = null;
	public var instanced:Bool = false;
	public var start:Int = 0;
	public var count:Int = -1;
	public var instanceCount:Int = 0;
	public var bool:Map<ConstantLocation, Bool> = [];
	public var float:Map<ConstantLocation, kha.FastFloat> = [];
	public var floats:Map<ConstantLocation, Float32Array> = [];
	public var vec2:Map<ConstantLocation, Vec2> = [];
	public var vec3:Map<ConstantLocation, Vec3> = [];
	public var vec4:Map<ConstantLocation, Vec4> = [];
	public var int:Map<ConstantLocation, Int> = [];
	public var ints:Map<ConstantLocation, Int32Array> = [];
	public var ivec2:Map<ConstantLocation, Vec2I> = [];
	public var ivec3:Map<ConstantLocation, Vec3I> = [];
	public var ivec4:Map<ConstantLocation, Vec4I> = [];
	public var mat3:Map<ConstantLocation, Mat3> = [];
	public var mat4:Map<ConstantLocation, Mat4> = [];
	public var textures:Map<TextureUnit, Image> = [];
	public var textureParameters:Map<TextureUnit, TextureParameters> = [];

	public function execute(graphics:Graphics, pipelineAlreadySet:Bool = false, indexBufferAlreadySet:Bool = false) {
		inline function setCL<T>(f:ConstantLocation->T->Void, a:Map<ConstantLocation, T>)
			for (l in a.keys())
				f(l, a.get(l));

		if (!pipelineAlreadySet)
			graphics.setPipeline(pipeline);
		if (!indexBufferAlreadySet)
			graphics.setIndexBuffer(indexBuffer);
		graphics.setVertexBuffer(vertexBuffer);

		setCL(graphics.setBool, bool);
		setCL(graphics.setFloat, float);
		setCL(graphics.setFloats, floats);
		setCL(graphics.setVector2, vec2);
		setCL(graphics.setVector3, vec3);
		setCL(graphics.setVector4, vec4);
		setCL(graphics.setInt, int);
		setCL(graphics.setInts, ints);
		for (l in ivec2.keys()) {
			var x = ivec2.get(l);
			graphics.setInt2(l, x.x, x.y);
		}
		for (l in ivec3.keys()) {
			var x = ivec3.get(l);
			graphics.setInt3(l, x.x, x.y, x.z);
		}
		for (l in ivec4.keys()) {
			var x = ivec4.get(l);
			graphics.setInt4(l, x.x, x.y, x.z, x.w);
		}
		setCL(graphics.setMatrix3, mat3);
		setCL(graphics.setMatrix, mat4);
		for (t in textures.keys())
			graphics.setTexture(t, textures.get(t));
		for (t in textureParameters.keys()) {
			var p = textureParameters.get(t);
			graphics.setTextureParameters(t, p.uAddressing, p.vAddressing, p.minificationFilter, p.magnificationFilter, p.mipmapFilter);
		}

		if (instanced) {
			graphics.setVertexBuffers(vertexBuffers);
			graphics.drawIndexedVerticesInstanced(instanceCount, start, count);
		} else
			graphics.drawIndexedVertices(start, count);
	}
}

@:allow(s.graphics.RenderTarget)
class Context3D {
	final graphics:Graphics;

	var mrt:Array<kha.Canvas>;

	var commands:Array<DrawCommand>;
	var command:DrawCommand;

	#if S2D_DEBUG_FPS
	var beginTime:Float;
	var executeTime:Float;

	public var cpuTime(default, null):Float;
	public var gpuTime(default, null):Float;
	#end

	public final vsynced:Bool;
	public final refreshRate:Int;
	public final instancedRenderingAvailable:Bool;

	function new(graphics:Graphics) {
		this.graphics = graphics;
		vsynced = graphics.vsynced();
		refreshRate = graphics.refreshRate();
		instancedRenderingAvailable = graphics.instancedRenderingAvailable();
	}

	public inline function begin(?mrt:Array<kha.Canvas>) {
		#if S2D_DEBUG_FPS
		beginTime = Timer.stamp() * 1000;
		#end

		graphics.begin(mrt);
		commands = [];
		command = {};
	}

	public inline function end() {
		try {
			var lastPipeline:PipelineState = null;
			var lastIndexBuffer:IndexBuffer = null;
			#if S2D_DEBUG_FPS
			var executeStart = Timer.stamp() * 1000;
			#end
			for (command in commands) {
				command.execute(graphics, command.pipeline == lastPipeline, command.indexBuffer == lastIndexBuffer);
				lastPipeline = command.pipeline;
				lastIndexBuffer = command.indexBuffer;
			}
			#if S2D_DEBUG_FPS
			executeTime = Timer.stamp() * 1000 - executeStart;
			#end
		} catch (e)
			logger.error("Failed: " + e.message);
		graphics.end();

		#if S2D_DEBUG_FPS
		cpuTime = Timer.stamp() * 1000 - beginTime;
		gpuTime = executeTime;
		#end
	}

	public inline function clear(?color:Color, ?depth:Float, ?stencil:Int)
		graphics.clear(color, depth, stencil);

	public inline function scissor(x:Int, y:Int, width:Int, height:Int)
		graphics.scissor(x, y, width, height);

	public inline function disableScissor()
		graphics.disableScissor();

	public inline function draw(start:Int = 0, count:Int = -1) {
		command.start = start;
		command.count = count;
		commands.push(command);
		command = command != null ? {
			pipeline: command.pipeline,
			indexBuffer: command.indexBuffer,
			vertexBuffer: command.vertexBuffer,
			vertexBuffers: command.vertexBuffers
		} : {};
	}

	public inline function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1) {
		command.instanced = true;
		command.instanceCount = instanceCount;
		draw(start, count);
	}

	public inline function setPipeline(pipeline:PipelineState)
		command.pipeline = pipeline;

	public inline function setIndexBuffer(indexBuffer:IndexBuffer)
		command.indexBuffer = indexBuffer;

	public inline function setVertexBuffer(vertexBuffer:VertexBuffer)
		command.vertexBuffer = vertexBuffer;

	public inline function setVertexBuffers(vertexBuffers:Array<VertexBuffer>)
		command.vertexBuffers = vertexBuffers;

	public inline function setBool(location:ConstantLocation, value:Bool)
		command.bool.set(location, value);

	public inline function setInt(location:ConstantLocation, value:Int)
		command.int.set(location, value);

	public inline function setInts(location:ConstantLocation, value:Int32Array)
		command.ints.set(location, value);

	extern overload public inline function setIVec2(location:ConstantLocation, value:Vec2I)
		command.ivec2.set(location, value);

	extern overload public inline function setIVec2(location:ConstantLocation, value1:Int, value2:Int)
		setIVec2(location, ivec2(value1, value2));

	extern overload public inline function setIVec3(location:ConstantLocation, value:Vec3I)
		command.ivec3.set(location, value);

	extern overload public inline function setIVec3(location:ConstantLocation, value1:Int, value2:Int, value3:Int)
		setIVec3(location, ivec3(value1, value2, value3));

	extern overload public inline function setIVec4(location:ConstantLocation, value:Vec4I)
		command.ivec4.set(location, value);

	extern overload public inline function setIVec4(location:ConstantLocation, value1:Int, value2:Int, value3:Int, value4:Int)
		setIVec4(location, ivec4(value1, value2, value3, value4));

	public inline function setFloat(location:ConstantLocation, value:Float)
		command.float.set(location, value);

	public inline function setFloats(location:ConstantLocation, value:Float32Array)
		command.floats.set(location, value);

	extern overload public inline function setVec2(location:ConstantLocation, value:Vec2)
		command.vec2.set(location, value);

	extern overload public inline function setVec2(location:ConstantLocation, value1:Float, value2:Float)
		setVec2(location, vec2(value1, value2));

	extern overload public inline function setVec3(location:ConstantLocation, value:Vec3)
		command.vec3.set(location, value);

	extern overload public inline function setVec3(location:ConstantLocation, value1:Float, value2:Float, value3:Float)
		setVec3(location, vec3(value1, value2, value3));

	extern overload public inline function setVec4(location:ConstantLocation, value:Vec4)
		command.vec4.set(location, value);

	extern overload public inline function setVec4(location:ConstantLocation, value1:Float, value2:Float, value3:Float, value4:Float)
		setVec4(location, vec4(value1, value2, value3, value4));

	extern overload public inline function setMat3(location:ConstantLocation, value:Mat3)
		command.mat3.set(location, value);

	extern overload public inline function setMat3(location:ConstantLocation, value1:Vec3, value2:Vec3, value3:Vec3)
		setMat3(location, mat3(value1, value2, value3));

	extern overload public inline function setMat3(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a01:Float, a11:Float, a21:Float, a02:Float,
			a12:Float, a22:Float)
		setMat3(location, mat3(a00, a10, a20, a01, a11, a21, a02, a12, a22));

	extern overload public inline function setMat4(location:ConstantLocation, value:Mat4)
		command.mat4.set(location, value);

	extern overload public inline function setMat4(location:ConstantLocation, value1:Vec4, value2:Vec4, value3:Vec4, value4:Vec4)
		setMat4(location, mat4(value1, value2, value3, value4));

	extern overload public inline function setMat4(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a30:Float, a01:Float, a11:Float, a21:Float,
			a31:Float, a02:Float, a12:Float, a22:Float, a32:Float, a03:Float, a13:Float, a23:Float, a33:Float)
		setMat4(location, mat4(a00, a10, a20, a30, a01, a11, a21, a31, a02, a12, a22, a32, a03, a13, a23, a33));

	extern overload public inline function setTexture(unit:TextureUnit, texture:Image)
		command.textures.set(unit, texture);

	extern overload public inline function setTexture(unit:TextureUnit, texture:Image, parameters:TextureParameters) {
		setTexture(unit, texture);
		setTextureParameters(unit, parameters);
	}

	extern overload public inline function setTexture(unit:TextureUnit, texture:Image, ?uAddressing:TextureAddressing, ?vAddressing:TextureAddressing,
			?minificationFilter:TextureFilter, ?magnificationFilter:TextureFilter, ?mipmapFilter:MipMapFilter) {
		setTexture(unit, texture);
		setTextureParameters(unit, uAddressing, vAddressing, minificationFilter, magnificationFilter, mipmapFilter);
	}

	overload extern public inline function setTextureParameters(unit:TextureUnit, ?uAddressing:TextureAddressing, ?vAddressing:TextureAddressing,
			?minificationFilter:TextureFilter, ?magnificationFilter:TextureFilter, ?mipmapFilter:MipMapFilter)
		setTextureParameters(unit, {
			uAddressing: uAddressing,
			vAddressing: vAddressing,
			minificationFilter: minificationFilter,
			magnificationFilter: magnificationFilter,
			mipmapFilter: mipmapFilter
		});

	overload extern public inline function setTextureParameters(unit:TextureUnit, parameters:TextureParameters)
		command.textureParameters.set(unit, parameters);
}
