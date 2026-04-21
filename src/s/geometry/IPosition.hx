package s.geometry;

import s.math.IVec2;

@:forward.new
@:forward(x, y)
extern abstract IPosition(IVec2) from IVec2 to IVec2 {
	@:from
	public static inline function fromPosition(value:Position):IPosition
		return new IPosition(Std.int(value.x), Std.int(value.y));

	@:to
	public inline function toString():String
		return '(${this.x}, ${this.y})';

	@:to
	private inline function toPosition():Position
		return new Position(this.x, this.y);
}
