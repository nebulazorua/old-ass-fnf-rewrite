package;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FPSDisplay extends TextField
{
	private var times:Array<Float> = [];

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFF)
	{
		super();
		this.x = x;
		this.y = y;
		defaultTextFormat = new TextFormat("_sans", 12, color);
		width = 1280;
		height = 720;
		addEventListener(Event.ENTER_FRAME, onEnter);
		text = "FPS: 144";
	}

	private function onEnter(_)
	{
		var currentTime = Timer.stamp();
		times.push(currentTime);
		while (times[0] < currentTime - 1)
			times.shift();

		text = 'FPS: ${times.length}';
	}
}
