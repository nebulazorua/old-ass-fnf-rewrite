package input;

import flixel.FlxG;
import lime.app.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

enum ActionState
{
	UP;
	DOWN;
}

typedef KeyEventCallback = (Int, ActionState) -> Void;
typedef BindEventCallback = (String, Int, ActionState) -> Void;
typedef Key = Null<Int>;

class Controls
{
	public static var pressedKeys:Array<Key> = [];
	private static var actions:Map<String, Array<Key>> = [
		"left" => [Keyboard.LEFT, Keyboard.A],
		"down" => [Keyboard.DOWN, Keyboard.S],
		"up" => [Keyboard.UP, Keyboard.K],
		"right" => [Keyboard.RIGHT, Keyboard.L],
		"pause" => [Keyboard.ESCAPE],
		"confirm" => [Keyboard.ENTER, Keyboard.Z],
		"botplay" => [Keyboard.F6]
	];

	// TODO: mouse controls
	public static var keyPressed:Event<KeyEventCallback> = new Event<KeyEventCallback>();
	public static var keyReleased:Event<KeyEventCallback> = new Event<KeyEventCallback>();
	public static var keyChanged:Event<KeyEventCallback> = new Event<KeyEventCallback>();

	public static var onActionChanged:Event<BindEventCallback> = new Event<BindEventCallback>();
	public static var onActionPressed:Event<BindEventCallback> = new Event<BindEventCallback>();
	public static var onActionReleased:Event<BindEventCallback> = new Event<BindEventCallback>();

	public static function setup()
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, keyRelease);
	}

	// event shit
	static function keyPress(event:KeyboardEvent)
	{
		if (FlxG.keys.enabled)
		{
			var code:Int = event.keyCode;
			if (!pressedKeys.contains(code))
			{
				pressedKeys.push(code);
				keyPressed.dispatch(code, DOWN);
				keyChanged.dispatch(code, DOWN);
				for (action in getActionsFromKey(code))
				{
					onActionChanged.dispatch(action, code, DOWN);
					onActionPressed.dispatch(action, code, DOWN);
				}
			}
		}
	}

	static function keyRelease(event:KeyboardEvent)
	{
		if (FlxG.keys.enabled)
		{
			var code:Int = event.keyCode;
			if (pressedKeys.contains(code))
			{
				pressedKeys.remove(code);
				keyReleased.dispatch(code, UP);
				keyChanged.dispatch(code, UP);
				for (action in getActionsFromKey(code))
				{
					onActionChanged.dispatch(action, code, UP);
					onActionReleased.dispatch(action, code, UP);
				}
			}
		}
	}

	// utility functions
	public static function getActionsFromKey(key:Key)
	{
		if (key == null)
			return [];
		var returnedBinds:Array<String> = [];
		for (name => keys in actions)
		{
			if (keys.contains(key))
				returnedBinds.push(name);
		}

		return returnedBinds;
	}

	public inline static function getState(key:Key):ActionState
	{
		return pressedKeys.contains(key) ? DOWN : UP;
	}

	public static function getStateFromAction(name:String):ActionState
	{
		if (actions.exists(name))
		{
			var keys:Array<Int> = actions.get(name);
			for (key in keys)
			{
				if (pressedKeys.contains(key))
					return DOWN;
			}
		}

		return UP;
	}

	// binding functions

	public static function changeBinds(name:String, binds:Array<Key>)
	{
		actions.set(name, binds);
	}

	public static function changeBind(name:String, index:Int, bind:Key)
	{
		if (actions.exists(name))
			actions.get(name)[index] = bind;
	}
}
