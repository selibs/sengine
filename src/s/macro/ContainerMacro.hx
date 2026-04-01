package s.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
#end

class ContainerMacro {
	#if macro
	public static function genericBuild() {
		switch Context.getLocalType() {
			case TInst(t, [TInst(_.get() => {kind: KExpr(macro $v{(i : Int)})}, []), d]):
				var N = Std.parseInt(i);

				var cls = t.get();
				var data = d.toComplexType();

				var thisType = ComplexType.TAnonymous([
					for (i in 0...N)
						{name: "i" + i, kind: FVar(data), pos: cls.pos}
				]);

				var typeName = "Container" + N;
				var iterName = typeName + "Iterator";

				inline function array(f:Expr->Expr)
					return {
						expr: ESwitch(macro i, [
							for (i in 0...N)
								{
									values: [macro $v{i}],
									expr: {
										var ref = "i" + i;
										f(macro this.$ref);
									}
								}
						], macro throw 'Index $i is out of range ' + $v{'[0, ${N - 1}]'}),
						pos: cls.pos
					}

				var refs = [for (i in 0...N) "i" + i];

				var typePath = {pack: [], name: typeName};
				var type = TPath(typePath);
				var typeDef = macro class $typeName {
					public var length(get, never):Int;

					@:from
					public static inline function fromArray(value:Array<$data>):$type
						return ${
							{
								expr: EObjectDecl([
									for (i in 0...N)
										{field: refs[i], expr: macro value[$v{i}]}
								]),
								pos: cls.pos
							}
						}

					@:to
					public inline function toString():String
						return Std.string(toArray());

					public inline function iterator():Iterator<$data>
						return toArray().iterator();

					public inline function traverse(f:$data->Void):Void
						return $b{[for (ref in refs) macro f(this.$ref)]}

					@:to
					private inline function toArray():Array<$data>
						return [$a{refs.map(ref -> macro this.$ref)}];

					@:op([])
					macro function arrayRead(i:Int):$data
						return ${array(e -> e)};

					@:op([])
					macro function arrayWrite(i:Int, value:$data):$data
						return ${array(e -> macro $e = value)};

					private inline function get_length():Int
						return $v{N};
				}

				typeDef.isExtern = true;
				typeDef.pack = [];
				typeDef.kind = TDAbstract(thisType, [AbFrom(thisType), AbTo(thisType)], [thisType], [thisType]);
				typeDef.fields.push({
					name: "new",
					access: [APublic, AInline],
					kind: FFun({
						args: [{name: "value", type: data, opt: true}],
						expr: macro this = ${
							{
								expr: EObjectDecl([
									for (i in 0...N)
										{field: refs[i], expr: macro value}
								]),
								pos: typeDef.pos
							}
						},
						ret: type
					}),
					pos: typeDef.pos
				});

				Context.defineType(typeDef);

				return type;
			default:
				Context.error("Invalid type", Context.currentPos());
		}
		return null;
	}
	#end
}
