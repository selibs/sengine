package s.graphics;

import haxe.ds.ObjectMap;
import s.geometry.Mesh;
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
import s.graphics.VertexBuffer;
import s.graphics.RenderTarget;

private final logger:Log.Logger = new Log.Logger("RENDER");

enum DrawCommand {
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

typedef DrawState = {
	dirty:Bool,
	pipeline:PipelineState,
	vertexCount:Int,
	indexCount:Int,
	stepCount:Int,

	?mesh:Mesh,
	?indexBuffer:IndexBuffer,
	?vertexBuffer:VertexBuffer,
	?vertexBuffers:Array<VertexBuffer>,

	steps:Array<{
		start:Int,
		count:Int,
		?instanceCount:Int,
		commands:Array<DrawCommand>
	}>
}

typedef DrawStateBuffer = {
	stateId:Int,
	stepId:Int,
	commands:Array<DrawCommand>,
	?pipeline:PipelineState,
	?mesh:Mesh
}

@:allow(s.graphics.RenderTarget)
class Context3D {
	final graphics:Graphics;
	final states:Array<DrawState> = [];

	var targets:Array<kha.Canvas>;
	var buffer:DrawStateBuffer;

	#if S2D_DEBUG_FPS
	public static var cpuTime(default, null):Float;
	public static var gpuTime(default, null):Float;
	public static var drawCalls(default, null):Int = 0;
	public static var ibAllocations(default, null):Int = 0;
	public static var vbAllocations(default, null):Int = 0;

	public static function reset() {
		cpuTime = 0;
		gpuTime = 0;
		drawCalls = 0;
		ibAllocations = 0;
		vbAllocations = 0;
	}

	var beginTime:Float;
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

	inline function applyCommand(command:DrawCommand) {
		switch command {
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
	}

	public inline function begin(?mrt:Array<kha.Canvas>) {
		#if S2D_DEBUG_FPS
		beginTime = haxe.Timer.stamp() * 1000;
		#end
		targets = mrt;
		buffer = {stateId: 0, stepId: 0, commands: []}
	}

	public inline function end() {
		#if S2D_DEBUG_FPS
		var currentCpuTime = haxe.Timer.stamp() * 1000 - beginTime;
		cpuTime += currentCpuTime;
		#end

		try {
			graphics.begin(targets);

			for (state in states) {
				if (state.dirty) {
					bakeState(state);
					state.dirty = false;
				}

				if (state.pipeline == null || state.indexBuffer == null || state.indexCount <= 0)
					continue;

				graphics.setPipeline(state.pipeline);
				graphics.setIndexBuffer(state.indexBuffer);
				if (state.vertexBuffers != null)
					graphics.setVertexBuffers(state.vertexBuffers);
				else if (state.vertexBuffer != null)
					graphics.setVertexBuffer(state.vertexBuffer);
				else
					continue;

				for (stepId in 0...state.stepCount) {
					var step = state.steps[stepId];
					if (step == null)
						continue;

					if (step.commands != null)
						for (command in step.commands)
							applyCommand(command);

					if (step.start < 0 || step.start >= state.indexCount)
						continue;

					var maxCount = state.indexCount - step.start;
					var drawCount = step.count == -1 ? maxCount : Std.int(Math.min(step.count, maxCount));
					if (drawCount <= 0)
						continue;

					if (step.instanceCount != null)
						graphics.drawIndexedVerticesInstanced(step.instanceCount, step.start, drawCount);
					else
						graphics.drawIndexedVertices(step.start, drawCount);

					#if S2D_DEBUG_FPS
					++ drawCalls;
					#end
				}
			}

			graphics.end();
		} catch (e)
			logger.error("Failed: " + e.message);

		#if S2D_DEBUG_FPS
		gpuTime += haxe.Timer.stamp() * 1000 - beginTime - currentCpuTime;
		#end
	}

	inline function bakeState(state:DrawState) {
		if (state.pipeline == null || state.mesh == null || state.mesh.length == 0) {
			state.vertexCount = 0;
			state.indexCount = 0;
			return;
		}

		var struct = state.pipeline.inputLayout[0];
		var floatsPerVertex = struct.byteSize() >> 2;

		var vertCount = 0;
		var indCount = 0;
		for (polygon in state.mesh) {
			var polygonVertCount = polygon.length;
			vertCount += polygonVertCount;
			if (polygonVertCount >= 3)
				indCount += (polygonVertCount - 2) * 3;
		}

		if (vertCount <= 0 || indCount <= 0) {
			state.vertexCount = 0;
			state.indexCount = 0;
			return;
		}

		state.vertexCount = vertCount;
		state.indexCount = indCount;

		if (state.vertexBuffer == null || vertCount > state.vertexBuffer.count()) {
			if (state.vertexBuffer != null)
				state.vertexBuffer.delete();
			state.vertexBuffer = new VertexBuffer(vertCount, struct, StaticUsage);

			#if S2D_DEBUG_FPS
			++ vbAllocations;
			#end
		}

		if (state.indexBuffer == null || indCount > state.indexBuffer.count()) {
			if (state.indexBuffer != null)
				state.indexBuffer.delete();
			state.indexBuffer = new IndexBuffer(indCount, StaticUsage);

			#if S2D_DEBUG_FPS
			++ ibAllocations;
			#end
		}

		var vert = state.vertexBuffer.lock(0, vertCount);
		var ind = state.indexBuffer.lock(0, indCount);

		var vertWrite = 0;
		var indWrite = 0;
		var vertexOffset = 0;

		for (polygon in state.mesh) {
			var polygonVertCount = polygon.length;
			if (polygonVertCount == 0)
				continue;

			for (vertex in polygon) {
				if (vertex.length != floatsPerVertex)
					throw 'Vertex size mismatch. Expected $floatsPerVertex floats, got ${vertex.length}.';

				for (value in vertex)
					vert[vertWrite++] = value;
			}

			if (polygonVertCount >= 3) {
				for (i in 1...polygonVertCount - 1) {
					ind[indWrite++] = vertexOffset;
					ind[indWrite++] = vertexOffset + i;
					ind[indWrite++] = vertexOffset + i + 1;
				}
			}

			vertexOffset += polygonVertCount;
		}

		state.vertexBuffer.unlock(vertCount);
		state.indexBuffer.unlock(indCount);
	}

	public inline function draw(?instanceCount:Int, start:Int = 0, count:Int = -1) {
		if (buffer.pipeline == null)
			return;

		var stateId = buffer.stateId;
		var state = states[stateId];
		var commands = buffer.commands;

		if (state == null) {
			state = {
				dirty: true,
				pipeline: buffer.pipeline,
				vertexCount: 0,
				indexCount: 0,
				stepCount: 1,
				mesh: buffer.mesh,
				steps: [
					{
						start: start,
						count: count,
						instanceCount: instanceCount,
						commands: commands
					}
				]
			};
			if (stateId == states.length)
				states.push(state);
			else
				states[stateId] = state;
		} else {
			state.dirty = true;
			state.pipeline = buffer.pipeline;
			state.mesh = buffer.mesh;
			state.vertexCount = 0;
			state.indexCount = 0;
			state.stepCount = 1;

			var step = state.steps[0];
			if (step == null)
				state.steps[0] = {
					start: start,
					count: count,
					instanceCount: instanceCount,
					commands: commands
				};
			else {
				step.start = start;
				step.count = count;
				step.instanceCount = instanceCount;
				step.commands = commands;
			}
		}

		buffer = {
			stateId: stateId + 1,
			stepId: 0,
			commands: []
		};
	}

	public inline function setPipeline(pipeline:PipelineState)
		buffer.pipeline = pipeline;

	public inline function setMesh(mesh:Mesh)
		buffer.mesh = mesh;

	public inline function addPolygon(polygon:Polygon) {
		var mesh:Mesh = buffer.mesh;
		if (mesh == null) {
			mesh = [];
			buffer.mesh = mesh;
		}
		mesh.push(polygon);
	}

	public inline function addVertex(vertex:Vertex) {
		var mesh:Mesh = buffer.mesh;
		if (mesh == null || mesh.length == 0) {
			mesh = [[vertex]];
			buffer.mesh = mesh;
		} else {
			var polygon:Polygon = mesh[0];
			if (polygon == null) {
				polygon = [];
				mesh[0] = polygon;
			}
			polygon.push(vertex);
		}
	}

	public inline function addCommand(command:DrawCommand)
		buffer.commands.push(command);

	public inline function clear(?color:Color, ?depth:Float, ?stencil:Int)
		addCommand(Clear(color, depth, stencil));

	public inline function scissor(x:Int, y:Int, width:Int, height:Int)
		addCommand(Scissor(x, y, width, height));

	public inline function disableScissor()
		addCommand(DisableScissor);

	public inline function setBool(location:ConstantLocation, value:Bool)
		addCommand(ConstantBool(location, value));

	public inline function setInt(location:ConstantLocation, value:Int)
		addCommand(ConstantInt(location, value));

	public inline function setInts(location:ConstantLocation, value:Int32Array)
		addCommand(ConstantInts(location, value));

	extern overload public inline function setIVec2(location:ConstantLocation, value:Vec2I)
		addCommand(ConstantIVec2(location, value));

	extern overload public inline function setIVec2(location:ConstantLocation, value1:Int, value2:Int)
		setIVec2(location, ivec2(value1, value2));

	extern overload public inline function setIVec3(location:ConstantLocation, value:Vec3I)
		addCommand(ConstantIVec3(location, value));

	extern overload public inline function setIVec3(location:ConstantLocation, value1:Int, value2:Int, value3:Int)
		setIVec3(location, ivec3(value1, value2, value3));

	extern overload public inline function setIVec4(location:ConstantLocation, value:Vec4I)
		addCommand(ConstantIVec4(location, value));

	extern overload public inline function setIVec4(location:ConstantLocation, value1:Int, value2:Int, value3:Int, value4:Int)
		setIVec4(location, ivec4(value1, value2, value3, value4));

	public inline function setFloat(location:ConstantLocation, value:Float)
		addCommand(ConstantFloat(location, value));

	public inline function setFloats(location:ConstantLocation, value:Float32Array)
		addCommand(ConstantFloats(location, value));

	extern overload public inline function setVec2(location:ConstantLocation, value:Vec2)
		addCommand(ConstantVec2(location, value));

	extern overload public inline function setVec2(location:ConstantLocation, value1:Float, value2:Float)
		setVec2(location, vec2(value1, value2));

	extern overload public inline function setVec3(location:ConstantLocation, value:Vec3)
		addCommand(ConstantVec3(location, value));

	extern overload public inline function setVec3(location:ConstantLocation, value1:Float, value2:Float, value3:Float)
		setVec3(location, vec3(value1, value2, value3));

	extern overload public inline function setVec4(location:ConstantLocation, value:Vec4)
		addCommand(ConstantVec4(location, value));

	extern overload public inline function setVec4(location:ConstantLocation, value1:Float, value2:Float, value3:Float, value4:Float)
		setVec4(location, vec4(value1, value2, value3, value4));

	extern overload public inline function setMat3(location:ConstantLocation, value:Mat3)
		addCommand(ConstantMat3(location, value));

	extern overload public inline function setMat3(location:ConstantLocation, value1:Vec3, value2:Vec3, value3:Vec3)
		setMat3(location, mat3(value1, value2, value3));

	extern overload public inline function setMat3(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a01:Float, a11:Float, a21:Float, a02:Float,
			a12:Float, a22:Float)
		setMat3(location, mat3(a00, a10, a20, a01, a11, a21, a02, a12, a22));

	extern overload public inline function setMat4(location:ConstantLocation, value:Mat4)
		addCommand(ConstantMat4(location, value));

	extern overload public inline function setMat4(location:ConstantLocation, value1:Vec4, value2:Vec4, value3:Vec4, value4:Vec4)
		setMat4(location, mat4(value1, value2, value3, value4));

	extern overload public inline function setMat4(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a30:Float, a01:Float, a11:Float, a21:Float,
			a31:Float, a02:Float, a12:Float, a22:Float, a32:Float, a03:Float, a13:Float, a23:Float, a33:Float)
		setMat4(location, mat4(a00, a10, a20, a30, a01, a11, a21, a31, a02, a12, a22, a32, a03, a13, a23, a33));

	extern overload public inline function setTexture(unit:TextureUnit, texture:Image)
		addCommand(ConstantTexture(unit, texture));

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
		addCommand(ConstantTextureParameters(unit, parameters));
}
