package s2d.elements;

@:genericBuild @:template class Interactive<T:Element> {
	@:attr public var enabled:Bool = true;
	@:attr public var hovered:Bool = false;

	@:signal public function mouseEntered(x:Float, y:Float);

	@:signal public function mouseExited(x:Float, y:Float);

	@:signal public function mouseMoved(m:se.system.input.Mouse.MouseMoveEvent);

	@:signal public function mouseScrolled(m:se.system.input.Mouse.MouseScrollEvent);

	@:signal public function mousePressed(m:se.system.input.Mouse.MouseButtonEvent);

	@:signal public function mouseReleased(m:se.system.input.Mouse.MouseButtonEvent);

	@:signal public function mouseHold(m:se.system.input.Mouse.MouseButtonEvent);

	@:signal public function mouseClicked(m:se.system.input.Mouse.MouseButtonEvent);

	@:signal public function mouseDoubleClicked(m:se.system.input.Mouse.MouseButtonEvent);

	@:signal public function mouseButtonPressed(m:se.system.input.Mouse.MouseButtonEvent);

	@:signal public function mouseButtonReleased(m:se.system.input.Mouse.MouseButtonEvent);

	@:signal public function mouseButtonHold(m:se.system.input.Mouse.MouseButtonEvent);

	@:signal public function mouseButtonClicked(m:se.system.input.Mouse.MouseButtonEvent);

	@:signal public function mouseButtonDoubleClicked(m:se.system.input.Mouse.MouseButtonEvent);

	override function render(target:se.Texture) {
		var m = se.App.input.mouse;
		var mx = m.x;
		var my = m.y;

		var containsMouse = contains(mx, my);
		if (!hovered && containsMouse)
			mouseEntered(mx, my);
		else if (hovered && !containsMouse)
			mouseExited(mx, my);

		flush();
		super.render(target);
	}

	@:slot(mouseEntered)
	function syncMouseEntered(x:Float, y:Float)
		hovered = true;

	@:slot(mouseExited)
	function syncMouseExited(x:Float, y:Float)
		hovered = false;
}
