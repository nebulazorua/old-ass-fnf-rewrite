package states;

import flixel.FlxState;

class MusicState extends FlxState
{
	@:isVar
	public var curBeat(get, null):Float = 0;
	public var curStep(get, null):Float = 0;
	public var conductor:Conductor;

	function get_curBeat()
	{
		return conductor.beat;
	}

	function get_curStep()
	{
		return conductor.step;
	}

	override public function create()
	{
		conductor = new Conductor(100);
		conductor.onBeat.add(beatHit);
		conductor.onStep.add(stepHit);
		super.create();
	}

	override function destroy()
	{
		conductor.onBeat.remove(beatHit);
		conductor.onStep.remove(stepHit);
		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	function beatHit(beat:Int) {}

	function stepHit(step:Int) {}
}
