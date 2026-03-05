package s2d.controls;

import s2d.elements.TextEdit;
import s2d.elements.shapes.RoundedRectangle;

class TextInput extends AbstractButton<RoundedRectangle, TextEdit> {
	@alias public var text:String = content.text;

	public function new(text:String = "", name:String = "textInput") {
		super(name);
		background = new RoundedRectangle();
		content = new TextEdit(text);
	}
}
