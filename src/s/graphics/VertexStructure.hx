package s.graphics;

import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure as KhaStructure;

@:forward()
@:forward.new
extern abstract VertexStructure(KhaStructure) from KhaStructure to KhaStructure {
	@:from
	public static inline function fromMap(value:Map<String, VertexData>):VertexStructure {
		var structure = new KhaStructure();
		for (data in value.keyValueIterator())
			structure.add(data.key, data.value);
		return structure;
	}
}
