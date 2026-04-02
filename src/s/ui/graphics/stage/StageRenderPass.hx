package s.ui.graphics.stage;

import s.graphics.shaders.Shader;
import s.ui.stage.Stage;

@:dox(hide)
abstract class StageRenderPass extends Shader {
	abstract function render(stage:Stage):Void;
}
