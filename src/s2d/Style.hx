package s2d;

import s2d.Selector;

typedef Stylesheet = Array<Style>;

@:forward(selector)
abstract Style(StyleData) from StyleData {
	// @:from
	// public static function fromString(value:String) {
	// 	// TODO: parse css body
	// 	return new Style();
	// }
	extern overload public inline function new(rule:Rule, f:Element->Void) {
		this = {selector: new Selector(rule), f: f};
	}

	extern overload public inline function new(rule:Rule, props:Map<String, Dynamic>) {
		this = {
			selector: new Selector(rule),
			f: e -> {
				var o = e;
				for (p in props.keys()) {
					var path = p.split(".");
					for (f in path.slice(0, path.length - 2))
						o = Reflect.getProperty(o, f);
					Reflect.setProperty(o, path[path.length - 1], props[p]);
				}
			}
		};
	}

	extern overload public inline function new(rule:Rule, props:{}) {
		this = {
			selector: new Selector(rule),
			f: e -> {
				for (p in Reflect.fields(props))
					Reflect.setProperty(e, p, Reflect.getProperty(props, p));
			}
		};
	}

	public function apply(e:Element):Void {
		this.selector.select(e, this.f);
	}

	public function remove(e:Element):Bool {
		return this.selector.deselect(e);
	}
}

private typedef StyleData = {
	selector:Selector,
	f:Element->Void
}
