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
import s.graphics.RenderTarget;
import s.graphics.VertexBuffer;

private final logger:Log.Logger = new Log.Logger("RENDER");

enum DrawCommand {
	Clear(color:Color, depth:Float, stencil:Int);
	Scissor(x:Int, y:Int, width:Int, height:Int);
	DisableScissor;
	UniformBool(location:ConstantLocation, value:Bool);
	UniformInt(location:ConstantLocation, value:Int);
	UniformInts(location:ConstantLocation, value:Int32Array);
	UniformIVec2(location:ConstantLocation, value:Vec2I);
	UniformIVec3(location:ConstantLocation, value:Vec3I);
	UniformIVec4(location:ConstantLocation, value:Vec4I);
	UniformFloat(location:ConstantLocation, value:Float);
	UniformFloats(location:ConstantLocation, value:Float32Array);
	UniformVec2(location:ConstantLocation, value:Vec2);
	UniformVec3(location:ConstantLocation, value:Vec3);
	UniformVec4(location:ConstantLocation, value:Vec4);
	UniformMat3(location:ConstantLocation, value:Mat3);
	UniformMat4(location:ConstantLocation, value:Mat4);
	UniformTexture(unit:TextureUnit, image:Image);
	UniformTextureParameters(unit:TextureUnit, parameters:TextureParameters);
}

typedef DrawStep = {
	var start:Int;
	var count:Int;
	@:optional var instanceCount:Int;
	var commands:Array<DrawCommand>;
}

typedef MeshRange = {
	var start:Int;
	var count:Int;
}

typedef DrawState = {
	@:optional var pipeline:PipelineState;
	@:optional var indexBuffer:IndexBuffer;
	@:optional var vertexBuffer:VertexBuffer;

	var meshRefs:Array<Mesh>;
	var meshVertexCounts:Array<Int>;
	var meshIndexCounts:Array<Int>;
	var meshRanges:ObjectMap<Mesh, MeshRange>;
	var meshRefCount:Int;
	var prevMeshRefCount:Int;

	var steps:Array<DrawStep>;

	var vertexCount:Int;
	var indexCount:Int;
	var prevVertexCount:Int;
	var prevIndexCount:Int;

	var vbCapacity:Int;
	var ibCapacity:Int;

	var meshDirty:Bool;
}

@:allow(s.graphics.RenderTarget)
class Context3D {
	final graphics:Graphics;

	var states:Array<DrawState>;
	var frameStateCount:Int = 0;
	public var frameId(default, null):Int = 0;

	var recordingPipeline:PipelineState;
	var recordingMesh:Mesh;
	var recordingVertexCount:Int = 0;
	var recordingIndexCount:Int = 0;
	var recordingForceDirty:Bool = false;
	var recordingDirty:Bool = false;

	var step:DrawStep;

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

		states = [];
		resetRecording();
	}

	inline function resetRecording() {
		recordingPipeline = null;
		recordingMesh = null;
		recordingVertexCount = 0;
		recordingIndexCount = 0;
		recordingForceDirty = false;
		recordingDirty = false;
		step = newStep();
	}

	inline function resetStepOnly() {
		recordingForceDirty = false;
		recordingDirty = false;
		step = newStep();
	}

	inline function newStep():DrawStep {
		return {
			start: 0,
			count: 0,
			commands: []
		};
	}

	inline function newState():DrawState {
		return {
			meshRefs: [],
			meshVertexCounts: [],
			meshIndexCounts: [],
			meshRanges: new ObjectMap<Mesh, MeshRange>(),
			meshRefCount: 0,
			prevMeshRefCount: 0,
			steps: [],
			vertexCount: 0,
			indexCount: 0,
			prevVertexCount: 0,
			prevIndexCount: 0,
			vbCapacity: 0,
			ibCapacity: 0,
			meshDirty: true
		};
	}

	inline function acquireStateSlot(index:Int):DrawState {
		if (index < states.length)
			return states[index];

		var s = newState();
		states.push(s);
		return s;
	}

	inline function prepareStateSlot(slot:DrawState, pipeline:PipelineState) {
		slot.prevMeshRefCount = slot.meshRefCount;
		slot.prevVertexCount = slot.vertexCount;
		slot.prevIndexCount = slot.indexCount;

		// очищаем map текущего кадра, но сохраняем старые массивы для сравнения
		for (i in 0...slot.meshRefCount)
			slot.meshRanges.remove(slot.meshRefs[i]);

		slot.meshRefCount = 0;
		slot.vertexCount = 0;
		slot.indexCount = 0;
		slot.steps.resize(0);

		if (slot.pipeline != pipeline) {
			slot.pipeline = pipeline;
			slot.meshDirty = true;

			if (slot.vertexBuffer != null) {
				slot.vertexBuffer.delete();
				slot.vertexBuffer = null;
			}

			if (slot.indexBuffer != null) {
				slot.indexBuffer.delete();
				slot.indexBuffer = null;
			}

			slot.vbCapacity = 0;
			slot.ibCapacity = 0;
		}
	}

	inline function finalizeStateSlot(slot:DrawState) {
		if (slot.meshRefCount != slot.prevMeshRefCount)
			slot.meshDirty = true;

		if (slot.vertexCount != slot.prevVertexCount)
			slot.meshDirty = true;

		if (slot.indexCount != slot.prevIndexCount)
			slot.meshDirty = true;
	}

	inline function countMeshVertices(mesh:Mesh):Int {
		if (mesh == null)
			return 0;

		var total = 0;
		for (p in mesh)
			total += p.length;
		return total;
	}

	inline function countMeshIndices(mesh:Mesh):Int {
		if (mesh == null)
			return 0;

		var total = 0;
		for (p in mesh) {
			var n = p.length;
			if (n >= 3)
				total += (n - 2) * 3;
		}
		return total;
	}

	inline function clampDrawCount(start:Int, count:Int, totalIndices:Int):Int {
		if (start >= totalIndices)
			return 0;

		var drawCount = count < 0 ? (totalIndices - start) : count;
		if (drawCount > totalIndices - start)
			drawCount = totalIndices - start;
		if (drawCount < 0)
			drawCount = 0;
		return drawCount;
	}

	inline function nextCapacity(value:Int):Int {
		var cap = 1;
		while (cap < value)
			cap <<= 1;
		return cap;
	}

	inline function appendOrGetMeshRange(slot:DrawState, mesh:Mesh, localVertexCount:Int, localIndexCount:Int, forceDirty:Bool):MeshRange {
		var range = slot.meshRanges.get(mesh);
		if (range != null) {
			if (forceDirty)
				slot.meshDirty = true;
			return range;
		}

		var pos = slot.meshRefCount;
		var sameAsPrev = pos < slot.prevMeshRefCount
			&& slot.meshRefs[pos] == mesh
			&& slot.meshVertexCounts[pos] == localVertexCount
			&& slot.meshIndexCounts[pos] == localIndexCount;

		if (!sameAsPrev || forceDirty)
			slot.meshDirty = true;

		if (pos < slot.meshRefs.length)
			slot.meshRefs[pos] = mesh;
		else
			slot.meshRefs.push(mesh);

		if (pos < slot.meshVertexCounts.length)
			slot.meshVertexCounts[pos] = localVertexCount;
		else
			slot.meshVertexCounts.push(localVertexCount);

		if (pos < slot.meshIndexCounts.length)
			slot.meshIndexCounts[pos] = localIndexCount;
		else
			slot.meshIndexCounts.push(localIndexCount);

		range = {
			start: slot.indexCount,
			count: localIndexCount
		};

		slot.meshRanges.set(mesh, range);
		slot.meshRefCount++;
		slot.vertexCount += localVertexCount;
		slot.indexCount += localIndexCount;

		return range;
	}

	inline function ensureBuffers(slot:DrawState) {
		if (slot == null || slot.pipeline == null)
			return;

		if (slot.vertexCount <= 0 || slot.indexCount <= 0)
			return;

		var structure = slot.pipeline.inputLayout[0];

		if (slot.vertexBuffer == null || slot.vbCapacity < slot.vertexCount) {
			if (slot.vertexBuffer != null)
				slot.vertexBuffer.delete();

			slot.vbCapacity = nextCapacity(slot.vertexCount);
			slot.vertexBuffer = new VertexBuffer(slot.vbCapacity, structure, StaticUsage);
			slot.meshDirty = true;
		}

		if (slot.indexBuffer == null || slot.ibCapacity < slot.indexCount) {
			if (slot.indexBuffer != null)
				slot.indexBuffer.delete();

			slot.ibCapacity = nextCapacity(slot.indexCount);
			slot.indexBuffer = new IndexBuffer(slot.ibCapacity, StaticUsage);
			slot.meshDirty = true;
		}

		if (!slot.meshDirty)
			return;

		uploadMesh(slot);
		slot.meshDirty = false;
	}

	inline function uploadMesh(slot:DrawState) {
		var vert = slot.vertexBuffer.lock();
		var ind = slot.indexBuffer.lock();

		var floatsPerVertex = slot.vertexBuffer.stride() >> 2;

		var vertexOffset = 0;
		var vertWrite = 0;
		var indWrite = 0;

		for (m in 0...slot.meshRefCount) {
			var mesh = slot.meshRefs[m];

			for (p in mesh) {
				var n = p.length;
				if (n == 0)
					continue;

				for (v in p) {
					if (v.length != floatsPerVertex)
						throw 'Vertex size mismatch. Expected $floatsPerVertex floats, got ${v.length}.';

					for (i in 0...floatsPerVertex)
						vert[vertWrite + i] = v[i];

					vertWrite += floatsPerVertex;
				}

				if (n >= 3) {
					for (i in 1...n - 1) {
						ind[indWrite++] = vertexOffset;
						ind[indWrite++] = vertexOffset + i;
						ind[indWrite++] = vertexOffset + i + 1;
					}
				}

				vertexOffset += n;
			}
		}

		slot.vertexBuffer.unlock();
		slot.indexBuffer.unlock();
	}

	inline function hasPendingRecording():Bool {
		return recordingDirty && (recordingMesh != null || step.commands.length > 0 || step.instanceCount != null);
	}

	function pushStep(slot:DrawState, start:Int, count:Int, instanceCount:Null<Int>, commands:Array<DrawCommand>) {
		if (count == 0 && commands.length == 0)
			return;

		if (commands.length == 0 && count > 0 && instanceCount == null && slot.steps.length > 0) {
			var prev = slot.steps[slot.steps.length - 1];
			if (prev.instanceCount == null && prev.start + prev.count == start) {
				prev.count += count;
				return;
			}
		}

		slot.steps.push({
			start: start,
			count: count,
			instanceCount: instanceCount,
			commands: commands
		});
	}

	public inline function begin(?mrt:Array<kha.Canvas>) {
		#if S2D_DEBUG_FPS
		beginTime = haxe.Timer.stamp() * 1000;
		#end

		graphics.begin(mrt);

		frameId++;
		frameStateCount = 0;
		resetRecording();
	}

	public inline function end() {
		#if S2D_DEBUG_FPS
		cpuTime = haxe.Timer.stamp() * 1000 - beginTime;
		#end

		if (hasPendingRecording())
			commit();

		for (i in 0...frameStateCount)
			finalizeStateSlot(states[i]);

		try {
			for (i in 0...frameStateCount) {
				var slot = states[i];

				ensureBuffers(slot);

				graphics.setPipeline(slot.pipeline);

				if (slot.vertexBuffer != null && slot.indexBuffer != null) {
					graphics.setIndexBuffer(slot.indexBuffer);
					graphics.setVertexBuffer(slot.vertexBuffer);
				}

				for (step in slot.steps) {
					for (command in step.commands) {
						switch command {
							case Clear(color, depth, stencil):
								graphics.clear(color, depth, stencil);

							case Scissor(x, y, width, height):
								graphics.scissor(x, y, width, height);

							case DisableScissor:
								graphics.disableScissor();

							case UniformBool(location, value):
								graphics.setBool(location, value);

							case UniformInt(location, value):
								graphics.setInt(location, value);

							case UniformInts(location, value):
								graphics.setInts(location, value);

							case UniformIVec2(location, value):
								graphics.setInt2(location, value.x, value.y);

							case UniformIVec3(location, value):
								graphics.setInt3(location, value.x, value.y, value.z);

							case UniformIVec4(location, value):
								graphics.setInt4(location, value.x, value.y, value.z, value.w);

							case UniformFloat(location, value):
								graphics.setFloat(location, value);

							case UniformFloats(location, value):
								graphics.setFloats(location, value);

							case UniformVec2(location, value):
								graphics.setVector2(location, value);

							case UniformVec3(location, value):
								graphics.setVector3(location, value);

							case UniformVec4(location, value):
								graphics.setVector4(location, value);

							case UniformMat3(location, value):
								graphics.setMatrix3(location, value);

							case UniformMat4(location, value):
								graphics.setMatrix(location, value);

							case UniformTexture(unit, image):
								graphics.setTexture(unit, image);

							case UniformTextureParameters(unit, parameters):
								graphics.setTextureParameters(unit, parameters.uAddressing, parameters.vAddressing, parameters.minificationFilter,
									parameters.magnificationFilter, parameters.mipmapFilter);
						}
					}

					if (step.count > 0) {
						if (step.instanceCount != null)
							graphics.drawIndexedVerticesInstanced(step.instanceCount, step.start, step.count);
						else
							graphics.drawIndexedVertices(step.start, step.count);

						#if S2D_DEBUG_FPS
						++ drawCalls;
						#end
					}
				}
			}
		} catch (e) {
			logger.error("Failed: " + e.message);
		}

		graphics.end();

		#if S2D_DEBUG_FPS
		gpuTime = haxe.Timer.stamp() * 1000 - beginTime - cpuTime;
		#end
	}

	public inline function commitInstanced(instanceCount:Int, start:Int = 0, count:Int = -1) {
		step.instanceCount = instanceCount;
		commit(start, count);
	}

	public inline function commit(start:Int = 0, count:Int = -1) {
		if (recordingPipeline == null) {
			resetStepOnly();
			return;
		}

		if (start < 0)
			start = 0;

		if (start > recordingIndexCount)
			start = recordingIndexCount;

		var drawCount = clampDrawCount(start, count, recordingIndexCount);

		var slot:DrawState;
		var prev = frameStateCount > 0 ? states[frameStateCount - 1] : null;

		var canBatch = prev != null && prev.pipeline == recordingPipeline && step.instanceCount == null;

		if (canBatch) {
			slot = prev;
		} else {
			slot = acquireStateSlot(frameStateCount);
			prepareStateSlot(slot, recordingPipeline);
			frameStateCount++;
		}

		var globalStart = 0;

		if (recordingMesh != null && recordingIndexCount > 0) {
			var range = appendOrGetMeshRange(slot, recordingMesh, recordingVertexCount, recordingIndexCount, recordingForceDirty);
			globalStart = range.start + start;
		}

		pushStep(slot, globalStart, drawCount, step.instanceCount, step.commands);

		resetStepOnly();
	}

	public inline function invalidate() {
		recordingForceDirty = true;
		recordingDirty = true;
	}

	public inline function invalidateAllStates() {
		for (s in states)
			s.meshDirty = true;
	}

	public inline function setPipeline(pipeline:PipelineState)
		recordingPipeline = pipeline;

	public inline function setMesh(mesh:Mesh) {
		recordingMesh = mesh;
		recordingVertexCount = countMeshVertices(mesh);
		recordingIndexCount = countMeshIndices(mesh);
		recordingDirty = true;
	}

	public inline function addCommand(command:DrawCommand) {
		recordingDirty = true;
		step.commands.push(command);
	}

	public inline function clear(?color:Color, ?depth:Float, ?stencil:Int)
		addCommand(Clear(color, depth, stencil));

	public inline function scissor(x:Int, y:Int, width:Int, height:Int)
		addCommand(Scissor(x, y, width, height));

	public inline function disableScissor()
		addCommand(DisableScissor);

	public inline function setBool(location:ConstantLocation, value:Bool)
		addCommand(UniformBool(location, value));

	public inline function setInt(location:ConstantLocation, value:Int)
		addCommand(UniformInt(location, value));

	public inline function setInts(location:ConstantLocation, value:Int32Array)
		addCommand(UniformInts(location, value));

	extern overload public inline function setIVec2(location:ConstantLocation, value:Vec2I)
		addCommand(UniformIVec2(location, value));

	extern overload public inline function setIVec2(location:ConstantLocation, value1:Int, value2:Int)
		setIVec2(location, ivec2(value1, value2));

	extern overload public inline function setIVec3(location:ConstantLocation, value:Vec3I)
		addCommand(UniformIVec3(location, value));

	extern overload public inline function setIVec3(location:ConstantLocation, value1:Int, value2:Int, value3:Int)
		setIVec3(location, ivec3(value1, value2, value3));

	extern overload public inline function setIVec4(location:ConstantLocation, value:Vec4I)
		addCommand(UniformIVec4(location, value));

	extern overload public inline function setIVec4(location:ConstantLocation, value1:Int, value2:Int, value3:Int, value4:Int)
		setIVec4(location, ivec4(value1, value2, value3, value4));

	public inline function setFloat(location:ConstantLocation, value:Float)
		addCommand(UniformFloat(location, value));

	public inline function setFloats(location:ConstantLocation, value:Float32Array)
		addCommand(UniformFloats(location, value));

	extern overload public inline function setVec2(location:ConstantLocation, value:Vec2)
		addCommand(UniformVec2(location, value));

	extern overload public inline function setVec2(location:ConstantLocation, value1:Float, value2:Float)
		setVec2(location, vec2(value1, value2));

	extern overload public inline function setVec3(location:ConstantLocation, value:Vec3)
		addCommand(UniformVec3(location, value));

	extern overload public inline function setVec3(location:ConstantLocation, value1:Float, value2:Float, value3:Float)
		setVec3(location, vec3(value1, value2, value3));

	extern overload public inline function setVec4(location:ConstantLocation, value:Vec4)
		addCommand(UniformVec4(location, value));

	extern overload public inline function setVec4(location:ConstantLocation, value1:Float, value2:Float, value3:Float, value4:Float)
		setVec4(location, vec4(value1, value2, value3, value4));

	extern overload public inline function setMat3(location:ConstantLocation, value:Mat3)
		addCommand(UniformMat3(location, value));

	extern overload public inline function setMat3(location:ConstantLocation, value1:Vec3, value2:Vec3, value3:Vec3)
		setMat3(location, mat3(value1, value2, value3));

	extern overload public inline function setMat3(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a01:Float, a11:Float, a21:Float, a02:Float,
			a12:Float, a22:Float)
		setMat3(location, mat3(a00, a10, a20, a01, a11, a21, a02, a12, a22));

	extern overload public inline function setMat4(location:ConstantLocation, value:Mat4)
		addCommand(UniformMat4(location, value));

	extern overload public inline function setMat4(location:ConstantLocation, value1:Vec4, value2:Vec4, value3:Vec4, value4:Vec4)
		setMat4(location, mat4(value1, value2, value3, value4));

	extern overload public inline function setMat4(location:ConstantLocation, a00:Float, a10:Float, a20:Float, a30:Float, a01:Float, a11:Float, a21:Float,
			a31:Float, a02:Float, a12:Float, a22:Float, a32:Float, a03:Float, a13:Float, a23:Float, a33:Float)
		setMat4(location, mat4(a00, a10, a20, a30, a01, a11, a21, a31, a02, a12, a22, a32, a03, a13, a23, a33));

	extern overload public inline function setTexture(unit:TextureUnit, texture:Image)
		addCommand(UniformTexture(unit, texture));

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
		addCommand(UniformTextureParameters(unit, parameters));
}
