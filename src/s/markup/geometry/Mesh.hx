package s.markup.geometry;

import haxe.ds.Vector;
import s.math.Vec2;

@:forward(length)
extern abstract Mesh(Vector<Vec2>) {
	public inline function new(value:Vector<Vec2>) {
		this = value;
	}

	@:from
	public static inline function fromArray(value:Array<Vec2>) {
		var v = new Vector(value.length);
		for (i in 0...value.length)
			v[i] = value[i];
		return new Mesh(v);
	}

	public inline function iterator() {
		return this.toData().iterator();
	}
}
