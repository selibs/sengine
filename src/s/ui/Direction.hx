package s.ui;

enum abstract Direction(Int) from Int to Int {
	var LeftToRight:Int = 1 << 0;
	var RightToLeft:Int = 1 << 1;
	var TopToBottom:Int = 1 << 2;
	var BottomToTop:Int = 1 << 3;

	@:op(!a)
	inline function not()
		return (this & LeftToRight != 0 ? RightToLeft : this & RightToLeft != 0 ? LeftToRight : 0) | (this & TopToBottom != 0 ? BottomToTop : this & BottomToTop != 0 ? TopToBottom : 0);
}
