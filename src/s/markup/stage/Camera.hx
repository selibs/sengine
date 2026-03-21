package s.markup.stage;

import s.math.Mat3;
import s.math.SMath;
import s.markup.stage.objects.StageObject;

@:allow(s.markup.stage.Stage)
class Camera extends StageObject {
	var view:Mat3 = Mat3.lookAt(vec2(0.0, 0.0), vec2(0.0, -1.0), vec2(0.0, 1.0));

	public function new() {
		super();
	}
}
