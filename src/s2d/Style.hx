package s2d;

import s2d.Element;

enum Relation {
	Child;
	Parent;
	Sibling;
}

enum StyleRule {
	Name(name:String);
	Type<T>(type:Class<T>);
	Any(rule1:StyleRule, rule2:StyleRule);
	All(rule1:StyleRule, rule2:StyleRule);
	Rel(relation:Relation, rule:StyleRule);
}

extern abstract Style<T:Element>(StyleData<T>) from StyleData<T> {
	@:from
	public static inline function fromString(value:String) {
		// TODO: parse css style
		return new Style();
	}

	public inline function apply(e:T) {
		inline function a(e:T)
			for (p in this.props)
				p(e);

		function matches(r:StyleRule)
			return switch this.rule {
				case Name(name): e.name == name;
				case Type(type): Std.isOfType(e, type);
				case Any(rule1, rule2): matches(rule1) || matches(rule2);
				case All(rule1, rule2): matches(rule1) && matches(rule2);
				default: true;
			}

		switch this.rule {
			case Rel(relation, rule):
				var s = new Style(rule, this.props);
				switch relation {
					case Child:
						for (c in e.children)
							s.apply(c);
					case Parent:
						if (e.parent != null) s.apply(e.parent);
					case Sibling:
						if (e.parent != null) for (c in e.parent.children.excluded(e))
							s.apply(c);
				}
			default:
				if (matches(this.rule))
					a(e);
		}
	}

	overload public inline function new(?rule:StyleRule) {
		this = {
			rule: rule ?? Type(T),
			props: []
		};
	}

	overload public inline function new(?rule:StyleRule, ?props:Array<T->Void>) {
		this = new Style(rule);
		if (props != null)
			for (p in props)
				addProperty(p);
	}

	overload public inline function new(?rule:StyleRule, ?props:Map<String, Dynamic>) {
		this = new Style(rule);
		if (props != null)
			for (p in props.keys())
				addProperty(p, props[p]);
	}

	overload public inline function new(?rule:StyleRule, ?props:{}) {
		this = new Style();
		if (props != null)
			for (p in Reflect.fields(props))
				addProperty(p, Reflect.field(props, p));
	}

	overload public inline function addProperty(prop:T->Void) {
		this.props.push(prop);
	}

	overload public inline function addProperty(name:String, value:Dynamic) {
		addProperty(e -> Reflect.setProperty(e, name, value));
	}
}

private typedef StyleData<T:Element> = {
	rule:StyleRule,
	props:Array<T->Void>
}
