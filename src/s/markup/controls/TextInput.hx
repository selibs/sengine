package s.markup.controls;

import s.markup.elements.TextEdit;
import s.markup.elements.shapes.RectangleRounded;

class TextInput extends AbstractButton<RectangleRounded, TextEdit> {
	@:alias public var text:String = content.text;

	public function new(text:String = "") {
		super();
		background = new RectangleRounded();
		content = new TextEdit(text);
	}
}
