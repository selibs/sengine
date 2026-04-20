package s.ui;

using StringTools;

enum AttrRule {
	Exists;
	Equals(value:Dynamic);
}

enum Rule {
	Custom(f:Element->Bool);
	// object
	Tags(tags:ElementTags); // "..."
	Type(type:Class<Element>); // a
	Object(object:Element); // ~a
	Attrs(attrs:Map<String, AttrRule>); // [...=...]
	// operations
	Not(rule:Rule); // !... / not(...)
	Or(rule1:Rule, rule2:Rule); // ... | ...
	And(rule1:Rule, rule2:Rule); // ... & ...
	Any(rules:Array<Rule>); // any(...)
	All(rules:Array<Rule>); // all(...)
	// relations
	Parent(rule:Rule); // ... < ...
	Children(rule:Rule); // ... > ...
	Siblings(rule:Rule); // ... >> ...
}

abstract Selector(Rule) from Rule to Rule {
	@:from
	public static function fromString(value:String) {
		// TODO: parse css selectors
		return new Selector();
	}

	public function new(?rule:Rule)
		this = rule ?? Type(Element);

	public inline function matches(element:Element):Bool
		return matchesRule(element, this);

	public inline function select(element:Element, callback:Element->Void):Void
		if (matches(element))
			callback(element);

	public inline function selectIfDirty(element:Element, callback:Element->Void):Void
		if (needsSync(element))
			select(element, callback);

	inline function needsSync(element:Element):Bool
		return @:privateAccess element.dirty || needsRuleUpdate(element, this);

	function matchesRule(element:Element, rule:Rule):Bool
		return switch rule {
			case Custom(f): f(element);
			case Tags(tags): element.tags == tags;
			case Type(type): Std.isOfType(element, type);
			case Object(object): object == element;
			case Attrs(fields):
				var matched = true;
				for (f in fields.keyValueIterator())
					switch f.value {
						case Exists:
							if (!Reflect.hasField(element, f.key)) {
								matched = false;
								break;
							}
						case Equals(value):
							if (Reflect.getProperty(element, f.key) != value) {
								matched = false;
								break;
							}
					}
				matched;
			case Not(rule): !matchesRule(element, rule);
			case Or(rule1, rule2): matchesRule(element, rule1) || matchesRule(element, rule2);
			case And(rule1, rule2): matchesRule(element, rule1) && matchesRule(element, rule2);
			case Any(rules):
				var matched = false;
				for (r in rules)
					if (matchesRule(element, r)) {
						matched = true;
						break;
					}
				matched;
			case All(rules):
				var matched = true;
				for (r in rules)
					if (!matchesRule(element, r)) {
						matched = false;
						break;
					}
				matched;
			case Parent(parentRule): element.parent != null && matchesRule(element.parent, parentRule);
			case Children(rule):
				var matched = false;
				for (child in element.children)
					if (matchesSubtree(child, rule)) {
						matched = true;
						break;
					}
				matched;
			case Siblings(siblingRule):
				var matched = false;
				if (element.parent != null)
					for (sibling in element.parent.children)
						if (sibling != element && matchesRule(sibling, siblingRule)) {
							matched = true;
							break;
						}
				matched;
		}

	function matchesSubtree(element:Element, rule:Rule):Bool {
		if (matchesRule(element, rule))
			return true;
		var d = false;
		for (child in element.children)
			if (matchesSubtree(child, rule)) {
				d = true;
				break;
			}
		return d;
	}

	function needsRuleUpdate(element:Element, rule:Rule):Bool
		return @:privateAccess switch rule {
			case Custom(_): true;
			case Tags(_): element.tags.dirty;
			case Type(_), Object(_): false;
			case Attrs(attrs):
				var d = false;
				for (f in attrs.keys())
					if (attrDirty(element, f)) {
						d = true;
						break;
					}
				d;
			case Not(rule): needsRuleUpdate(element, rule);
			case Or(rule1, rule2), And(rule1, rule2): needsRuleUpdate(element, rule1) || needsRuleUpdate(element, rule2);
			case Any(rules), All(rules):
				var d = false;
				for (r in rules)
					if (needsRuleUpdate(element, r)) {
						d = true;
						break;
					}
				d;
			case Parent(rule): element.parentDirty || element.parent != null && (element.parent.dirty || needsRuleUpdate(element.parent, rule));
			case Children(_): element.children.dirty;
			case Siblings(_): element.parentDirty || element.parent != null && (element.parent.dirty || element.parent.children.dirty);
		}

	function attrDirty(element:Element, path:String):Bool {
		final parts = path.split(".");

		var target:Dynamic = element;
		for (i in 0...parts.length - 1)
			if ((target = Reflect.getProperty(target, parts[i])) == null)
				break;

		return target == null ? true : Reflect.getProperty(target, '${parts[parts.length - 1]}Dirty') == true;
	}
}
