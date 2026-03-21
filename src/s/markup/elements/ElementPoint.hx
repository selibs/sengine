package s.markup.elements;

@:structInit
@:allow(s.markup.Element)
class ElementPoint implements s.shortcut.Shortcut {
	@:attr public var x:Length;
	@:attr public var y:Length;
}
