package s2d.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

class ElementMacro {
	public static function build() {
		var fields = Context.getBuildFields();

		for (field in fields)
			for (m in field.meta)
				if (m.name == "ui.markup") {
					try {
						buildMarkup(field);
					} catch (e)
						Context.error("Failed to build markup: " + e.message, field.pos);
					break;
				}

		return fields;
	}

	static function buildMarkup(field:Field) {
		var n = 0;

		function transform(expr:Expr) {
			function buildEl(meta:MetadataEntry, expr:Expr, pos:Position) {
				var elExprs:Array<Expr> = [macro @:pos(pos) __b.openElement($i{meta.name})];
				for (p in meta.params ?? [])
					switch p.expr {
						case EBinop(OpAssign, e1, e2):
							switch e1.expr {
								case EConst(CIdent(s)):
									elExprs.push(macro @:pos(e1.pos) __b.element.$s = $e2);
								default:
									Context.warning("Invalid attribute", p.pos);
							}
						case EObjectDecl(fields):
							for (f in fields) {
								var s = f.field;
								elExprs.push(macro @:pos(f.expr.pos) __b.element.$s = ${f.expr});
							}
						default:
							Context.warning("Invalid operation", p.pos);
					}
				elExprs = elExprs.concat(block(transform(expr)));
				elExprs.push(macro __b.closeElement());

				return EBlock(elExprs);
			}

			var def = expr.expr;
			if (def != null)
				expr.expr = switch def {
					case EBlock(exprs):
						EBlock(exprs.map(e -> transform(e)));
					case EIf(econd, eif, eelse):
						EIf(econd, transform(eif), transform(eelse));
					case EFor(it, e):
						EFor(it, transform(e));
					case EWhile(econd, e, normalWhile):
						EWhile(econd, transform(e), normalWhile);
					case ESwitch(e, cases, edef):
						ESwitch(e, cases.map(c -> {
							values: c.values,
							guard: c.guard,
							expr: transform(c.expr)
						}), transform(edef));
					case EMeta(m, e) if (m.name.charAt(0) != ":"):
						buildEl(m, e, expr.pos);
					default:
						expr.expr;
				}
			return expr;
		}

		switch field.kind {
			case FFun(f):
				if (f.expr != null) {
					f.expr = concat((macro var __b = new s2d.ElementTreeBuilder(this)), transform(f.expr));
					trace(f.expr.toString());
				}
			default:
				throw "Field must be function";
		}
	}

	static function concat(e1:Expr, e2:Expr) {
		var e = block(e1).concat(block(e2));
		if (e.length > 1)
			return macro $b{e};
		return e[0];
	}

	static function block(expr:Expr) {
		return switch expr.expr {
			case EBlock(exprs):
				exprs;
			default:
				[expr];
		}
	}
}
#end
