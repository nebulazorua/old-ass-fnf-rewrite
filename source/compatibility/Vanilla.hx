package compatibility;

import haxe.exceptions.NotImplementedException;

class Vanilla
{
	public static function parseChart(rawJson:String, chart:Chart) {}

	public static function loadTxtOffsets(path:String, char:Character) // week 7
	{
		var offsets = Paths.splitTxt(path);

		for (s in offsets)
		{
			var stuff:Array<String> = s.split(" ");
			char.addOffset(stuff[0], Std.parseFloat(stuff[1]), Std.parseFloat(stuff[2]));
		}
	}

	public static function loadCharacter(char:Character, json:String)
	{
		throw new NotImplementedException();
	}
}
