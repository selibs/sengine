package;

import haxe.macro.Expr;

@:forward.new
abstract Signal<S>(Array<S>) {
	extern private inline function toArray():Array<S> {
		return this;
	}

	public macro function emit(self:Expr, exprs:Array<Expr>) {
		return macro for (s in @:privateAccess $self.toArray()) s($a{exprs});
	}

	public macro function connect(self:Expr, slot:Expr) {
		return macro(@:privateAccess $self.toArray()).push($slot);
	}

	public macro function disconnect(self:Expr, slot:Expr) {
		return macro(@:privateAccess $self.toArray()).remove($slot);
	}
}

@:forward.new
abstract KeySignal<K, S>(Map<K, Signal<S>>) {
	extern private inline function toMap():Map<K, Signal<S>> {
		return this;
	}

	public macro function emit(self:Expr, key:Expr, exprs:Array<Expr>) {
		return macro(@:privateAccess $self.toMap())[$key].emit($a{exprs});
	}

	public macro function connect(self:Expr, key:Expr, slot:Expr) {
		return macro(@:privateAccess $self.toMap())[$key].connect($slot);
	}

	public macro function disconnect(self:Expr, key:Expr, slot:Expr) {
		return macro(@:privateAccess $self.toMap())[$key].disconnect($slot);
	}
}
