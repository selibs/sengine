package s.ui;

import s.ui.Selector;
import s.ui.elements.Element;

typedef Stylesheet = Array<Style>;

extern abstract Style({selector:Selector, f:Element->Void}) from {selector:Selector, f:Element->Void} to {selector:Selector, f:Element->Void} {
	@:from
	public static inline function fromString(value:String) {
		// TODO: parse css body
		return new Style(Type(Element), _ -> {});
	}

	overload public inline function new(rule:Rule, f:Element->Void)
		this = {selector: new Selector(rule), f: f};

	overload public inline function new(rule:Rule, props:Map<String, Dynamic>)
		this = new Style(rule, e -> {
			var o = e;
			for (p in props.keys()) {
				var path = p.split(".");
				for (f in path.slice(0, path.length - 1))
					o = Reflect.getProperty(o, f);
				Reflect.setProperty(o, path[path.length - 1], props[p]);
			}
		});

	overload public inline function new(rule:Rule, props:{})
		this = new Style(rule, e -> for (p in Reflect.fields(props))
			Reflect.setProperty(e, p, Reflect.getProperty(props, p)));

	public inline function apply(e:Element):Void
		this.selector.selectIfDirty(e, this.f);

	public inline function remove(e:Element):Bool
		return this.selector.deselect(e);
}
