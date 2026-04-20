package s.ui;

import s.ui.Selector;

typedef Stylesheet = Array<Style>;

@:forward
abstract Style(StyleData) from StyleData to StyleData {
	@:from
	public static function fromString(value:String) {
		// TODO: parse css body
		return new Style(Type(Element), _ -> {});
	}

	extern overload public inline function new(rule:Rule, props:{})
		this = new Style(rule, [for (f in Reflect.fields(props)) f => Reflect.getProperty(props, f)]);

	extern overload public inline function new(rule:Rule, props:Map<String, Any>)
		this = new Style(rule, e -> for (p in props.keys()) {
			var o = e;
			var path = p.split(".");
			for (f in path.slice(0, path.length - 1))
				o = Reflect.getProperty(o, f);
			Reflect.setProperty(o, path[path.length - 1], props[p]);
		});

	extern overload public inline function new(rule:Rule, f:Element->Void)
		this = {selector: new Selector(rule), f: f};

	public function apply(e:Element):Void
		e.setStyle(this);

	public function remove(e:Element):Void
		e.removeStyle(this);
}

private typedef StyleData = {selector:Selector, f:Element->Void}
