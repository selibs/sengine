package s;

class TextEditor implements s.shortcut.Shortcut {
	final buf:StringBuf = new StringBuf();

	public function new() {}

	public inline function addChar(char:Char)
		buf.addChar(char);
}
