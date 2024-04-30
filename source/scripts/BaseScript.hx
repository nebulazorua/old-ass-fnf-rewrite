package scripts;

using StringTools;

/**
	This is a base class meant to be overridden so you can easily implement custom script types
**/
//
class BaseScript
{
	public var scriptName:String = '';
	public var scriptType:String = '';

	/**
		Called when the script should be stopped
	**/
	public function stop()
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	/**
		Called to output debug information
	**/
	public function scriptTrace(text:String)
	{
		trace(text); // wow for once its not NotImplementedException
	}

	/**
		Called to set a variable defined in the script
	**/
	public function set(variable:String, data:Dynamic):Void
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	/**
		Called to get a variable defined in the script
	**/
	public function get(key:String):Dynamic
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	/**
		Called to call a function within the script
	**/
	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	/**
		Helper function
		Sets a bunch of basic variables for the script depending on the state
	**/
	function setDefaultVars()
	{
		var currentState = flixel.FlxG.state;
	}
}

interface IBaseScript
{
	public var scriptName:String;
	public var scriptType:String;
	public function set(variable:String, data:Dynamic):Void;
	public function get(key:String):Dynamic;
	public function call(func:String, ?args:Array<Dynamic>):Dynamic;
	public function stop():Void;
}
