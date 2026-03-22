package s.markup.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

class ExprError extends haxe.Exception {
	public var expr:Expr;

	public function new(expr:Expr, ?message:String) {
		super(message ?? "Invalid expression");
		this.expr = expr;
	}

	public function warn() {
		Context.warning('$message: ${expr.toString()}', expr.pos);
	}
}
#end

class MarkupMacro {
	#if macro
	static var reserved = ["style", "use", "all"];
	static var stylesheets:Map<String, Map<String, Array<Expr>>>;

	public static var shortcuts(default, null):Map<String, String> = [
		"element" => "s.markup.Element",
		"drawable" => "s.markup.elements.DrawableElement",
		"interactive" => "s.markup.elements.InteractiveElement",
		// controls
		// "button" => "s.markup.controls.Button",
		// "input" => "s.markup.controls.TextInput",
		// elements
		"label" => "s.markup.elements.Label",
		// "positioner" => "s.markup.elements.Positioner",
		"text" => "s.markup.elements.Text",
		// "edit" => "s.markup.elements.TextEdit",
		"canvas" => "s.markup.elements.Canvas",
		"image" => "s.markup.elements.ImageElement",
		// shapes
		"circle" => "s.markup.elements.shapes.Circle",
		"ellipse" => "s.markup.elements.shapes.Ellipse",
		"triangle" => "s.markup.elements.shapes.Triangle",
		"rectangle" => "s.markup.elements.shapes.Rectangle",
		// gradients
		"gradient.linear" => "s.markup.elements.gradients.LinearGradient",
		"gradient.radial" => "s.markup.elements.gradients.RadialGradient",
		"gradient.conic" => "s.markup.elements.gradients.ConicGradient",
		// layouts
		"box" => "s.markup.layouts.BoxLayout",
		// "vbox" => "s.markup.layouts.VBoxLayout",
		// "hbox" => "s.markup.layouts.HBoxLayout",
		// widgets
		// "progress" => "s.markup.widgets.ProgressBar",
		// "scroll" => "s.markup.widgets.ScrollView",
		// stage
		// "stage" => "s.markup.Stage"
	];

	public static function init() {
		Compiler.registerCustomMetadata({
			metadata: ":ui.markup",
			doc: "A"
		});
		stylesheets = [];
		Compiler.addGlobalMetadata("", "@:build(s.markup.macro.MarkupMacro.build())", true, true, true);
	}

	public static function useShortcut(name:String, type:String) {
		if (reserved.contains(name)) {
			Context.warning("Can't overwrite reserved shortcut `name`", Context.currentPos());
			return;
		}

		if (shortcuts.exists(name))
			Context.warning('Shortcut `$name -> ${shortcuts.get(name)}` will be overwritten to `$type`', Context.currentPos());
		shortcuts.set(name, type);
	}

	public static function build() {
		var fields = Context.getBuildFields();

		for (field in fields) {
			if (field.meta == null)
				continue;
			for (m in field.meta)
				switch m.name {
					case ":ui.markup":
						buildMarkup(field);
					case ":ui.style":
						try {
							buildStylesheet(field);
						} catch (er:ExprError) {
							er.warn();
							fields.remove(field);
						}
				}
		}

		return fields;
	}

	static function getType(name:String) {
		return Context.getType(getTypeName(name)).toComplexType();
	}

	static function getTypePath(name:String):TypePath {
		return switch getType(name) {
			case TPath(tp):
				tp;
			default:
				throw "Invalid element class: " + name;
		}
	}

	static function getTypeName(name:String) {
		return shortcuts.get(name) ?? name;
	}

	static function buildMarkup(field:Field) {
		var i = 0;
		var stack:Array<Expr> = [macro parent];

		inline function currentRef():Expr
			return stack[stack.length - 1];

		inline function parentRef():Expr
			return stack.length > 1 ? stack[stack.length - 2] : macro parent;

		function transform(expr:Expr) {
			function addEl(meta:MetadataEntry, expr:Expr, pos:Position, ?varData:{name:String, type:Null<ComplexType>, isFinal:Bool}, ?assignRef:Expr) {
				var elTypeName = getTypeName(meta.name);
				var elCls:TypePath = {
					pack: null,
					name: null,
					sub: null
				}
				elCls.pack = elTypeName.split(".");
				elCls.name = elCls.pack.pop();
				if (elCls.pack.length > 0) {
					var c = elCls.pack[elCls.pack.length - 1].charAt(0);
					if (c == c.toUpperCase()) {
						elCls.sub = elCls.name;
						elCls.name = elCls.pack.pop();
					}
				}

				var ctor = macro @:pos(pos) new $elCls($a{meta.params ?? []});
				var elRef:Expr;
				var elExprs = [];

				if (varData != null) {
					elRef = macro @:pos(pos) $i{varData.name};
					elExprs.push({
						pos: pos,
						expr: EVars([
							{
								name: varData.name,
								type: varData.type,
								expr: ctor,
								isFinal: varData.isFinal
							}
						])
					});
				} else if (assignRef != null) {
					elRef = assignRef;
					elExprs.push(macro @:pos(pos) $assignRef = $ctor);
				} else {
					var elName = "__el" + i++;
					elRef = macro @:pos(pos) $i{elName};
					elExprs.push(macro @:pos(pos) var $elName = $ctor);
				}

				stack.push(elRef);
				var bodyExprs = transform(expr);
				stack.pop();
				if (bodyExprs != null && bodyExprs.length > 0)
					elExprs.push({
						pos: pos,
						expr: EBlock(bodyExprs)
					});
				elExprs.push(macro ${currentRef()}.addChild($elRef));

				return elExprs;
			}

			var def = expr.expr;
			if (def == null)
				return null;

			switch def {
				case EBlock(exprs):
					var out:Array<Expr> = [];
					for (e in exprs)
						out = out.concat(transform(e));
					return out;
				case EConst(CIdent(s)) if (s.charAt(0) == "$"):
					if (s == "$parent")
						expr = parentRef();
					else
						expr.expr = EField(currentRef(), s.substr(1));
					return transform(expr);
				case EMeta(m, e) if (m.name.charAt(0) != ":"):
					return switch m.name {
						case "use":
							[macro ${currentRef()}.useStylesheet($e)];
						default:
							addEl(m, e, expr.pos);
					}
				case EVars(vars):
					var out:Array<Expr> = [];
					for (v in vars) {
						var n = v.name;
						if (v.expr == null) {
							out.push({
								pos: expr.pos,
								expr: EVars([
									{
										name: v.name,
										type: v.type,
										expr: null,
										isFinal: v.isFinal
									}
								])
							});
							continue;
						}
						out = out.concat(switch v.expr.expr {
							case EMeta(s, e):
								addEl(s, e, v.expr.pos, {
									name: n,
									type: v.type,
									isFinal: v.isFinal
								});
							default:
								[
									{
										pos: v.expr.pos,
										expr: EVars([
											{
												name: v.name,
												type: v.type,
												expr: v.expr,
												isFinal: v.isFinal
											}
										])
									}
								];
						});
					}
					return out;
				case EBinop(OpAssign, e1, e2):
					switch e2.expr {
						case EMeta(m, e):
							switch e1.expr {
								case EConst(CIdent(s)):
									return addEl(m, e, e2.pos, null, macro @:pos(e1.pos) $i{s});
								case EField(e, field):
									return addEl(m, e, e2.pos, null, e1);
								default:
							}
						default:
					}
				default:
			}

			return flatten(expr.map(e -> block(transform(e))));
		}

		var expr = extractExpr(field);
		var args = switch field.kind {
			case FFun(f):
				f.args;
			default:
				[];
		}
		args.push({
			name: "parent",
			type: macro :s.markup.Element
		});

		if (expr != null) {
			var expr = block(transform(expr));
			field.kind = FFun({
				args: args,
				expr: expr,
				ret: macro :Void
			});
		}
	}

	static function buildStylesheet(field:Field) {
		function buildStyle(meta:MetadataEntry, expr:Expr, mExpr:Expr):Array<Expr> {
			var substyles = [];

			function getName(expr:Expr) {
				return switch expr.expr {
					case EConst((CIdent(s))):
						switch s {
							case "$":
								meta.name;
							default: s;
						}
					case EField(e, field, kind):
						getName(e) + "." + field;
					default:
						null;
				}
			}

			function prop(expr:Expr) {
				return switch expr.expr {
					case EConst(CIdent(s)):
						macro @:pos(expr.pos) $v{s} => Exists;
					case EBinop(OpAssign, e1, e2):
						var name = getName(e1);
						if (name == null)
							throw new ExprError(expr, "Name expected");
						macro @:pos(e1.pos) $v{name} => Equals($e2);
					default:
						throw new ExprError(expr);
				}
			}

			function rule(expr:Expr) {
				var name = getName(expr);
				if (name != null)
					return macro @:pos(expr.pos) Type($p{getTypeName(name).split(".")});

				return switch expr.expr {
					case EConst(CString(s)):
						macro @:pos(expr.pos) Tag($expr);
					case EUnop(op, false, e):
						switch op {
							case OpNot:
								macro @:pos(expr.pos) Not(${rule(e)});
							case OpNegBits:
								macro @:pos(expr.pos) Object($e);
							default:
								throw new ExprError(expr);
						}
					case EBinop(op, e1, e2):
						switch op {
							case OpOr:
								macro @:pos(expr.pos) Or(${rule(e1)}, ${rule(e2)});
							case OpAnd:
								macro @:pos(expr.pos) And(${rule(e1)}, ${rule(e2)});
							case OpLt:
								macro @:pos(expr.pos) And(${rule(e1)}, Parent(${rule(e2)}));
							case OpGt:
								macro @:pos(expr.pos) And(${rule(e1)}, Children(${rule(e2)}));
							case OpMod:
								macro @:pos(expr.pos) And(${rule(e1)}, Siblings(${rule(e2)}));
							default:
								throw new ExprError(expr);
						}
					case EArrayDecl(values):
						var props = [
							for (v in values)
								try {
									prop(v);
								} catch (er:ExprError) {
									er.warn();
									continue;
								}
						];
						macro @:pos(expr.pos) Properties([$a{props}]);
					case ECall(e, params):
						switch e.expr {
							case EConst(CIdent(s)):
								switch s {
									case "not" if (params.length == 1):
										macro @:pos(expr.pos) Not(${rule(params[0])});
									case "or" if (params.length == 2):
										macro @:pos(expr.pos) Or(${rule(params[0])}, ${rule(params[1])});
									case "and" if (params.length == 2):
										macro @:pos(expr.pos) And(${rule(params[0])}, ${rule(params[1])});
									case "any":
										macro @:pos(expr.pos) Any([$a{params.map(rule)}]);
									case "all":
										macro @:pos(expr.pos) All([$a{params.map(rule)}]);
									default:
										throw new ExprError(expr, 'Unknown operation "$s"');
								}
							default:
								throw new ExprError(expr, "Operation name expected");
						}
					default:
						throw new ExprError(expr);
				}
			}

			function body(type:String, expr:Expr) {
				function replace(e:Expr) {
					return e.map(e -> switch e.expr {
						case EConst(CIdent(s)) if (s.charAt(0) == "$"):
							macro @:pos(e.pos) $p{["e"].concat(s.substr(1).split("."))};
						default:
							replace(e);
					});
				}

				return switch expr.expr {
					case EBlock(exprs):
						var t = getType(type);
						var fields = [macro var e:$t = cast e];
						for (e in exprs)
							switch e.expr {
								case EMeta(m, e) if (m.name.charAt(0) != ":"):
									try {
										for (s in buildStyle(m, e, expr))
											substyles.push(s);
									} catch (er:ExprError)
										er.warn();
								default:
									fields.push(replace(e));
							}
						macro e -> ${block(fields)};
					default:
						throw new ExprError(expr);
				}
			}

			var params = meta.params ?? [];
			if (params.length < 2) {
				var selector = macro Type($p{getTypeName(meta.name).split(".")});
				if (params.length == 1)
					selector = macro And($selector, ${rule(params[0])});
				substyles.push(macro new s.markup.Style($selector, ${body(meta.name, expr)}));
			} else
				throw new ExprError(mExpr, "Expected only 1 selector");

			return substyles;
		}

		var expr = extractExpr(field);
		switch expr.expr {
			case EBlock(exprs):
				var styles = [];
				for (ex in exprs)
					try {
						switch ex.expr {
							case EMeta(m, e) if (m.name.charAt(0) != ":"):
								styles = styles.concat(buildStyle(m, e, ex));
							default:
								throw new ExprError(ex);
						}
					} catch (er:ExprError)
						er.warn();
				field.kind = FVar(macro :s.markup.Style.Stylesheet, macro @:pos(expr.pos) $a{styles});
			default:
				throw new ExprError(expr);
		}
	}

	static function extractExpr(field:Field) {
		return switch field.kind {
			case FFun(f):
				f.expr;
			case FVar(t, e), FProp(_, _, t, e):
				e;
		}
	}

	static function extractName(expr:Expr):String {
		return switch expr.expr {
			case EConst(CIdent(s)), EConst(CString(s)):
				s;
			case EField(e, field):
				extractName(e) + "." + field;
			default:
				Context.warning("Name expected", expr.pos);
				null;
		}
	}

	static function concat(e1:Expr, e2:Expr) {
		return block(flatten(e1).concat(flatten(e2)));
	}

	static function block(exprs:Array<Expr>) {
		if (exprs.length > 1)
			return macro $b{exprs};
		return exprs[0];
	}

	static function flatten(expr:Expr):Array<Expr> {
		return switch expr.expr {
			case EBlock(exprs):
				exprs;
			default:
				[expr];
		}
	}
	#end
}
