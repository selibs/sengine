package s.ui.controls;

import s.ui.elements.Label;
import s.ui.elements.Control;
import s.ui.shapes.Rectangle;

class Button extends Control<Rectangle, Label> {
	@:alias extern public var text:String = content.text;

	public function new(?text:String) {
		super(new Rectangle(), new Label(text));
		cursor = Pointer;
	}
}
