package s.markup.graphics.stage;

import s.graphics.shaders.Shader;
import s.markup.stage.Stage;

@:dox(hide)
abstract class StageRenderPass extends Shader {
	abstract function render(stage:Stage):Void;
}
