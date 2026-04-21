package s.app.input;

import s.app.input.KeyCode;

using s.extensions.ArrayExt;
using s.extensions.StringExt;

final HelpContents:Shortcut = "F1";
final WhatsThis:Shortcut = "Shift+F1";
final Open:Shortcut = "Ctrl+O";
final Close:Shortcut = "Ctrl+F4, Ctrl+W";
final Save:Shortcut = "Ctrl+S";
final Quit:Shortcut = "";
final SaveAs:Shortcut = "Ctrl+Shift+S";
final New:Shortcut = "Ctrl+N";
final Delete:Shortcut = "Del";
final Cut:Shortcut = "Ctrl+X, Shift+Del";
final Copy:Shortcut = "Ctrl+C, Ctrl+Ins";
final Paste:Shortcut = "Ctrl+V, Shift+Ins";
final Preferences:Shortcut = "";
final Undo:Shortcut = "Ctrl+Z, Alt+Backspace";
final Redo:Shortcut = "Ctrl+Y, Shift+Ctrl+Z, Alt+Shift+Backspace";
final Back:Shortcut = "Alt+Left, Backspace";
final Forward:Shortcut = "Alt+Right, Shift+Backspace";
final Refresh:Shortcut = "F5";
final ZoomIn:Shortcut = "Ctrl+Plus";
final ZoomOut:Shortcut = "Ctrl+Minus";
final FullScreen:Shortcut = "F11, Alt+Enter";
final Print:Shortcut = "Ctrl+P";
final AddTab:Shortcut = "Ctrl+T";
final NextChild:Shortcut = "Ctrl+Tab, Forward, Ctrl+F6";
final PreviousChild:Shortcut = "Ctrl+Shift+Tab, Back, Ctrl+Shift+F6";
final Find:Shortcut = "Ctrl+F";
final FindNext:Shortcut = "F3, Ctrl+G";
final FindPrevious:Shortcut = "Shift+F3, Ctrl+Shift+G";
final Replace:Shortcut = "Ctrl+H";
final SelectAll:Shortcut = "Ctrl+A";
final Deselect:Shortcut = "";
final Bold:Shortcut = "Ctrl+B";
final Italic:Shortcut = "Ctrl+I";
final Underline:Shortcut = "Ctrl+U";
final MoveToNextChar:Shortcut = "Right";
final MoveToPreviousChar:Shortcut = "Left";
final MoveToNextWord:Shortcut = "Ctrl+Right";
final MoveToPreviousWord:Shortcut = "Ctrl+Left";
final MoveToNextLine:Shortcut = "Down";
final MoveToPreviousLine:Shortcut = "Up";
final MoveToNextPage:Shortcut = "PgDown";
final MoveToPreviousPage:Shortcut = "PgUp";
final MoveToStartOfLine:Shortcut = "Home";
final MoveToEndOfLine:Shortcut = "End";
final MoveToStartOfBlock:Shortcut = "";
final MoveToEndOfBlock:Shortcut = "";
final MoveToStartOfDocument:Shortcut = "Ctrl+Home";
final MoveToEndOfDocument:Shortcut = "Ctrl+End";
final SelectNextChar:Shortcut = "Shift+Right";
final SelectPreviousChar:Shortcut = "Shift+Left";
final SelectNextWord:Shortcut = "Ctrl+Shift+Right";
final SelectPreviousWord:Shortcut = "Ctrl+Shift+Left";
final SelectNextLine:Shortcut = "Shift+Down";
final SelectPreviousLine:Shortcut = "Shift+Up";
final SelectNextPage:Shortcut = "Shift+PgDown";
final SelectPreviousPage:Shortcut = "Shift+PgUp";
final SelectStartOfLine:Shortcut = "Shift+Home";
final SelectEndOfLine:Shortcut = "Shift+End";
final SelectStartOfBlock:Shortcut = "";
final SelectEndOfBlock:Shortcut = "";
final SelectStartOfDocument:Shortcut = "Ctrl+Shift+Home";
final SelectEndOfDocument:Shortcut = "Ctrl+Shift+End";
final DeleteStartOfWord:Shortcut = "Ctrl+Backspace";
final DeleteEndOfWord:Shortcut = "Ctrl+Del";
final DeleteEndOfLine:Shortcut = "";
final DeleteCompleteLine:Shortcut = "";
final InsertParagraphSeparator:Shortcut = "Enter";
final InsertLineSeparator:Shortcut = "Shift+Enter";
final Backspace:Shortcut = "Backspace";
final Cancel:Shortcut = "Escape";

@:forward
extern abstract Hotkey(HotkeyData) {
	@:from
	public static inline function fromString(value:String):Hotkey
		return fromArray(value?.split("+").map(k -> (k : KeyCode)));

	@:from
	public static inline function fromArray(value:Array<KeyCode>):Hotkey
		return value == null || value.length <= 0 ? null : new Hotkey(value.last(), value.splice(0, value.length - 1));

	public inline function new(key:KeyCode, ?modifiers:Array<KeyCode>)
		if (key == null || key.isModifier)
			this = null;
		else {
			var mod = [];
			var valid = true;
			for (m in modifiers ?? []) {
				if (m == null || !m.isModifier) {
					valid = false;
					break;
				}
				if (!mod.contains(m))
					mod.push(m);
			}
			this = valid ? {key: key, modifiers: mod} : null;
		}

	@:op(a == b)
	public inline function equals(b:Hotkey) {
		if (this.key != b.key || this.modifiers.length != b.modifiers.length)
			return false;

		var eq = true;
		for (m in this.modifiers)
			if (!b.modifiers.contains(m)) {
				eq = false;
				break;
			}

		return eq;
	}

	@:op(a != b)
	public inline function notEquals(b:Hotkey)
		return !equals(b);

	@:to
	public inline function toString():String
		return '[${this.modifiers.concat([this.key]).map(k -> k.toString()).join("+")}]';
}

extern abstract Shortcut(Array<Hotkey>) {
	@:from
	public static inline function fromString(value:String):Shortcut
		return fromArray(value?.replace(";", ",").split(",").map(v -> (v : Hotkey)));

	@:from
	public static inline function fromArray(value:Array<Hotkey>):Shortcut
		return value == null ? null : new Shortcut(value);

	public var count(get, never):Int;

	public inline function new(hotkeys:Array<Hotkey>)
		this = hotkeys;

	public inline function has(value:Hotkey):Bool {
		var v = false;
		for (h in this)
			if (h == value) {
				v = true;
				break;
			}
		return v;
	}

	@:op(a == b)
	public inline function equals(b:Shortcut) {
		if (b == null || count != b.count)
			return false;
		var h = true;
		for (v in b)
			if (!has(v)) {
				h = false;
				break;
			}
		return h;
	}

	@:op(a != b)
	public inline function notEquals(b:Shortcut)
		return !equals(b);

	@:to
	public inline function toString():String
		return this.map(c -> c.toString()).join(", ");

	public inline function iterator()
		return this.iterator();

	private inline function get_count():Int
		return this.length;
}

private typedef HotkeyData = {key:KeyCode, modifiers:Array<KeyCode>}
