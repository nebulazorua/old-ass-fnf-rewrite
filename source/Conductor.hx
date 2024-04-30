package;

import lime.app.Event;

typedef BPMChange =
{
	var time:Float;
	var beat:Float;
	var step:Float;
}

class Conductor
{
	public var onBeat:Event<Int->Void> = new Event<Int->Void>();
	public var onStep:Event<Int->Void> = new Event<Int->Void>();
	public var onBpmChange:Event<(Float, Float) -> Void> = new Event<(Float, Float) -> Void>();
	public var bpm(default, set):Float = 0;
	public var crochet:Float = 0;
	public var stepCrochet:Float = 0;
	public var time(default, set):Float = 0; // in milliseconds
	public var rawTime:Float = 0;
	public var visualTime:Float = 0;

	// public var time:Float = 0;
	// for bpm changing on-the-fly
	@:isVar
	public var lastBeat(get, null):Float = 0;
	@:isVar
	public var lastStep(get, null):Float = 0;
	@:isVar
	public var lastTime(get, null):Float = 0;

	var bpmChanges:Array<BPMChange> = [
		{
			step: 0,
			beat: 0,
			time: 0
		}
	];

	function get_lastTime()
		return bpmChanges.length == 0 ? 0 : bpmChanges[bpmChanges.length - 1].time;

	function get_lastStep()
		return bpmChanges.length == 0 ? 0 : bpmChanges[bpmChanges.length - 1].step;

	function get_lastBeat()
		return bpmChanges.length == 0 ? 0 : bpmChanges[bpmChanges.length - 1].beat;

	@:isVar
	public var beat(get, null):Float = 0;
	@:isVar
	public var step(get, null):Float = 0;
	@:isVar
	public var roundBeat(get, null):Int = 0;
	@:isVar
	public var roundStep(get, null):Int = 0;

	var lastHitBeat:Int = 0;
	var lastHitStep:Int = 0;

	// accessors

	function set_time(newTime:Float)
	{
		time = newTime;
		// maybe do the beatHit/stepHit shit in an update function that gets called by the state?
		if (roundBeat > lastHitBeat)
		{
			for (beat in Math.floor(lastHitBeat)...roundBeat)
				onBeat.dispatch(beat);

			lastHitBeat = roundBeat;
		}
		if (roundStep > lastHitStep)
		{
			for (beat in Math.floor(lastHitStep)...roundStep)
				onStep.dispatch(beat);

			lastHitStep = roundStep;
		}
		return time;
	}

	function set_bpm(newBPM:Float)
	{
		crochet = (60 / newBPM) * 1000;
		stepCrochet = crochet / 4;
		return bpm = newBPM;
	}

	function get_beat()
	{
		return lastBeat + ((time - lastTime) / crochet);
	}

	function get_step()
	{
		return lastStep + ((time - lastTime) / stepCrochet);
	}

	function get_roundBeat()
	{
		return Math.floor(get_beat());
	}

	function get_roundStep()
	{
		return Math.floor(get_step());
	}

	// class functions
	public function changeBPM(newBPM:Float, ?dontResetBeat:Bool = true)
	{
		if (crochet != 0 && dontResetBeat)
		{
			bpmChanges.push({
				beat: beat,
				step: step,
				time: time
			});
			bpmChanges.sort((a, b) -> Std.int(a.time - b.time));
			// might wanna use a map and not allow on-the-fly bpm changing? idk
		}
		onBpmChange.dispatch(bpm, newBPM);
		bpm = newBPM;
	}

	public function getBeat(time:Float)
	{
		return lastBeat + ((time - lastTime) / crochet);
	}

	public function getStep(time:Float)
	{
		return lastStep + ((time - lastTime) / stepCrochet);
	}

	public function new(curBpm:Float = 100)
	{
		bpm = curBpm;
	}

	public function destroy()
	{
		onBeat.cancel();
		onStep.cancel();
		onBeat.removeAll();
		onStep.removeAll();
		onStep = null;
		onBeat = null;
	}
}
