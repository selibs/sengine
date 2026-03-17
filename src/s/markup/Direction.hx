package s.markup;

enum abstract Direction(Int) from Int to Int {
	var LeftToRight:Int = 1 << 0;
	var RightToLeft:Int = 1 << 1;
	var TopToBottom:Int = 1 << 2;
	var BottomToTop:Int = 1 << 3;
}
