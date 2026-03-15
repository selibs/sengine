package s2d.controls;

import s2d.elements.TextEdit;
import s2d.elements.shapes.RectangleRounded;

class TextInput extends AbstractButton<RectangleRounded, TextEdit> {
	@:alias public var text:String = content.text;

	public function new(text:String = "") {
		super();
		background = new RectangleRounded();
		content = new TextEdit(text);
	}
}
