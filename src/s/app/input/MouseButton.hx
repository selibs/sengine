package s.app.input;

extern enum abstract MouseButton(Int) from Int to Int {
	@:from
	public static inline function fromString(value:String)
		return switch value?.toLowerCase() ?? "" {
			case "left": Left;
			case "right": Right;
			case "middle": Middle;
			case "back": Back;
			case "forward": Forward;
			case "any": Any;
			case _: null;
		}

	var Left = 1 << 0;
	var Right = 1 << 1;
	var Middle = 1 << 2;
	var Back = 1 << 3;
	var Forward = 1 << 4;
	var Any = Left | Right | Middle | Back | Forward;

	public inline function matches(value:MouseButton)
		return this & value != 0;

	@:to
	public inline function toString():String
		return switch this {
			case Left: "Left";
			case Right: "Right";
			case Middle: "Middle";
			case Back: "Back";
			case Forward: "Forward";
			default: 'MouseButton(${(this : Int)})';
		}
}
