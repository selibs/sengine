package s.graphics;

import kha.arrays.Int32Array;
import kha.arrays.Float32Array;
import kha.graphics4.Graphics;
import kha.graphics4.TextureUnit;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.ConstantLocation;
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

private final logger:Log.Logger = new Log.Logger("RENDER");

enum DrawConstant {
	Clear(color:Color, depth:Float, stencil:Int);
	Scissor(x:Int, y:Int, width:Int, height:Int);
	DisableScissor;
	ConstantBool(location:ConstantLocation, value:Bool);
	ConstantInt(location:ConstantLocation, value:Int);
	ConstantInts(location:ConstantLocation, value:Int32Array);
	ConstantIVec2(location:ConstantLocation, value:Vec2I);
	ConstantIVec3(location:ConstantLocation, value:Vec3I);
	ConstantIVec4(location:ConstantLocation, value:Vec4I);
	ConstantFloat(location:ConstantLocation, value:Float);
	ConstantFloats(location:ConstantLocation, value:Float32Array);
	ConstantVec2(location:ConstantLocation, value:Vec2);
	ConstantVec3(location:ConstantLocation, value:Vec3);
	ConstantVec4(location:ConstantLocation, value:Vec4);
	ConstantMat3(location:ConstantLocation, value:Mat3);
	ConstantMat4(location:ConstantLocation, value:Mat4);
	ConstantTexture(unit:TextureUnit, image:Image);
	ConstantTextureParameters(unit:TextureUnit, parameters:TextureParameters);
}

typedef DrawConstants = Array<DrawConstant>;

typedef DrawState = {
	?indexBuffer:IndexBuffer,
	?vertexBuffer:VertexBuffer,
	?vertexBuffers:Array<VertexBuffer>,
	?start:Int,
	?count:Int,
	?instanceCount:Int,
	?constants:Array<DrawConstants>
}

typedef DrawCommand = {
	?pipeline:PipelineState,
	?states:Array<DrawState>
}

@:allow(s.graphics.RenderTarget)
class Context3D {
	final graphics:Graphics;

	var state:DrawState;
	var command:DrawCommand;
	var constants:Array<DrawConstant>;
	var pipeline:PipelineState;
	var commands:Array<DrawCommand>;

	#if S2D_DEBUG_FPS
	public static var drawCalls(default, null):Int = 0;

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

		pipeline = null;
		state = {};
		constants = [];
		command = {states: []}
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
		gpuTime = haxe.Timer.stamp() * 1000 - beginTime - cpuTime;
		#end
	}

	inline function execute() {
		for (c in commands) {
			graphics.setPipeline(c.pipeline);

			for (state in c.states) {
				// geometry
				graphics.setIndexBuffer(state.indexBuffer);
				if (state.vertexBuffers != null)
					graphics.setVertexBuffers(state.vertexBuffers);
				else
					graphics.setVertexBuffer(state.vertexBuffer);

				// constants
				for (constants in state.constants) {
					for (c in constants)
						switch c {
							case Clear(color, depth, stencil):
								graphics.clear(color, depth, stencil);
							case Scissor(x, y, width, height):
								graphics.scissor(x, y, width, height);
							case DisableScissor:
								graphics.disableScissor();
							case ConstantBool(location, value):
								graphics.setBool(location, value);
							case ConstantInt(location, value):
								graphics.setInt(location, value);
							case ConstantInts(location, value):
								graphics.setInts(location, value);
							case ConstantIVec2(location, value):
								graphics.setInt2(location, value.x, value.y);
							case ConstantIVec3(location, value):
								graphics.setInt3(location, value.x, value.y, value.z);
							case ConstantIVec4(location, value):
								graphics.setInt4(location, value.x, value.y, value.z, value.w);
							case ConstantFloat(location, value):
								graphics.setFloat(location, value);
							case ConstantFloats(location, value):
								graphics.setFloats(location, value);
							case ConstantVec2(location, value):
								graphics.setVector2(location, value);
							case ConstantVec3(location, value):
								graphics.setVector3(location, value);
							case ConstantVec4(location, value):
								graphics.setVector4(location, value);
							case ConstantMat3(location, value):
								graphics.setMatrix3(location, value);
							case ConstantMat4(location, value):
								graphics.setMatrix(location, value);
							case ConstantTexture(unit, image):
								graphics.setTexture(unit, image);
							case ConstantTextureParameters(unit, parameters):
								graphics.setTextureParameters(unit, parameters.uAddressing, parameters.vAddressing, parameters.minificationFilter,
									parameters.magnificationFilter, parameters.mipmapFilter);
						}

					if (state.vertexBuffers != null)
						graphics.drawIndexedVerticesInstanced(state.instanceCount, state.start, state.count);
					else
						graphics.drawIndexedVertices(state.start, state.count);
					++drawCalls;
				}
			}
		}
	}

	public inline function clear(?color:Color, ?depth:Float, ?stencil:Int)
		constants.push(Clear(color, depth, stencil));

	public inline function scissor(x:Int, y:Int, width:Int, height:Int)
		constants.push(Scissor(x, y, width, height));

	public inline function disableScissor()
		constants.push(DisableScissor);

	public inline function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1) {
		state.instanceCount = instanceCount;
		draw(start, count);
	}

	public inline function draw(start:Int = 0, count:Int = -1) {
		state.start = start;
		if (count < 0) {
			state.count = if (state.indexBuffer != null) state.indexBuffer.count() else if (state.vertexBuffers != null && state.vertexBuffers.length > 0)
				state.vertexBuffers[0].count() else if (state.vertexBuffer != null) state.vertexBuffer.count() else 0;
		} else {
			state.count = count;
		}

		if (command.states.length == 0)
			pipeline = command.pipeline;
		else if (command.pipeline != null && command.pipeline != pipeline) {
			var nextPipeline = command.pipeline;
			flush();
			command.pipeline = nextPipeline;
			pipeline = nextPipeline;
		}

		var lastState = command.states.length > 0 ? command.states[command.states.length - 1] : null;
		if (lastState != null
			&& lastState.indexBuffer == state.indexBuffer
			&& lastState.vertexBuffer == state.vertexBuffer
			&& lastState.vertexBuffers == state.vertexBuffers
			&& lastState.start == state.start
			&& lastState.count == state.count
			&& lastState.instanceCount == state.instanceCount) {
			if (lastState.constants == null)
				lastState.constants = [];
			lastState.constants.push(constants);
		} else {
			state.constants = [constants];
			command.states.push(state);
		}

		state = {
			indexBuffer: state.indexBuffer,
			vertexBuffer: state.vertexBuffer,
			vertexBuffers: state.vertexBuffers
		};
		constants = [];
	}

	inline function flush() {
		if (command.pipeline != null)
			pipeline = command.pipeline;
		if (command.states.length > 0)
			commands.push(command);
		state = {
			indexBuffer: state.indexBuffer,
			vertexBuffer: state.vertexBuffer,
			vertexBuffers: state.vertexBuffers
		};
		constants = [];
		command = {states: []}
	}

	public inline function setPipeline(pipeline:PipelineState) {
		if (command.states.length > 0 && command.pipeline != null && command.pipeline != pipeline) {
			flush();
		}
		command.pipeline = pipeline;
	}

	public inline function setIndexBuffer(indexBuffer:IndexBuffer)
		state.indexBuffer = indexBuffer;

	public inline function setVertexBuffer(vertexBuffer:VertexBuffer)
		state.vertexBuffer = vertexBuffer;

	public inline function setVertexBuffers(vertexBuffers:Array<VertexBuffer>)
		state.vertexBuffers = vertexBuffers;

	public inline function setBool(location:ConstantLocation, value:Bool)
		constants.push(ConstantBool(location, value));

	public inline function setInt(location:ConstantLocation, value:Int)
		constants.push(ConstantInt(location, value));

	public inline function setInts(location:ConstantLocation, value:Int32Array)
		constants.push(ConstantInts(location, value));

	extern overload public inline function setIVec2(location:ConstantLocation, value:Vec2I)
		constants.push(ConstantIVec2(location, value));

	extern overload public inline function setIVec2(location:ConstantLocation, value1:Int, value2:Int)
		setIVec2(location, ivec2(value1, value2));

	extern overload public inline function setIVec3(location:ConstantLocation, value:Vec3I)
		constants.push(ConstantIVec3(location, value));

	extern overload public inline function setIVec3(location:ConstantLocation, value1:Int, value2:Int, value3:Int)
		setIVec3(location, ivec3(value1, value2, value3));

	extern overload public inline function setIVec4(location:ConstantLocation, value:Vec4I)
		constants.push(ConstantIVec4(location, value));

	extern overload public inline function setIVec4(location:ConstantLocation, value1:Int, value2:Int, value3:Int, value4:Int)
		setIVec4(location, ivec4(value1, value2, value3, value4));

	public inline function setFloat(location:ConstantLocation, value:Float)
		constants.push(ConstantFloat(location, value));

	public inline function setFloats(location:ConstantLocation, value:Float32Array)
		constants.push(ConstantFloats(location, value));

	extern overload public inline function setVec2(location:ConstantLocation, value:Vec2)
		constants.push(ConstantVec2(location, value));

	extern overload public inline function setVec2(location:ConstantLocation, value1:Float, value2:Float)
		setVec2(location, vec2(value1, value2));

	extern overload public inline function setVec3(location:ConstantLocation, value:Vec3)
		constants.push(ConstantVec3(location, value));

	extern overload public inline function setVec3(location:ConstantLocation, value1:Float, value2:Float, value3:Float)
		setVec3(location, vec3(value1, value2, value3));

	extern overload public inline function setVec4(location:ConstantLocation, value:Vec4)
		constants.push(ConstantVec4(location, value));

	extern overload public inline function setVec4(location:ConstantLocation, value1:Float, value2:Float, value3:Float, value4:Float)
		setVec4(location, vec4(value1, value2, value3, value4));

	extern overload public inline function setMat3(location:ConstantLocation, value:Mat3)
		constants.push(ConstantMat3(location, value));

	extern overload public inline function setMat3(location:ConstantLocation, value1:Vec3, value2:Vec3, value3:Vec3)
		setMat3(location, mat3(value1, value2, value3));

	extern overload public inline function setMat3(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a01:Float, a11:Float, a21:Float, a02:Float,
			a12:Float, a22:Float)
		setMat3(location, mat3(a00, a10, a20, a01, a11, a21, a02, a12, a22));

	extern overload public inline function setMat4(location:ConstantLocation, value:Mat4)
		constants.push(ConstantMat4(location, value));

	extern overload public inline function setMat4(location:ConstantLocation, value1:Vec4, value2:Vec4, value3:Vec4, value4:Vec4)
		setMat4(location, mat4(value1, value2, value3, value4));

	extern overload public inline function setMat4(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a30:Float, a01:Float, a11:Float, a21:Float,
			a31:Float, a02:Float, a12:Float, a22:Float, a32:Float, a03:Float, a13:Float, a23:Float, a33:Float)
		setMat4(location, mat4(a00, a10, a20, a30, a01, a11, a21, a31, a02, a12, a22, a32, a03, a13, a23, a33));

	extern overload public inline function setTexture(unit:TextureUnit, texture:Image)
		constants.push(ConstantTexture(unit, texture));

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
		constants.push(ConstantTextureParameters(unit, parameters));
}
