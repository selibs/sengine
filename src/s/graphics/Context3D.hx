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

	steps:Array<DrawStep>,

	streamVerts:Float32Array,
	streamInds:Int32Array,
	streamFloatCount:Int,
	streamVertCount:Int,
	streamIndCount:Int,
	streamVertCap:Int,
	streamIndCap:Int,

	vbCapacity:Int,
	ibCapacity:Int
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
	var recordingForceDirty:Bool = false;
	var recordingDirty:Bool = false;
	var step:DrawStep;
	var recordingStreamState:DrawState;
	var recordingStreamStart:Int = 0;
	var recordingStreamCount:Int = 0;

	#if S2D_DEBUG_FPS
	public static var cpuTime(default, null):Float;
	public static var gpuTime(default, null):Float;
	public static var drawCalls(default, null):Int = 0;
	public static var ibAllocations(default, null):Int = 0;
	public static var vbAllocations(default, null):Int = 0;
	public static var stepCount(default, null):Int = 0;
	public static var commandCount(default, null):Int = 0;
	public static var pipelineBatches(default, null):Int = 0;
	public static var streamVerts(default, null):Int = 0;
	public static var streamInds(default, null):Int = 0;
	public static var ensureMs(default, null):Float = 0;
	public static var commandMs(default, null):Float = 0;
	public static var drawMs(default, null):Float = 0;

	public static function reset() {
		cpuTime = 0;
		gpuTime = 0;
		drawCalls = 0;
		ibAllocations = 0;
		vbAllocations = 0;
		stepCount = 0;
		commandCount = 0;
		pipelineBatches = 0;
		streamVerts = 0;
		streamInds = 0;
		ensureMs = 0;
		commandMs = 0;
		drawMs = 0;
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
			steps: [],
			streamVerts: null,
			streamInds: null,
			streamFloatCount: 0,
			streamVertCount: 0,
			streamIndCount: 0,
			streamVertCap: 0,
			streamIndCap: 0,
			vbCapacity: 0,
			ibCapacity: 0
		};

	inline function resetRecording(full:Bool = false) {
		if (full) {
			recordingPipeline = null;
			recordingMesh = null;
			recordingStreamState = null;
			recordingStreamStart = 0;
			recordingStreamCount = 0;
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

	inline function ensureStreamCapacity(s:DrawState, addVerts:Int, addFloats:Int, addInds:Int) {
		var needFloats = s.streamFloatCount + addFloats;
		if (s.streamVerts == null || s.streamVertCap < needFloats) {
			var newCap = nextCapacity(needFloats);
			var next = new Float32Array(newCap);
			if (s.streamVerts != null)
				for (i in 0...s.streamFloatCount)
					next[i] = s.streamVerts[i];
			s.streamVerts = next;
			s.streamVertCap = newCap;
		}

		var needInds = s.streamIndCount + addInds;
		if (s.streamInds == null || s.streamIndCap < needInds) {
			var newCap = nextCapacity(needInds);
			var next = new Int32Array(newCap);
			if (s.streamInds != null)
				for (i in 0...s.streamIndCount)
					next[i] = s.streamInds[i];
			s.streamInds = next;
			s.streamIndCap = newCap;
		}
	}

	inline function prepareFrameState(s:DrawState) {
		s.streamFloatCount = 0;
		s.streamVertCount = 0;
		s.streamIndCount = 0;
		s.steps.resize(0);
	}

	inline function finalizeFrameState(s:DrawState) {}

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

	function appendMeshToStream(s:DrawState, mesh:Mesh):MeshRange {
		var start = s.streamIndCount;
		if (mesh == null)
			return {start: start, count: 0};

		var addVerts = 0;
		var addFloats = 0;
		var addInds = 0;
		for (p in mesh) {
			var n = p.length;
			addVerts += n;
			if (n >= 3)
				addInds += (n - 2) * 3;
			for (v in p)
				addFloats += v.length;
		}

		ensureStreamCapacity(s, addVerts, addFloats, addInds);

		var verts = s.streamVerts;
		var inds = s.streamInds;
		var floatWrite = s.streamFloatCount;
		var indWrite = s.streamIndCount;
		var vertexOffset = s.streamVertCount;

		for (p in mesh) {
			var n = p.length;
			if (n == 0)
				continue;

			var polyStart = vertexOffset;
			for (v in p) {
				for (i in 0...v.length)
					verts[floatWrite++] = v[i];
				vertexOffset++;
			}

			if (n >= 3) {
				for (i in 1...n - 1) {
					inds[indWrite++] = polyStart;
					inds[indWrite++] = polyStart + i;
					inds[indWrite++] = polyStart + i + 1;
				}
			}
		}

		s.streamFloatCount = floatWrite;
		s.streamVertCount = vertexOffset;
		s.streamIndCount = indWrite;

		return {start: start, count: indWrite - start};
	}

	inline function ensureBuffers(s:DrawState) {
		if (s == null || s.pipeline == null || s.streamVertCount <= 0 || s.streamIndCount <= 0)
			return;

		var structure = s.pipeline.inputLayout[0];

		if (s.vertexBuffer == null || s.vbCapacity < s.streamVertCount) {
			if (s.vertexBuffer != null)
				s.vertexBuffer.delete();

			s.vbCapacity = nextCapacity(s.streamVertCount);
			s.vertexBuffer = new VertexBuffer(s.vbCapacity, structure, DynamicUsage);

			#if S2D_DEBUG_FPS
			++ vbAllocations;
			#end
		}

		if (s.indexBuffer == null || s.ibCapacity < s.streamIndCount) {
			if (s.indexBuffer != null)
				s.indexBuffer.delete();

			s.ibCapacity = nextCapacity(s.streamIndCount);
			s.indexBuffer = new IndexBuffer(s.ibCapacity, DynamicUsage);

			#if S2D_DEBUG_FPS
			++ ibAllocations;
			#end
		}

		var vert = s.vertexBuffer.lock();
		var ind = s.indexBuffer.lock();

		var floatCount = s.streamFloatCount;
		for (i in 0...floatCount)
			vert[i] = s.streamVerts[i];

		var indCount = s.streamIndCount;
		for (i in 0...indCount)
			ind[i] = s.streamInds[i];

		s.vertexBuffer.unlock();
		s.indexBuffer.unlock();
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

		#if S2D_DEBUG_FPS
		var localSteps = 0;
		var localCommands = 0;
		var localPipelines = frameStates.length;
		var localStreamVerts = 0;
		var localStreamInds = 0;
		var localEnsureMs = 0.0;
		var localCommandMs = 0.0;
		var localDrawMs = 0.0;
		#end

		for (s in frameStates)
			finalizeFrameState(s);

		try {
			for (s in frameStates) {
				#if S2D_DEBUG_FPS
				localSteps += s.steps.length;
				localStreamVerts += s.streamVertCount;
				localStreamInds += s.streamIndCount;
				var tEnsure = haxe.Timer.stamp() * 1000;
				#end
				ensureBuffers(s);
				#if S2D_DEBUG_FPS
				localEnsureMs += haxe.Timer.stamp() * 1000 - tEnsure;
				#end

				if (s.pipeline != null)
					graphics.setPipeline(s.pipeline);

				if (s.vertexBuffer != null && s.indexBuffer != null) {
					graphics.setIndexBuffer(s.indexBuffer);
					graphics.setVertexBuffer(s.vertexBuffer);
				}

				for (st in s.steps) {
					#if S2D_DEBUG_FPS
					localCommands += st.commands.length;
					var tCommands = haxe.Timer.stamp() * 1000;
					#end
					for (command in st.commands)
						applyCommand(command);
					#if S2D_DEBUG_FPS
					localCommandMs += haxe.Timer.stamp() * 1000 - tCommands;
					#end

					if (st.count > 0) {
						#if S2D_DEBUG_FPS
						var tDraw = haxe.Timer.stamp() * 1000;
						#end
						if (st.instanceCount != null)
							graphics.drawIndexedVerticesInstanced(st.instanceCount, st.start, st.count);
						else
							graphics.drawIndexedVertices(st.start, st.count);

						#if S2D_DEBUG_FPS
						++ drawCalls;
						localDrawMs += haxe.Timer.stamp() * 1000 - tDraw;
						#end
					}
				}
			}
			#if S2D_DEBUG_FPS
			stepCount += localSteps;
			commandCount += localCommands;
			pipelineBatches += localPipelines;
			streamVerts += localStreamVerts;
			streamInds += localStreamInds;
			ensureMs += localEnsureMs;
			commandMs += localCommandMs;
			drawMs += localDrawMs;
			#end
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

	public function draw(start:Int = 0, count:Int = -1) {
		if (recordingStreamCount > 0 && recordingStreamState != null) {
			pushStep(recordingStreamState, recordingStreamStart, recordingStreamCount, step.instanceCount, step.commands);
			recordingStreamState = null;
			recordingStreamStart = 0;
			recordingStreamCount = 0;
			resetStepOnly();
			return;
		}

		if (recordingPipeline != null) {
			if (recordingMesh == null && step.commands.length > 0) {
				var s = acquireCommandState();
				pushStep(s, 0, 0, null, step.commands);
				resetStepOnly();
				return;
			}

			var prev = frameStates.length > 0 ? frameStates[frameStates.length - 1] : null;
			var canBatch = prev != null && prev.pipeline == recordingPipeline && step.instanceCount == null;

			var s = canBatch ? prev : acquirePipelineState(recordingPipeline);

			var globalStart = 0;
			var drawCount = 0;
			if (recordingMesh != null) {
				var range = appendMeshToStream(s, recordingMesh);
				var total = range.count;
				if (start < 0)
					start = 0;
				if (start > total)
					start = total;
				drawCount = clampCount(start, count, total);
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
		// no-op in streaming mode
	}

	public inline function setPipeline(pipeline:PipelineState) {
		recordingPipeline = pipeline;
		markDirty();
	}

	public inline function setMesh(mesh:Mesh) {
		recordingMesh = mesh;
		markDirty();
	}

	public inline function streamQuad(x0:Float, y0:Float, u0:Float, v0:Float, x1:Float, y1:Float, u1:Float, v1:Float, x2:Float, y2:Float, u2:Float, v2:Float,
			x3:Float, y3:Float, u3:Float, v3:Float) {
		var prev = frameStates.length > 0 ? frameStates[frameStates.length - 1] : null;
		var canBatch = prev != null && prev.pipeline == recordingPipeline && step.instanceCount == null;
		var s = canBatch ? prev : acquirePipelineState(recordingPipeline);

		ensureStreamCapacity(s, 4, 16, 6);

		var verts = s.streamVerts;
		var inds = s.streamInds;
		var floatWrite = s.streamFloatCount;
		var indWrite = s.streamIndCount;
		var vertexOffset = s.streamVertCount;

		verts[floatWrite] = x0;
		verts[floatWrite + 1] = y0;
		verts[floatWrite + 2] = u0;
		verts[floatWrite + 3] = v0;
		verts[floatWrite + 4] = x1;
		verts[floatWrite + 5] = y1;
		verts[floatWrite + 6] = u1;
		verts[floatWrite + 7] = v1;
		verts[floatWrite + 8] = x2;
		verts[floatWrite + 9] = y2;
		verts[floatWrite + 10] = u2;
		verts[floatWrite + 11] = v2;
		verts[floatWrite + 12] = x3;
		verts[floatWrite + 13] = y3;
		verts[floatWrite + 14] = u3;
		verts[floatWrite + 15] = v3;

		inds[indWrite++] = vertexOffset;
		inds[indWrite++] = vertexOffset + 1;
		inds[indWrite++] = vertexOffset + 2;
		inds[indWrite++] = vertexOffset;
		inds[indWrite++] = vertexOffset + 2;
		inds[indWrite++] = vertexOffset + 3;

		s.streamFloatCount = floatWrite + 16;
		s.streamVertCount = vertexOffset + 4;
		s.streamIndCount = indWrite;

		if (recordingStreamState != s || recordingStreamCount == 0) {
			recordingStreamState = s;
			recordingStreamStart = indWrite - 6;
			recordingStreamCount = 6;
		} else {
			recordingStreamCount += 6;
		}

		markDirty();
	}

	public inline function streamTri(x0:Float, y0:Float, u0:Float, v0:Float, x1:Float, y1:Float, u1:Float, v1:Float, x2:Float, y2:Float, u2:Float, v2:Float) {
		var prev = frameStates.length > 0 ? frameStates[frameStates.length - 1] : null;
		var canBatch = prev != null && prev.pipeline == recordingPipeline && step.instanceCount == null;
		var s = canBatch ? prev : acquirePipelineState(recordingPipeline);

		ensureStreamCapacity(s, 3, 12, 3);

		var verts = s.streamVerts;
		var inds = s.streamInds;
		var floatWrite = s.streamFloatCount;
		var indWrite = s.streamIndCount;
		var vertexOffset = s.streamVertCount;

		verts[floatWrite] = x0;
		verts[floatWrite + 1] = y0;
		verts[floatWrite + 2] = u0;
		verts[floatWrite + 3] = v0;
		verts[floatWrite + 4] = x1;
		verts[floatWrite + 5] = y1;
		verts[floatWrite + 6] = u1;
		verts[floatWrite + 7] = v1;
		verts[floatWrite + 8] = x2;
		verts[floatWrite + 9] = y2;
		verts[floatWrite + 10] = u2;
		verts[floatWrite + 11] = v2;

		inds[indWrite++] = vertexOffset;
		inds[indWrite++] = vertexOffset + 1;
		inds[indWrite++] = vertexOffset + 2;

		s.streamFloatCount = floatWrite + 12;
		s.streamVertCount = vertexOffset + 3;
		s.streamIndCount = indWrite;

		if (recordingStreamState != s || recordingStreamCount == 0) {
			recordingStreamState = s;
			recordingStreamStart = indWrite - 3;
			recordingStreamCount = 3;
		} else {
			recordingStreamCount += 3;
		}

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
