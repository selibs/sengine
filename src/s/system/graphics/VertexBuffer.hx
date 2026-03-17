package s.system.graphics;

import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer as KhaBuffer;

@:forward()
extern abstract VertexBuffer(KhaBuffer) from KhaBuffer to KhaBuffer {
	public inline function new(vertexCount:Int, structure:VertexStructure, usage:Usage, instanceDataStepRate:Int = 0, canRead:Bool = false) {
		this = new KhaBuffer(vertexCount, structure, usage, instanceDataStepRate, canRead);
	}
}
