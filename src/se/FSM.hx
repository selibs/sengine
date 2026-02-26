package se;

class FSM {
	public var current:State;

	public function new(?state:State) {
		this.current = state;
	}

	public function goto(to:State) {
		if (current == null)
			return;

		final transition = current.getTransition(to);
		if (transition != null) {
			current = to;
			transition();
		}
	}
}

@:forward()
@:forward.new
abstract State(StateData) from StateData to StateData {
	@:from
	static inline function fromMap(value:Map<State, Void->Void>):State {
		return new State(value);
	}

	@:op([])
	public function addTransition(to:State, ?transition:Void->Void) {
		this.transitions.set(to, transition ?? () -> {});
	}

	@:op([])
	public function getTransition(to:State) {
		return to != null ? this.transitions.get(to) : null;
	}

	public function hasTransition(to:State) {
		return this.transitions.exists(to);
	}

	public function removeTransition(to:State) {
		this.transitions.remove(to);
	}
}

class StateData {
	public var transitions:Map<StateData, Void->Void>;

	public function new(?transitions:Map<StateData, Void->Void>) {
		this.transitions = transitions ?? [];
	}
}
