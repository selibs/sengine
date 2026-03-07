package s2d;

import haxe.ds.StringMap;
import s2d.Element;

using StringTools;

enum Rule {
	Custom(f:Element->Bool);
	// object
	Tag(tag:String); // "..."
	Type(type:Class<Element>); // a
	Object(object:Element); // ~a
	Properties(fields:StringMap<Dynamic>); // [...=...]
	// operations
	Not(rule:Rule); // !... / not(...)
	Or(rule1:Rule, rule2:Rule); // ... | ...
	And(rule1:Rule, rule2:Rule); // ... & ...
	Any(rules:Array<Rule>); // any(...)
	All(rules:Array<Rule>); // all(...)
	// relations
	Parent(rule:Rule); // ... < ...
	Children(rule:Rule); // ... > ...
	Siblings(rule:Rule); // ... % ...
	Descendants(rule:Rule); // ... >> ...
}

abstract Selector(SelectorData) from SelectorData {
	@:from
	public static function fromString(value:String) {
		// TODO: parse css selectors
		return new Selector();
	}

	public function new(?rule:Rule) {
		this = {rule: rule ?? Type(Element), slots: []};
	}

	public function select(element:Element, callback:Element->Void):Void {
		var slots = this.slots[element];
		if (slots != null)
			return;
		
		slots = [];
		this.slots[element] = slots;

		function match(r:Rule, ?cb:Bool->Void) {
			cb = cb ?? b -> if (b) callback(element);

			switch r {
				case Custom(f):
					cb(f(element));
				case Tag(tag):
					var slot = _ -> cb(element.tag == tag);
					element.onTagChanged(slot);
					slots.push(() -> element.offTagChanged(slot));
					slot(element.tag);
				case Type(type):
					cb(Std.isOfType(element, type));
				case Object(object):
					cb(object == element);
				case Properties(fields):
					for (f in fields.keyValueIterator()) {
						var slot = _ -> cb(Reflect.getProperty(element, f.key) == f.value);
						var signalName = '${f.key.charAt(0).toUpperCase()}${f.key.substr(1)}Changed';
						var on = Reflect.field(element, "on" + signalName);
						var off = Reflect.field(element, "off" + signalName);
						if (on != null && off != null) {
							Reflect.callMethod(element, on, [slot]);
							slots.push(() -> Reflect.callMethod(element, off, [slot]));
						}
						slot(Reflect.getProperty(element, f.key));
					}
				case Not(rule):
					match(rule, b -> cb(!b));
				case Or(rule1, rule2), And(rule1, rule2):
					var cond1 = false;
					var cond2 = false;
					switch r {
						case Or(_, _):
							match(rule1, b -> cb((cond1 = b) || cond2));
							match(rule2, b -> cb(cond1 || (cond2 = b)));
						default:
							match(rule1, b -> cb((cond1 = b) && cond2));
							match(rule2, b -> cb(cond1 && (cond2 = b)));
					}
				case Any(rules), All(rules):
					var cond = 0;
					final destination = switch r {
						case All(_): rules.length - 1;
						default: 0;
					}
					for (r in rules) {
						var set = false;
						match(r, b -> if (b) {
							if (!set) {
								set = true;
								cb(++cond > destination);
							}
						} else if (set) --cond);
					}
				case Children(rule):
					var s = new Selector(rule);
					var slotApply = c -> s.select(c, callback);
					var slotRemove = c -> s.deselect(c);
					element.onChildAdded(slotApply);
					element.onChildRemoved(slotRemove);
					slots.push(() -> {
						element.offChildAdded(slotApply);
						element.offChildRemoved(slotRemove);
						for (c in element.children)
							slotRemove(c);
					});
					for (c in element.children)
						slotApply(c);
				case Parent(rule):
					var s = new Selector(rule);
					var slot = p -> {
						if (p != null)
							s.deselect(p);
						if (element.parent != null)
							s.select(element.parent, callback);
					};
					element.onParentChanged(slot);
					slots.push(() -> {
						element.offParentChanged(slot);
						if (element.parent != null)
							s.deselect(element.parent);
					});
					slot(null);
				case Siblings(rule):
					var s = new Selector(Parent(Children(And(Not(Object(element)), rule))));
					s.select(element, callback);
					slots.push(() -> s.deselect(element));
				case Descendants(rule):
					var s = new Selector(Children(Or(Descendants(rule), rule)));
					s.select(element, callback);
					slots.push(() -> s.deselect(element));
				default:
					true;
			}
		}

		match(this.rule);
	}

	public function deselect(element:Element):Bool {
		var slots = this.slots[element];
		if (slots != null)
			for (s in slots)
				s();
		return this.slots.remove(element);
	}
}

private typedef SelectorData = {
	rule:Rule,
	slots:Map<Element, Array<Void->Void>>
}
