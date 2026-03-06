package s2d;

import s2d.Element;

enum Selector {
	Always;
	Child(element:Element);
	Sibling(element:Element);
	ByAll(s1:Selector, s2:Selector);
	ByAny(s1:Selector, s2:Selector);
	ByName(name:String);
	ByType<T:Element>(type:Class<T>);
	ByAttribute<T>(attr:String, ?value:T);
}

typedef Style = {
	selector:Selector,
	f:Element->Void
}

typedef Stylesheet = Array<Style>;
