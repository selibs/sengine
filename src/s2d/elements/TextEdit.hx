package s2d.elements;

import se.App;
import se.Timer;
import se.Color;
import se.Texture;
import se.system.input.Keyboard;

using se.extensions.StringExt;

@:ui.shortcut(edit)
class TextEdit extends Text {
	var _cursorVisible:Bool = false;
	var _selecting = false;
	var _selectionStart = 0;
	var _selectionEnd = 0;
	var keysHold:Array<KeyCode> = [];

	var undoStack:Array<String> = [];
	var redoStack:Array<String> = [];
	var cursorX:Float = 0.0;

	public var canPaste:Bool = true;
	public var canUndo:Bool = true;
	public var canRedo:Bool = true;

	public var selectionStart:Int = 0;
	public var selectionEnd:Int = 0;
	public var selectionColor:Color = 0xFF3399FF;
	public var selectedTextColor:Color = White;

	public var cursorVisible:Bool = true;
	public var cursorColor:Color = Black;
	public var cursorWidth:Float = 2.0;
	@:isVar public var cursorPosition(default, set):Int = 0;

	public var placeholder:String;
	public var placeholderColor:Color = 0x44000000;

	public function new(text:String = "", placeholder:String = "Text", name:String = "textEdit") {
		super(text, name);
		this.placeholder = placeholder;

		onMouseButtonPressed(Left, m -> {
			cursorPosition = posAt(m.x);
			_selectionStart = selectionStart;
			_selectionEnd = selectionEnd;
			_selecting = true;
		});
		onMouseButtonReleased(Left, m -> _selecting = false);
		onMouseEntered((x, y) -> App.input.mouse.cursor = Text);
		onMouseExited((x, y) -> App.input.mouse.cursor = Default);
		onMouseMoved(m -> if (_selecting) adjustSelection(posAt(m.x)));
		onMouseButtonDoubleClicked(Left, m -> {
			var i = posAt(m.x);
			var start = i - 1;
			while (start > 0 && ~/[\w]/.match(text.charAt(start - 1)))
				start--;
			var end = i;
			while (end < text.length && ~/[\w]/.match(text.charAt(end)))
				end++;
			selectionStart = start;
			selectionEnd = end;
		});
		App.input.keyboard.onHotkeyPressed([Control, A], () -> if (focused) {
			cursorPosition = text.length;
			selectionStart = 0;
			selectionEnd = text.length;
		});
	}

	public function cut() {
		var part = copy();
		replace("");
		return part;
	}

	public function copy() {
		return text.substring(selectionStart, selectionEnd);
	}

	public function paste(text:String) {
		if (canPaste)
			replace(text);
	}

	public function undo() {
		if (canUndo && undoStack.length > 0) {
			text = undoStack.pop();
			redoStack.push(undoStack.pop());
		}
	}

	public function redo() {
		if (canRedo && redoStack.length > 0)
			text = redoStack.shift();
	}

	public function posAt(x:Float) @:privateAccess {
		var i = 0;
		if (kravur != null) {
			x -= textX;
			var s = 0.0;
			var k = kravur._get(fontSize);
			while (i < text.length) {
				var c = k.getCharWidth(text.charCodeAt(i++));
				if (s + c >= x) {
					if (s + c * 0.5 >= x)
						--i;
					break;
				}
				s += c;
			}
		}
		return i;
	}

	function adjustSelection(i:Int) {
		cursorPosition = i;
		selectionStart = i < _selectionStart ? i : _selectionStart;
		selectionEnd = i > _selectionStart ? i : _selectionEnd;
	}

	@:slot(focusedChanged)
	function onFocused(_:Bool) {
		if (focused) {
			App.onUndo(undo);
			App.onRedo(redo);
			App.onCutCopyPaste(cut, copy, paste);
			function tick()
				if (focused) {
					_cursorVisible = !_cursorVisible && cursorVisible;
					Timer.set(tick, 0.5);
				}
			tick();
		} else
			_cursorVisible = false;
	}

	@:slot(keyboardDown)
	function onKeyDown(key:KeyCode) {
		switch key {
			case Backspace:
				replace("", -1);
			case Delete:
				replace("", 0, 1);
			case Space:
				replace(" ");
			case Shift:
				_selecting = true;
			case Left:
				if (_selecting)
					adjustSelection(cursorPosition - 1);
				else
					--cursorPosition;
			case Right:
				if (_selecting)
					adjustSelection(cursorPosition + 1);
				else
					++cursorPosition;
			default:
		}
	}

	@:slot(keyboardUp)
	function onKeyUp(key:KeyCode) {
		keysHold.remove(key);
		switch key {
			case Shift:
				_selecting = false;
			default:
		}
	}

	@:slot(keyboardHold)
	function onKeyHold(key:KeyCode) {
		function tick()
			if (keysHold.contains(key)) {
				onKeyDown(key);
				Timer.set(tick, 0.01);
			}
		keysHold.push(key);
		tick();
	}

	@:slot(keyboardPressed)
	function onChar(char:String) {
		replace(char);
	}

	function replace(char:String, loffset:Int = 0, roffset:Int = 0) {
		if (selectionStart != selectionEnd) {
			text = text.substr(0, selectionStart) + char + text.substr(selectionEnd);
			cursorPosition = selectionStart + char.length;
		} else {
			text = text.substr(0, cursorPosition + loffset) + char + text.substr(cursorPosition + roffset);
			cursorPosition += loffset + char.length;
		}
	}

	override function draw(target:Texture) {
		if (fontAsset.isLoaded) {
			final ctx = target.context2D;
			ctx.style.font = kravur;
			ctx.style.fontSize = fontSize;

			if (text != null && text != "") {
				ctx.style.color = color;
				if (focused) {
					var part1 = text.substring(0, selectionStart);
					var offsetX = textX + kravur.width(fontSize, part1);
					ctx.drawString(part1, textX, textY);

					// selection
					var selection = text.substring(selectionStart, selectionEnd);
					var selectionWidth = kravur.width(fontSize, selection);
					ctx.style.color = selectionColor;
					ctx.fillRect(offsetX, textY, selectionWidth, fontSize);

					ctx.style.color = selectedTextColor;
					ctx.drawString(selection, offsetX, textY);
					offsetX += selectionWidth;

					var part2 = text.substring(selectionEnd);
					ctx.style.color = color;
					ctx.drawString(part2, offsetX, textY);
				} else
					ctx.drawString(text, textX, textY);
			} else if (placeholder != null && placeholder != "") {
				ctx.style.color = placeholderColor;
				ctx.drawString(placeholder, textX, textY);
			}

			// cursor
			if (_cursorVisible) {
				ctx.style.color = cursorColor;
				ctx.fillRect(textX + cursorX, textY, cursorWidth, fontSize);
			}
		}
	}

	function set_cursorPosition(value:Int):Int {
		cursorPosition = selectionStart = selectionEnd = value >= 0 ? (value < text.length ? value : text.length) : 0;
		cursorX = kravur.width(fontSize, text.substring(0, cursorPosition)) - cursorWidth;
		_cursorVisible = cursorVisible;
		return cursorPosition;
	}

	override function set_text(value:String):String {
		undoStack.push(text);
		redoStack = [];
		return super.set_text(value);
	}
}
