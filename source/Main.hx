package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import input.*;
import openfl.Lib;
import openfl.display.Sprite;
import scripts.HScript;

class Main extends Sprite
{
	public static var gameWidth:Int = 1280;
	public static var gameHeight:Int = 720;
	public static var initialState:Class<FlxState> = states.PlayState;
	public static var zoom:Float = -1;
	public static var frameRate:Int = 800;
	public static var splashScreen:Bool = true;
	public static var fullscreen:Bool = false;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();
		Controls.setup();
		HScript.init();

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, frameRate, frameRate, splashScreen, fullscreen));
		addChild(new FPSDisplay(10, 10, 0xFFFFFF));
		FlxG.fixedTimestep = true;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;
	}
}
