package s.markup.stage.objects;

class StageObject extends s.markup.Object2D<StageObject> {
	@:alias public var x:Float = this.transform.translationX;
	@:alias public var y:Float = this.transform.translationY;
}
