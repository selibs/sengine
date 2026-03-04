package s2d.stage.objects;

abstract class LayerObject extends StageObject {
	@:isVar public var layer(default, set):StageLayer;

	public function addToLayer(layer:StageLayer) {
		this.layer = layer;
	}

	abstract function set_layer(value:StageLayer):StageLayer;
}
