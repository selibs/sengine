package s2d.elements;

import se.math.SMath;

class Flickable extends Element {
	var contentItem:Element;

	public var shiftX(get, set):Float;
	public var shiftY(get, set):Float;

	@alias public var contentWidth:Float = contentItem.width;
	@alias public var contentHeight:Float = contentItem.height;

	public function new(name:String = "flickable") {
		super(name);
		clip = true;

		addChild({
			contentItem = new Element();
			contentItem;
		});
	}

	@:slot(childAdded)
	function __syncChildAdded__(child:Element) {
		contentItem.addChild(child);
	}

	function get_shiftX():Float {
		return contentItem.translationX;
	}

	function set_shiftX(value:Float):Float {
		contentItem.translationX = clamp(value, width - contentWidth, 0.0);
		return value;
	}

	function get_shiftY():Float {
		return contentItem.translationY;
	}

	function set_shiftY(value:Float):Float {
		contentItem.translationY = clamp(value, height - contentHeight, 0.0);
		return value;
	}
}
