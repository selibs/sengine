package s2d;

import haxe.Constraints;

class ElementTreeBuilder {
	var stack:Array<Element> = [];

	public var element(default, null):Element;

	public function new(element:Element) {
		this.element = element;
		stack.push(element);
	}

	@:generic
	public function openElement<T:Constructible<Void->Void> & Element>(cls:Class<T>) {
		var e = new T();
		element.addChild(e);
		element = e;
	}

	public function closeElement() {
		stack.pop();
		element = stack[stack.length - 1];
	}
}
