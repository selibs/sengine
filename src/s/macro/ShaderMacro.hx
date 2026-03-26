package s.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class ShaderMacro {
	#if macro
	public static function build() {
		final fields = Context.getBuildFields();
		final clsRef = Context.getLocalClass();
		if (clsRef == null)
			return fields;

		final cls = clsRef.get();
		if (cls.isAbstract || cls.params.length > 0 || Lambda.exists(fields, f -> f.name == "shader"))
			return fields;

		final tp:TypePath = {pack: cls.pack, name: cls.name};
		fields.push({
			name: "shader",
			access: [APublic, AStatic],
			kind: FProp("default", "never", TPath(tp), macro new $tp()),
			pos: cls.pos
		});
		return fields;
	}
	#end
}
