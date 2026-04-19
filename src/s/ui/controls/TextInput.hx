package s.ui.controls;

import s.ui.elements.Label;
import s.ui.elements.Control;
import s.ui.shapes.Rectangle;

class TextInput extends Control<Rectangle, Label> {
    public function new() {
        super(new Rectangle(), new Label());
    }
}
