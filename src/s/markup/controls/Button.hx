// package s.markup.controls;

// import s.markup.elements.Text;
// import s.markup.layouts.HBoxLayout;
// import s.markup.elements.shapes.Rectangle;

// class Button extends AbstractButton<Rectangle, HBoxLayout> {
// 	public var label:Text;

// 	@:alias public var text:String = label.text;

// 	public function new(text:String = "Button") {
// 		super();

// 		background = new Rectangle();
// 		background.color = Color.rgb(0.75, 0.75, 0.75);
// 		onHoveredChanged((_) -> if (!pressed) {
// 			background.color = hovered ? Color.rgb(0.85, 0.85, 0.85) : Color.rgb(0.75, 0.75, 0.75);
// 		});
// 		onPressedChanged((_) -> {
// 			background.color = pressed ? Color.rgb(0.55, 0.55, 0.55) : Color.rgb(0.75, 0.75, 0.75);
// 		});

// 		content = new HBoxLayout();
// 		content.addChild({
// 			label = new Text(text);
// 			label.layout.fillWidth = true;
// 			label.layout.fillHeight = true;
// 			label.color = Black;
// 			label.alignment = AlignCenter;
// 			label;
// 		});
// 	}
// }
