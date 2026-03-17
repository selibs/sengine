package s.markup.geometry;

import s.system.math.Vec2;

@:forward.new
@:forward(x, y)
extern abstract Position(Vec2) from Vec2 to Vec2 {
	@:to
	private inline function toPositionI():PositionI {
		return PositionI.fromPosition(this);
	}

	@:to
	public inline function toString():String {
		return '(${this.x}, ${this.y})';
	}
}
