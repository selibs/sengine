package s.app.input;

import kha.input.Keyboard as KhaKeyboard;

typedef BlockInterventions = kha.input.Keyboard.BlockInterventions;

class Keyboard implements s.shortcut.Shortcut {
	public static inline function disableSystemInterventions(behavior:BlockInterventions):Void
		KhaKeyboard.disableSystemInterventions(behavior);

	var keysTimers:Map<KeyCode, Timer> = [];
	var hotkeyPressedListeners:Map<Array<KeyCode>, Array<Void->Void>> = [];

	public var keysDown:Array<KeyCode> = [];
	public var holdInterval = 0.5;

	@:signal public function down(key:KeyCode);

	@:signal public function up(key:KeyCode);

	@:signal public function hold(key:KeyCode);

	@:signal public function pressed(char:Char);

	@:signal public function hotkey(hotkey:Array<KeyCode>);

	@:signal(key) public function keyDown(key:KeyCode);

	@:signal(key) public function keyUp(key:KeyCode);

	@:signal(key) public function keyHold(key:KeyCode);

	@:signal(char) public function charPressed(char:Char);

	public function new(id:Int = 0) {
		KhaKeyboard.get(id).notify(k -> down((k : Int)), k -> up((k : Int)), c -> pressed(c));

		onDown(k -> keyDown(k));
		onUp(k -> keyUp(k));
		onHold(k -> keyHold(k));
		onPressed(c -> charPressed(c));
	}

	@:slot(down)
	function processDown(key:KeyCode) {
		keysDown.push(key);
		hotkeyDown(keysDown);

		keysTimers.set(key, Timer.set(() -> {
			if (keysTimers.exists(key))
				hold(key);
		}, holdInterval));
	}

	@:slot(up)
	function processUp(key:KeyCode) {
		keysDown.remove(key);
		hotkeyDown(keysDown);

		keysTimers.get(key)?.stop();
		keysTimers.remove(key);
	}

	function hotkeyDown(hotkey:Array<KeyCode>) {
		if (hotkey.length > 1) {
			this.hotkey(hotkey);
			for (listener in hotkeyPressedListeners.keyValueIterator())
				if (listener.key.length == hotkey.length) {
					var flag = true;
					for (k in listener.key)
						if (!hotkey.contains(k)) {
							flag = false;
							break;
						}
					if (flag) {
						for (callback in listener.value)
							callback();
						break;
					}
				}
		}
	}
}

extern enum abstract KeyCode(Int) from Int to Int {
	var Unknown = 0;
	var Back = 1; // Android
	var Cancel = 3;
	var Help = 6;
	var Backspace = 8;
	var Tab = 9;
	var Clear = 12;
	var Return = 13;
	var Shift = 16;
	var Control = 17;
	var Alt = 18;
	var Pause = 19;
	var CapsLock = 20;
	var Kana = 21;
	var Hangul = 21;
	var Eisu = 22;
	var Junja = 23;
	var Final = 24;
	var Hanja = 25;
	var Kanji = 25;
	var Escape = 27;
	var Convert = 28;
	var NonConvert = 29;
	var Accept = 30;
	var ModeChange = 31;
	var Space = 32;
	var PageUp = 33;
	var PageDown = 34;
	var End = 35;
	var Home = 36;
	var Left = 37;
	var Up = 38;
	var Right = 39;
	var Down = 40;
	var Select = 41;
	var Print = 42;
	var Execute = 43;
	var PrintScreen = 44;
	var Insert = 45;
	var Delete = 46;
	var Zero = 48;
	var One = 49;
	var Two = 50;
	var Three = 51;
	var Four = 52;
	var Five = 53;
	var Six = 54;
	var Seven = 55;
	var Eight = 56;
	var Nine = 57;
	var Colon = 58;
	var Semicolon = 59;
	var LessThan = 60;
	var Equals = 61;
	var GreaterThan = 62;
	var QuestionMark = 63;
	var At = 64;
	var A = 65;
	var B = 66;
	var C = 67;
	var D = 68;
	var E = 69;
	var F = 70;
	var G = 71;
	var H = 72;
	var I = 73;
	var J = 74;
	var K = 75;
	var L = 76;
	var M = 77;
	var N = 78;
	var O = 79;
	var P = 80;
	var Q = 81;
	var R = 82;
	var S = 83;
	var T = 84;
	var U = 85;
	var V = 86;
	var W = 87;
	var X = 88;
	var Y = 89;
	var Z = 90;
	var Win = 91;
	var ContextMenu = 93;
	var Sleep = 95;
	var Numpad0 = 96;
	var Numpad1 = 97;
	var Numpad2 = 98;
	var Numpad3 = 99;
	var Numpad4 = 100;
	var Numpad5 = 101;
	var Numpad6 = 102;
	var Numpad7 = 103;
	var Numpad8 = 104;
	var Numpad9 = 105;
	var Multiply = 106;
	var Add = 107;
	var Separator = 108;
	var Subtract = 109;
	var Decimal = 110;
	var Divide = 111;
	var F1 = 112;
	var F2 = 113;
	var F3 = 114;
	var F4 = 115;
	var F5 = 116;
	var F6 = 117;
	var F7 = 118;
	var F8 = 119;
	var F9 = 120;
	var F10 = 121;
	var F11 = 122;
	var F12 = 123;
	var F13 = 124;
	var F14 = 125;
	var F15 = 126;
	var F16 = 127;
	var F17 = 128;
	var F18 = 129;
	var F19 = 130;
	var F20 = 131;
	var F21 = 132;
	var F22 = 133;
	var F23 = 134;
	var F24 = 135;
	var NumLock = 144;
	var ScrollLock = 145;
	var WinOemFjJisho = 146;
	var WinOemFjMasshou = 147;
	var WinOemFjTouroku = 148;
	var WinOemFjLoya = 149;
	var WinOemFjRoya = 150;
	var Circumflex = 160;
	var Exclamation = 161;
	var DoubleQuote = 162;
	var Hash = 163;
	var Dollar = 164;
	var Percent = 165;
	var Ampersand = 166;
	var Underscore = 167;
	var OpenParen = 168;
	var CloseParen = 169;
	var Asterisk = 170;
	var Plus = 171;
	var Pipe = 172;
	var HyphenMinus = 173;
	var OpenCurlyBracket = 174;
	var CloseCurlyBracket = 175;
	var Tilde = 176;
	var VolumeMute = 181;
	var VolumeDown = 182;
	var VolumeUp = 183;
	var Comma = 188;
	var Period = 190;
	var Slash = 191;
	var BackQuote = 192;
	var OpenBracket = 219;
	var BackSlash = 220;
	var CloseBracket = 221;
	var Quote = 222;
	var Meta = 224;
	var AltGr = 225;
	var WinIcoHelp = 227;
	var WinIco00 = 228;
	var WinIcoClear = 230;
	var WinOemReset = 233;
	var WinOemJump = 234;
	var WinOemPA1 = 235;
	var WinOemPA2 = 236;
	var WinOemPA3 = 237;
	var WinOemWSCTRL = 238;
	var WinOemCUSEL = 239;
	var WinOemATTN = 240;
	var WinOemFinish = 241;
	var WinOemCopy = 242;
	var WinOemAuto = 243;
	var WinOemENLW = 244;
	var WinOemBackTab = 245;
	var ATTN = 246;
	var CRSEL = 247;
	var EXSEL = 248;
	var EREOF = 249;
	var Play = 250;
	var Zoom = 251;
	var PA1 = 253;
	var WinOemClear = 254;

	@:to
	public inline function toString():String
		return switch this {
			case Unknown: "Unknown";
			case Back: "Back";
			case Cancel: "Cancel";
			case Help: "Help";
			case Backspace: "Backspace";
			case Tab: "Tab";
			case Clear: "Clear";
			case Return: "Enter";
			case Shift: "Shift";
			case Control: "Ctrl";
			case Alt: "Alt";
			case Pause: "Pause";
			case CapsLock: "Caps Lock";
			case Kana: "Kana";
			case Eisu: "Eisu";
			case Junja: "Junja";
			case Final: "Final";
			case Hanja: "Hanja";
			case Escape: "Escape";
			case Convert: "Convert";
			case NonConvert: "Non Convert";
			case Accept: "Accept";
			case ModeChange: "Mode Change";
			case Space: "Space";
			case PageUp: "Page Up";
			case PageDown: "Page Down";
			case End: "End";
			case Home: "Home";
			case Left: "Left";
			case Up: "Up";
			case Right: "Right";
			case Down: "Down";
			case Select: "Select";
			case Print: "Print";
			case Execute: "Execute";
			case PrintScreen: "Print Screen";
			case Insert: "Insert";
			case Delete: "Delete";
			case Zero: "0";
			case One: "1";
			case Two: "2";
			case Three: "3";
			case Four: "4";
			case Five: "5";
			case Six: "6";
			case Seven: "7";
			case Eight: "8";
			case Nine: "9";
			case Colon: ":";
			case Semicolon: ";";
			case LessThan: "<";
			case Equals: "=";
			case GreaterThan: ">";
			case QuestionMark: "?";
			case At: "@";
			case A: "A";
			case B: "B";
			case C: "C";
			case D: "D";
			case E: "E";
			case F: "F";
			case G: "G";
			case H: "H";
			case I: "I";
			case J: "J";
			case K: "K";
			case L: "L";
			case M: "M";
			case N: "N";
			case O: "O";
			case P: "P";
			case Q: "Q";
			case R: "R";
			case S: "S";
			case T: "T";
			case U: "U";
			case V: "V";
			case W: "W";
			case X: "X";
			case Y: "Y";
			case Z: "Z";
			case Win: "Win";
			case ContextMenu: "Context Menu";
			case Sleep: "Sleep";
			case Numpad0: "NumPad 0";
			case Numpad1: "NumPad 1";
			case Numpad2: "NumPad 2";
			case Numpad3: "NumPad 3";
			case Numpad4: "NumPad 4";
			case Numpad5: "NumPad 5";
			case Numpad6: "NumPad 6";
			case Numpad7: "NumPad 7";
			case Numpad8: "NumPad 8";
			case Numpad9: "NumPad 9";
			case Multiply: "*";
			case Add: "+";
			case Separator: "Separator";
			case Subtract: "-";
			case Decimal: ".";
			case Divide: "/";
			case F1: "F1";
			case F2: "F2";
			case F3: "F3";
			case F4: "F4";
			case F5: "F5";
			case F6: "F6";
			case F7: "F7";
			case F8: "F8";
			case F9: "F9";
			case F10: "F10";
			case F11: "F11";
			case F12: "F12";
			case F13: "F13";
			case F14: "F14";
			case F15: "F15";
			case F16: "F16";
			case F17: "F17";
			case F18: "F18";
			case F19: "F19";
			case F20: "F20";
			case F21: "F21";
			case F22: "F22";
			case F23: "F23";
			case F24: "F24";
			case NumLock: "Num Lock";
			case ScrollLock: "Scroll Lock";
			case WinOemFjJisho: "WinOemFjJisho";
			case WinOemFjMasshou: "WinOemFjMasshou";
			case WinOemFjTouroku: "WinOemFjTouroku";
			case WinOemFjLoya: "WinOemFjLoya";
			case WinOemFjRoya: "WinOemFjRoya";
			case Circumflex: "^";
			case Exclamation: "!";
			case DoubleQuote: "\"";
			case Hash: "#";
			case Dollar: "$";
			case Percent: "%";
			case Ampersand: "&";
			case Underscore: "_";
			case OpenParen: "(";
			case CloseParen: ")";
			case Asterisk: "*";
			case Plus: "+";
			case Pipe: "|";
			case HyphenMinus: "-";
			case OpenCurlyBracket: "{";
			case CloseCurlyBracket: "}";
			case Tilde: "~";
			case VolumeMute: "Volume Mute";
			case VolumeDown: "Volume Down";
			case VolumeUp: "Volume Up";
			case Comma: ",";
			case Period: ".";
			case Slash: "/";
			case BackQuote: "`";
			case OpenBracket: "[";
			case BackSlash: "\\";
			case CloseBracket: "]";
			case Quote: "'";
			case Meta: "Meta";
			case AltGr: "AltGr";
			case WinIcoHelp: "WinIcoHelp";
			case WinIco00: "WinIco00";
			case WinIcoClear: "WinIcoClear";
			case WinOemReset: "WinOemReset";
			case WinOemJump: "WinOemJump";
			case WinOemPA1: "WinOemPA1";
			case WinOemPA2: "WinOemPA2";
			case WinOemPA3: "WinOemPA3";
			case WinOemWSCTRL: "WinOemWSCTRL";
			case WinOemCUSEL: "WinOemCUSEL";
			case WinOemATTN: "WinOemATTN";
			case WinOemFinish: "WinOemFinish";
			case WinOemCopy: "WinOemCopy";
			case WinOemAuto: "WinOemAuto";
			case WinOemENLW: "WinOemENLW";
			case WinOemBackTab: "WinOemBackTab";
			case ATTN: "ATTN";
			case CRSEL: "CRSEL";
			case EXSEL: "EXSEL";
			case EREOF: "EREOF";
			case Play: "Play";
			case Zoom: "Zoom";
			case PA1: "PA1";
			case WinOemClear: "WinOemClear";
			default: 'KeyCode(${(this : Int)})';
		}
}
