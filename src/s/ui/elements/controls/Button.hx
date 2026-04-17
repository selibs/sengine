package s.ui.elements.controls;

import s.ui.elements.positioners.Row;
import s.ui.elements.shapes.Rectangle;

class Button extends Control {
	public final icon:ImageElement;
	public final label:Label;

	public function new(?text:String) {
		super(new Rectangle(), new Row());
		content.addChild(icon = new ImageElement());
		content.addChild(label = new Label(text));
	}
}
