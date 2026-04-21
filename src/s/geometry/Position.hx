package s.geometry;

import s.math.Vec2;

@:forward.new
@:forward(x, y)
extern abstract Position(Vec2) from Vec2 to Vec2 {
	@:to
	private inline function toPositionI():IPosition
		return IPosition.fromPosition(this);

	@:to
	public inline function toString():String
		return '(${this.x}, ${this.y})';
}
