package;

import flixel.FlxSprite;

class OffsettedSprite extends FlxSprite
{
	public var offsets:Map<String, Array<Float>> = [];

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		animation.play(AnimName, Force, Reversed, Frame);
		if (offsets.exists(AnimName))
		{
			var ar = offsets.get(AnimName);
			if (ar.length >= 2)
				offset.set(ar[0], ar[1]);
			else if (ar.length == 1)
				offset.set(ar[0], ar[0]);
			else
				offset.set(0, 0);
		}
		else
			offset.set(0, 0);
	}

	public function addOffset(anim:String, x:Float, y:Float)
		offsets.set(anim, [x, y]);
}
