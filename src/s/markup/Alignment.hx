package s.markup;

import s.markup.Element;

extern enum abstract Alignment(Int) from Int to Int {
	var AlignLeft:Int = 1 << 0;
	var AlignRight:Int = 1 << 1;
	var AlignHCenter:Int = 1 << 2;
	var AlignTop:Int = 1 << 3;
	var AlignBottom:Int = 1 << 4;
	var AlignVCenter:Int = 1 << 5;
	var AlignCenter:Int = AlignHCenter | AlignVCenter;

	overload public static inline function align(alignment:Alignment, element:Element, ?h:Float = 0.0, ?v:Float = 0.0) {
		// horizontal
		if (alignment & AlignLeft != 0)
			element.x = h;
		else if (alignment & AlignHCenter != 0)
			element.x = h - element.width * 0.5;
		else if (alignment & AlignRight != 0)
			element.x = h - element.width;
		// vertical
		if (alignment & AlignTop != 0)
			element.y = v;
		else if (alignment & AlignVCenter != 0)
			element.y = v - element.height * 0.5;
		else if (alignment & AlignBottom != 0)
			element.y = v - element.height;
	}

	overload public static inline function align(alignment:Alignment, elements:Array<Element>, ?h:Float = 0.0, ?v:Float = 0.0) {
		// horizontal
		if (alignment & AlignLeft != 0)
			for (element in elements)
				element.x = h;
		else if (alignment & AlignHCenter != 0)
			for (element in elements)
				element.x = h - element.width * 0.5;
		else if (alignment & AlignRight != 0)
			for (element in elements)
				element.x = h - element.width;
		// vertical
		if (alignment & AlignTop != 0)
			for (element in elements)
				element.y = v;
		else if (alignment & AlignVCenter != 0)
			for (element in elements)
				element.y = v - element.height * 0.5;
		else if (alignment & AlignBottom != 0)
			for (element in elements)
				element.y = v - element.height;
	}

	public inline function toString():String {
		var strs = [];
		
		if (this & AlignLeft != 0)
			strs.push("AlignLeft");
		if (this & AlignHCenter != 0)
			strs.push("AlignHCenter");
		if (this & AlignRight != 0)
			strs.push("AlignRight");
		if (this & AlignTop != 0)
			strs.push("AlignTop");
		if (this & AlignVCenter != 0)
			strs.push("AlignVCenter");
		if (this & AlignBottom != 0)
			strs.push("AlignBottom");

		return strs.join(" + ");
	}
}
