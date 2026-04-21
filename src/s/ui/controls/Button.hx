package s.ui.controls;

import s.ui.elements.Label;
import s.ui.elements.Control;
import s.ui.elements.ImageElement;
import s.ui.shapes.Rectangle;
import s.ui.positioners.Row;

class Button extends Control<Rectangle, Row> {
	public final icon:ImageElement;
	public final label:Label;

	@:alias extern public var text:String = label.text;

	public function new(?text:String) {
		super(new Rectangle(), new Row());
		cursor = Pointer;
		content.addChild(icon = new ImageElement());
		content.addChild(label = new Label(text));
	}
}
