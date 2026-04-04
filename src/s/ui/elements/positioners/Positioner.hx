package s.ui.elements.positioners;

abstract class Positioner extends ContainerElement {
	var flowIsDirty:Bool = false;

	@:attr public var direction:Direction;
	@:attr public var spacing:Float = 10.0;

	public function new(direction:Direction) {
		super();
		this.direction = direction;
	}

	override function syncTree() {
		if (!isDirty)
			return;
		sync();
		syncFlow();
		flush();
	}

	abstract function syncFlow():Void;

	override function insertChild(child:Element) {
		super.insertChild(child);
		flowIsDirty = true;
	}

	override function __childRemoved__(child:Element) {
		super.__childRemoved__(child);
		flowIsDirty = true;
	}
}
