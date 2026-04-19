package s.ui;

extern enum abstract FocusPolicy(Int) from Int to Int {
	var NoFocus = 0;
	var TabFocus = 1 << 0;
	var PointerFocus = 1 << 1;
	var InputFocus = TabFocus | PointerFocus;
	var WheelFocus = InputFocus | 1 << 2;

	public inline function matches(value:FocusPolicy)
		return this & value == value;
}
