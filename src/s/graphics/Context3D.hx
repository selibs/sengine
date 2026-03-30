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
	start:Int,
	count:Int,
	?instanceCount:Int,
	commands:Array<DrawCommand>
}

typedef MeshRange = {
	start:Int,
	count:Int
}

typedef DrawState = {
	?pipeline:PipelineState,
	?indexBuffer:IndexBuffer,
	?vertexBuffer:VertexBuffer,

	meshRefs:Array<Mesh>,
	meshVertexCounts:Array<Int>,
	meshIndexCounts:Array<Int>,
	meshRanges:ObjectMap<Mesh, MeshRange>,
	meshRefCount:Int,
	prevMeshRefCount:Int,

	steps:Array<DrawStep>,

	vertexCount:Int,
	indexCount:Int,
	prevVertexCount:Int,
	prevIndexCount:Int,

	vbCapacity:Int,
	ibCapacity:Int,

	meshDirty:Bool
}

@:allow(s.graphics.RenderTarget)
class Context3D {
	final graphics:Graphics;

	// pipeline -> list of states for 1st use of pipeline in frame, 2nd use, 3rd use, ...
	var pipelineStateCache:ObjectMap<PipelineState, Array<DrawState>> = new ObjectMap();
	var commandStateCache:Array<DrawState> = [];

	// current frame order
	var frameStates:Array<DrawState> = [];
	var pipelineUseCounts:ObjectMap<PipelineState, Int> = new ObjectMap();
	var commandStateUseCount:Int = 0;

	// current recorder bindings
	var recordingPipeline:PipelineState;
	var recordingMesh:Mesh;
	var recordingVertexCount:Int = 0;
	var recordingIndexCount:Int = 0;
	var recordingForceDirty:Bool = false;
	var recordingDirty:Bool = false;
	var step:DrawStep;

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
		resetRecording(true);
	}

	inline function newStep():DrawStep
		return {start: 0, count: 0, commands: []};

	inline function newState():DrawState
		return {
			meshRefs: [],
			meshVertexCounts: [],
			meshIndexCounts: [],
			meshRanges: new ObjectMap(),
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

	inline function resetRecording(full:Bool = false) {
		if (full) {
			recordingPipeline = null;
			recordingMesh = null;
			recordingVertexCount = 0;
			recordingIndexCount = 0;
		}
		recordingForceDirty = false;
		recordingDirty = false;
		step = newStep();
	}

	inline function resetStepOnly() {
		recordingForceDirty = false;
		recordingDirty = false;
		step = newStep();
	}

	inline function markDirty()
		recordingDirty = true;

	inline function meshVertices(mesh:Mesh):Int {
		var n = 0;
		if (mesh != null)
			for (p in mesh)
				n += p.length;
		return n;
	}

	inline function meshIndices(mesh:Mesh):Int {
		var n = 0;
		if (mesh != null)
			for (p in mesh)
				if (p.length >= 3)
					n += (p.length - 2) * 3;
		return n;
	}

	inline function clampCount(start:Int, count:Int, total:Int):Int {
		if (start >= total)
			return 0;

		var c = count < 0 ? total - start : count;
		return c > total - start ? total - start : (c < 0 ? 0 : c);
	}

	inline function nextCapacity(v:Int):Int {
		var c = 1;
		while (c < v)
			c <<= 1;
		return c;
	}

	inline function prepareFrameState(s:DrawState) {
		s.prevMeshRefCount = s.meshRefCount;
		s.prevVertexCount = s.vertexCount;
		s.prevIndexCount = s.indexCount;

		for (i in 0...s.meshRefCount)
			s.meshRanges.remove(s.meshRefs[i]);

		s.meshRefCount = 0;
		s.vertexCount = 0;
		s.indexCount = 0;
		s.steps.resize(0);
	}

	inline function finalizeFrameState(s:DrawState) {
		if (s.meshRefCount != s.prevMeshRefCount || s.vertexCount != s.prevVertexCount || s.indexCount != s.prevIndexCount)
			s.meshDirty = true;
	}

	inline function acquirePipelineState(pipeline:PipelineState):DrawState {
		var list = pipelineStateCache.get(pipeline);
		if (list == null) {
			list = [];
			pipelineStateCache.set(pipeline, list);
		}

		var useIndex = pipelineUseCounts.get(pipeline);
		if (useIndex == null)
			useIndex = 0;
		pipelineUseCounts.set(pipeline, useIndex + 1);

		var s:DrawState;
		if (useIndex < list.length) {
			s = list[useIndex];
		} else {
			s = newState();
			s.pipeline = pipeline;
			list.push(s);
		}

		prepareFrameState(s);
		frameStates.push(s);
		return s;
	}

	inline function acquireCommandState():DrawState {
		var s:DrawState;
		if (commandStateUseCount < commandStateCache.length) {
			s = commandStateCache[commandStateUseCount];
		} else {
			s = newState();
			commandStateCache.push(s);
		}
		commandStateUseCount++;

		s.pipeline = null;
		prepareFrameState(s);
		frameStates.push(s);
		return s;
	}

	inline function appendOrGetMeshRange(s:DrawState, mesh:Mesh, vc:Int, ic:Int, forceDirty:Bool):MeshRange {
		var r = s.meshRanges.get(mesh);
		if (r != null) {
			if (forceDirty)
				s.meshDirty = true;
			return r;
		}

		var pos = s.meshRefCount;
		var sameAsPrev = pos < s.prevMeshRefCount && s.meshRefs[pos] == mesh && s.meshVertexCounts[pos] == vc && s.meshIndexCounts[pos] == ic;

		if (!sameAsPrev || forceDirty)
			s.meshDirty = true;

		if (pos < s.meshRefs.length)
			s.meshRefs[pos] = mesh;
		else
			s.meshRefs.push(mesh);

		if (pos < s.meshVertexCounts.length)
			s.meshVertexCounts[pos] = vc;
		else
			s.meshVertexCounts.push(vc);

		if (pos < s.meshIndexCounts.length)
			s.meshIndexCounts[pos] = ic;
		else
			s.meshIndexCounts.push(ic);

		r = {start: s.indexCount, count: ic};
		s.meshRanges.set(mesh, r);

		s.meshRefCount++;
		s.vertexCount += vc;
		s.indexCount += ic;

		return r;
	}

	inline function ensureBuffers(s:DrawState) {
		if (s == null || s.pipeline == null || s.vertexCount <= 0 || s.indexCount <= 0)
			return;

		var structure = s.pipeline.inputLayout[0];

		if (s.vertexBuffer == null || s.vbCapacity < s.vertexCount) {
			if (s.vertexBuffer != null)
				s.vertexBuffer.delete();

			s.vbCapacity = nextCapacity(s.vertexCount);
			s.vertexBuffer = new VertexBuffer(s.vbCapacity, structure, StaticUsage);
			s.meshDirty = true;

			#if S2D_DEBUG_FPS
			++ vbAllocations;
			#end
		}

		if (s.indexBuffer == null || s.ibCapacity < s.indexCount) {
			if (s.indexBuffer != null)
				s.indexBuffer.delete();

			s.ibCapacity = nextCapacity(s.indexCount);
			s.indexBuffer = new IndexBuffer(s.ibCapacity, StaticUsage);
			s.meshDirty = true;

			#if S2D_DEBUG_FPS
			++ ibAllocations;
			#end
		}

		if (!s.meshDirty)
			return;

		var vert = s.vertexBuffer.lock();
		var ind = s.indexBuffer.lock();
		var fpv = s.vertexBuffer.stride() >> 2;

		var vertexOffset = 0;
		var vertWrite = 0;
		var indWrite = 0;

		for (m in 0...s.meshRefCount) {
			var mesh = s.meshRefs[m];

			for (p in mesh) {
				var n = p.length;
				if (n == 0)
					continue;

				for (v in p) {
					if (v.length != fpv)
						throw 'Vertex size mismatch. Expected $fpv floats, got ${v.length}.';

					for (i in 0...fpv)
						vert[vertWrite + i] = v[i];
					vertWrite += fpv;
				}

				if (n >= 3)
					for (i in 1...n - 1) {
						ind[indWrite++] = vertexOffset;
						ind[indWrite++] = vertexOffset + i;
						ind[indWrite++] = vertexOffset + i + 1;
					}

				vertexOffset += n;
			}
		}

		s.vertexBuffer.unlock();
		s.indexBuffer.unlock();
		s.meshDirty = false;
	}

	inline function hasPendingRecording():Bool
		return recordingDirty && (recordingMesh != null || step.commands.length > 0 || step.instanceCount != null);

	function pushStep(s:DrawState, start:Int, count:Int, instanceCount:Null<Int>, commands:Array<DrawCommand>) {
		if (count == 0 && commands.length == 0)
			return;

		if (commands.length == 0 && count > 0 && instanceCount == null && s.steps.length > 0) {
			var prev = s.steps[s.steps.length - 1];
			if (prev.instanceCount == null && prev.start + prev.count == start) {
				prev.count += count;
				return;
			}
		}

		s.steps.push({
			start: start,
			count: count,
			instanceCount: instanceCount,
			commands: commands
		});
	}

	inline function applyCommand(command:DrawCommand) {
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

	public inline function begin(?mrt:Array<kha.Canvas>) {
		#if S2D_DEBUG_FPS
		beginTime = haxe.Timer.stamp() * 1000;
		#end

		graphics.begin(mrt);

		frameStates.resize(0);
		pipelineUseCounts = new ObjectMap();
		commandStateUseCount = 0;

		resetRecording(true);
	}

	public inline function end() {
		#if S2D_DEBUG_FPS
		var currentCpuTime = haxe.Timer.stamp() * 1000 - beginTime;
		cpuTime += currentCpuTime;
		#end

		if (hasPendingRecording())
			draw();

		for (s in frameStates)
			finalizeFrameState(s);

		try {
			for (s in frameStates) {
				ensureBuffers(s);

				if (s.pipeline != null)
					graphics.setPipeline(s.pipeline);

				if (s.vertexBuffer != null && s.indexBuffer != null) {
					graphics.setIndexBuffer(s.indexBuffer);
					graphics.setVertexBuffer(s.vertexBuffer);
				}

				for (st in s.steps) {
					for (command in st.commands)
						applyCommand(command);

					if (st.count > 0) {
						if (st.instanceCount != null)
							graphics.drawIndexedVerticesInstanced(st.instanceCount, st.start, st.count);
						else
							graphics.drawIndexedVertices(st.start, st.count);

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
		gpuTime += haxe.Timer.stamp() * 1000 - beginTime - currentCpuTime;
		#end
	}

	public inline function drawInstanced(instanceCount:Int, start:Int = 0, count:Int = -1) {
		step.instanceCount = instanceCount;
		draw(start, count);
	}

	public inline function draw(start:Int = 0, count:Int = -1) {
		if (recordingPipeline != null) {
			if (start < 0)
				start = 0;
			if (start > recordingIndexCount)
				start = recordingIndexCount;

			var drawCount = clampCount(start, count, recordingIndexCount);

			var prev = frameStates.length > 0 ? frameStates[frameStates.length - 1] : null;
			var canBatch = prev != null && prev.pipeline == recordingPipeline && step.instanceCount == null;

			var s = canBatch ? prev : acquirePipelineState(recordingPipeline);

			var globalStart = 0;
			if (recordingMesh != null && recordingIndexCount > 0) {
				var range = appendOrGetMeshRange(s, recordingMesh, recordingVertexCount, recordingIndexCount, recordingForceDirty);
				globalStart = range.start + start;
			}

			pushStep(s, globalStart, drawCount, step.instanceCount, step.commands);
		} else if (step.commands.length > 0) {
			var s = acquireCommandState();
			pushStep(s, 0, 0, null, step.commands);
		}

		resetStepOnly();
	}

	public inline function invalidate() {
		recordingForceDirty = true;
		recordingDirty = true;
	}

	public inline function invalidateAllStates() {
		for (pipeline in pipelineStateCache.keys()) {
			var list = pipelineStateCache.get(pipeline);
			if (list != null)
				for (s in list)
					s.meshDirty = true;
		}
	}

	public inline function setPipeline(pipeline:PipelineState) {
		recordingPipeline = pipeline;
		markDirty();
	}

	public inline function setMesh(mesh:Mesh) {
		recordingMesh = mesh;
		recordingVertexCount = meshVertices(mesh);
		recordingIndexCount = meshIndices(mesh);
		markDirty();
	}

	public inline function addCommand(command:DrawCommand) {
		markDirty();
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
