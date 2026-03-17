package s.markup;

enum abstract FocusPolicy(Int) from Int to Int {
	var NoFocus = 0;
	var TabFocus = 1;
	var ClickFocus = 2;
	var WheelFocus = 4;
}
