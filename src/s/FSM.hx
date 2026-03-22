package s;

/**
 * Minimal finite state machine with explicit transitions between states.
 *
 * `FSM` keeps track of one current state and only allows transitions that are
 * explicitly registered on that state. This keeps state flow easy to reason
 * about: if there is no transition, [`goto`](s.FSM.goto) simply does nothing.
 *
 * Typical usage:
 * ```haxe
 * var idle = new State();
 * var walking = new State();
 *
 * idle[walking] = () -> trace("start walking");
 * walking[idle] = () -> trace("stop walking");
 *
 * var fsm = new FSM(idle);
 * fsm.goto(walking);
 * ```
 */
class FSM {
	/**
	 * Current active state.
	 *
	 * This field can be assigned directly, but in normal usage transitions should
	 * go through [`goto`](s.FSM.goto) so transition callbacks are respected.
	 */
	public var current:State;

	/**
	 * Creates a finite state machine.
	 *
	 * @param state Initial state. May be `null`, in which case [`goto`](s.FSM.goto)
	 * cannot do anything until a state is assigned.
	 */
	public function new(?state:State) {
		this.current = state;
	}

	/**
	 * Transitions to another state if the current state defines a transition for it.
	 *
	 * If the transition exists, the target state becomes current and the
	 * transition callback is invoked immediately.
	 *
	 * @param to Target state.
	 */
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

/**
 * State descriptor used by [`FSM`](s.FSM).
 *
 * States store outgoing transitions as callbacks keyed by target state. The
 * state object itself does not contain behavior beyond transition bookkeeping,
 * which keeps it lightweight and easy to compose.
 *
 * Transitions are usually configured with the `[]` operator:
 * ```haxe
 * var a = new State();
 * var b = new State();
 * a[b] = () -> trace("a -> b");
 * ```
 */
@:forward()
@:forward.new
abstract State(StateData) from StateData to StateData {
	/**
	 * Creates a state from a transition map.
	 *
	 * This is mainly a convenience conversion for compact state declarations.
	 *
	 * @param value Map of target states to transition callbacks.
	 * @return The created state.
	 */
	@:from
	static inline function fromMap(value:Map<State, Void->Void>):State {
		return new State(value);
	}

	/**
	 * Adds or replaces a transition to another state.
	 *
	 * When `transition` is omitted, an empty callback is stored so the transition
	 * is still considered valid.
	 *
	 * @param to Target state.
	 * @param transition Callback invoked when the transition is taken.
	 */
	@:op([])
	public function addTransition(to:State, ?transition:Void->Void) {
		this.transitions.set(to, transition ?? () -> {});
	}

	/**
	 * Gets the transition callback for a target state.
	 *
	 * @param to Target state.
	 * @return The transition callback or `null`.
	 */
	@:op([])
	public function getTransition(to:State) {
		return to != null ? this.transitions.get(to) : null;
	}

	/**
	 * Checks whether a transition to a target state exists.
	 *
	 * @param to Target state.
	 * @return `true` if a transition is defined.
	 */
	public function hasTransition(to:State) {
		return this.transitions.exists(to);
	}

	/**
	 * Removes a transition to a target state.
	 *
	 * @param to Target state.
	 */
	public function removeTransition(to:State) {
		this.transitions.remove(to);
	}
}

/**
 * Backing data for [`State`](s.State).
 *
 * This type exists so `State` can stay an abstract wrapper with convenient
 * conversions and operators while the real storage lives in a small concrete
 * object.
 */
class StateData {
	/**
	 * Transition callbacks keyed by target state.
	 *
	 * The map is mutated by the public `State` API and is not usually accessed
	 * directly from gameplay code.
	 */
	public var transitions:Map<StateData, Void->Void>;

	/**
	 * Creates state backing data.
	 *
	 * @param transitions Optional transition map.
	 */
	public function new(?transitions:Map<StateData, Void->Void>) {
		this.transitions = transitions ?? [];
	}
}
