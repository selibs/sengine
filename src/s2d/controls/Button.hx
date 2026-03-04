package s2d.controls;

import s2d.elements.Text;
import s2d.layouts.HBoxLayout;
import s2d.elements.shapes.RoundedRectangle;

@:ui.shortcut(button)
class Button extends AbstractButton<RoundedRectangle, HBoxLayout> {
	public var label:Text;

	@alias public var text:String = label.text;

	public function new(text:String = "Button", name:String = "button") {
		super(name);

		background = new RoundedRectangle();
		background.color = Color.rgb(0.75, 0.75, 0.75);
		onHoveredChanged((_) -> if (!pressed) {
			background.color = hovered ? Color.rgb(0.85, 0.85, 0.85) : Color.rgb(0.75, 0.75, 0.75);
		});
		onPressedChanged((_) -> {
			background.color = pressed ? Color.rgb(0.55, 0.55, 0.55) : Color.rgb(0.75, 0.75, 0.75);
		});

		content = new HBoxLayout();
		content.addChild({
			label = new Text(text);
			label.layout.fillWidth = true;
			label.layout.fillHeight = true;
			label.color = Black;
			label.alignment = AlignCenter;
			label;
		});
	}
}
