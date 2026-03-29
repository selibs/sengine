package s.graphics;

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

typedef DrawCommand = {
	?pipeline:PipelineState,
	?states:Array<DrawState>
}

typedef DrawState = {
	?indexBuffer:IndexBuffer,
	?vertexBuffer:VertexBuffer,
	?vertexBuffers:Array<VertexBuffer>,
	?start:Int,
	?count:Int,
	?instanceCount:Int,
	?bool:Map<ConstantLocation, Bool>,
	?float:Map<ConstantLocation, kha.FastFloat>,
	?floats:Map<ConstantLocation, Float32Array>,
	?vec2:Map<ConstantLocation, Vec2>,
	?vec3:Map<ConstantLocation, Vec3>,
	?vec4:Map<ConstantLocation, Vec4>,
	?int:Map<ConstantLocation, Int>,
	?ints:Map<ConstantLocation, Int32Array>,
	?ivec2:Map<ConstantLocation, Vec2I>,
	?ivec3:Map<ConstantLocation, Vec3I>,
	?ivec4:Map<ConstantLocation, Vec4I>,
	?mat3:Map<ConstantLocation, Mat3>,
	?mat4:Map<ConstantLocation, Mat4>,
	?textures:Map<TextureUnit, Image>,
	?textureParameters:Map<TextureUnit, TextureParameters>
}

@:allow(s.graphics.RenderTarget)
class Context3D {
	final graphics:Graphics;

	var state:DrawState;
	var command:DrawCommand;
	var pipeline:PipelineState;
	var commands:Array<DrawCommand>;

	#if S2D_DEBUG_FPS
	var beginTime:Float;

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
		beginTime = haxe.Timer.stamp() * 1000;
		#end
		graphics.begin(mrt);

		state = {};
		command = {states: [state]}
		commands = [];
	}

	public inline function end() {
		flush();

		#if S2D_DEBUG_FPS
		cpuTime = haxe.Timer.stamp() * 1000 - beginTime;
		#end

		try {
			execute();
		} catch (e)
			logger.error("Failed: " + e.message);
		graphics.end();

		#if S2D_DEBUG_FPS
		gpuTime = haxe.Timer.stamp() * 1000 - cpuTime;
		#end
	}

	inline function execute() {
		inline function setCL<T>(f:ConstantLocation->T->Void, a:Map<ConstantLocation, T>)
			if (a != null)
				for (l in a.keys())
					f(l, a.get(l));

		for (c in commands) {
			graphics.setPipeline(c.pipeline);

			for (s in c.states) {
				// constants
				setCL(graphics.setBool, s.bool);
				setCL(graphics.setFloat, s.float);
				setCL(graphics.setFloats, s.floats);
				setCL(graphics.setVector2, s.vec2);
				setCL(graphics.setVector3, s.vec3);
				setCL(graphics.setVector4, s.vec4);
				setCL(graphics.setInt, s.int);
				setCL(graphics.setInts, s.ints);
				if (s.ivec2 != null)
					for (l in s.ivec2.keys()) {
						var x = s.ivec2.get(l);
						graphics.setInt2(l, x.x, x.y);
					}
				if (s.ivec3 != null)
					for (l in s.ivec3.keys()) {
						var x = s.ivec3.get(l);
						graphics.setInt3(l, x.x, x.y, x.z);
					}
				if (s.ivec4 != null)
					for (l in s.ivec4.keys()) {
						var x = s.ivec4.get(l);
						graphics.setInt4(l, x.x, x.y, x.z, x.w);
					}
				setCL(graphics.setMatrix3, s.mat3);
				setCL(graphics.setMatrix, s.mat4);
				if (s.textures != null)
					for (t in s.textures.keys())
						graphics.setTexture(t, s.textures.get(t));
				if (s.textureParameters != null)
					for (t in s.textureParameters.keys()) {
						var p = s.textureParameters.get(t);
						graphics.setTextureParameters(t, p.uAddressing, p.vAddressing, p.minificationFilter, p.magnificationFilter, p.mipmapFilter);
					}

				// geometry
				graphics.setIndexBuffer(s.indexBuffer);

				if (s.vertexBuffers != null) {
					graphics.setVertexBuffers(s.vertexBuffers);
					graphics.drawIndexedVerticesInstanced(s.instanceCount, s.start, s.count);
				} else {
					graphics.setVertexBuffer(s.vertexBuffer);
					graphics.drawIndexedVertices(s.start, s.count);
				}
			}
		}
	}

	public inline function clear(?color:Color, ?depth:Float, ?stencil:Int)
		graphics.clear(color, depth, stencil);

	public inline function scissor(x:Int, y:Int, width:Int, height:Int)
		graphics.scissor(x, y, width, height);

	public inline function disableScissor()
		graphics.disableScissor();

	public inline function draw(start:Int = 0, count:Int = -1) {
		state.start = start;
		state.count = count;
        
		if (command.pipeline != null && command.pipeline != pipeline)
			flush();
		else {
			command.states.push(state);
			state = {
				indexBuffer: state.indexBuffer,
				vertexBuffer: state.vertexBuffer,
				vertexBuffers: state.vertexBuffers
			};
		}
	}

	inline function flush() {
		pipeline = command.pipeline;
		commands.push(command);
		state = {
			indexBuffer: state.indexBuffer,
			vertexBuffer: state.vertexBuffer,
			vertexBuffers: state.vertexBuffers
		};
		command = {states: [state]}
	}

	public inline function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1) {
		state.instanceCount = instanceCount;
		draw(start, count);
	}

	public inline function setPipeline(pipeline:PipelineState)
		command.pipeline = pipeline;

	public inline function setIndexBuffer(indexBuffer:IndexBuffer)
		state.indexBuffer = indexBuffer;

	public inline function setVertexBuffer(vertexBuffer:VertexBuffer)
		state.vertexBuffer = vertexBuffer;

	public inline function setVertexBuffers(vertexBuffers:Array<VertexBuffer>)
		state.vertexBuffers = vertexBuffers;

	public inline function setBool(location:ConstantLocation, value:Bool)
		(state.bool = state.bool ?? []).set(location, value);

	public inline function setInt(location:ConstantLocation, value:Int)
		(state.int = state.int ?? []).set(location, value);

	public inline function setInts(location:ConstantLocation, value:Int32Array)
		(state.ints = state.ints ?? []).set(location, value);

	extern overload public inline function setIVec2(location:ConstantLocation, value:Vec2I)
		(state.ivec2 = state.ivec2 ?? []).set(location, value);

	extern overload public inline function setIVec2(location:ConstantLocation, value1:Int, value2:Int)
		setIVec2(location, ivec2(value1, value2));

	extern overload public inline function setIVec3(location:ConstantLocation, value:Vec3I)
		(state.ivec3 = state.ivec3 ?? []).set(location, value);

	extern overload public inline function setIVec3(location:ConstantLocation, value1:Int, value2:Int, value3:Int)
		setIVec3(location, ivec3(value1, value2, value3));

	extern overload public inline function setIVec4(location:ConstantLocation, value:Vec4I)
		(state.ivec4 = state.ivec4 ?? []).set(location, value);

	extern overload public inline function setIVec4(location:ConstantLocation, value1:Int, value2:Int, value3:Int, value4:Int)
		setIVec4(location, ivec4(value1, value2, value3, value4));

	public inline function setFloat(location:ConstantLocation, value:Float)
		(state.float = state.float ?? []).set(location, value);

	public inline function setFloats(location:ConstantLocation, value:Float32Array)
		(state.floats = state.floats ?? []).set(location, value);

	extern overload public inline function setVec2(location:ConstantLocation, value:Vec2)
		(state.vec2 = state.vec2 ?? []).set(location, value);

	extern overload public inline function setVec2(location:ConstantLocation, value1:Float, value2:Float)
		setVec2(location, vec2(value1, value2));

	extern overload public inline function setVec3(location:ConstantLocation, value:Vec3)
		(state.vec3 = state.vec3 ?? []).set(location, value);

	extern overload public inline function setVec3(location:ConstantLocation, value1:Float, value2:Float, value3:Float)
		setVec3(location, vec3(value1, value2, value3));

	extern overload public inline function setVec4(location:ConstantLocation, value:Vec4)
		(state.vec4 = state.vec4 ?? []).set(location, value);

	extern overload public inline function setVec4(location:ConstantLocation, value1:Float, value2:Float, value3:Float, value4:Float)
		setVec4(location, vec4(value1, value2, value3, value4));

	extern overload public inline function setMat3(location:ConstantLocation, value:Mat3)
		(state.mat3 = state.mat3 ?? []).set(location, value);

	extern overload public inline function setMat3(location:ConstantLocation, value1:Vec3, value2:Vec3, value3:Vec3)
		setMat3(location, mat3(value1, value2, value3));

	extern overload public inline function setMat3(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a01:Float, a11:Float, a21:Float, a02:Float,
			a12:Float, a22:Float)
		setMat3(location, mat3(a00, a10, a20, a01, a11, a21, a02, a12, a22));

	extern overload public inline function setMat4(location:ConstantLocation, value:Mat4)
		(state.mat4 = state.mat4 ?? []).set(location, value);

	extern overload public inline function setMat4(location:ConstantLocation, value1:Vec4, value2:Vec4, value3:Vec4, value4:Vec4)
		setMat4(location, mat4(value1, value2, value3, value4));

	extern overload public inline function setMat4(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a30:Float, a01:Float, a11:Float, a21:Float,
			a31:Float, a02:Float, a12:Float, a22:Float, a32:Float, a03:Float, a13:Float, a23:Float, a33:Float)
		setMat4(location, mat4(a00, a10, a20, a30, a01, a11, a21, a31, a02, a12, a22, a32, a03, a13, a23, a33));

	extern overload public inline function setTexture(unit:TextureUnit, texture:Image)
		(state.textures = state.textures ?? []).set(unit, texture);

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
		(state.textureParameters = state.textureParameters ?? []).set(unit, parameters);
}
