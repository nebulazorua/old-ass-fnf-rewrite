package scripts;

import data.Judgements;
import data.NoteData;
import flixel.FlxG;
import flixel.system.FlxSound;
import gameplay.Notefield;
import gameplay.Player;
import gameplay.Receptor;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import lime.utils.AssetType;
import lime.utils.Assets;
import openfl.display.BlendMode;
import scripts.Globals.*;
import states.PlayState;
import sys.io.File;

class HScript extends BaseScript
{
	static var parser:Parser = new Parser();

	public static function init() // BRITISH
	{
		parser.allowMetadata = true;
		parser.allowJSON = true;
		parser.allowTypes = true;
	}

	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>)
	{
		if (name == null)
			name = file;
		return fromString(File.getContent(file), name, additionalVars);
	}

	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		var expr:Expr;
		try
		{
			parser.line = 1;
			expr = parser.parseString(script, name);
		}
		catch (e:haxe.Exception)
		{
			trace(e.details());
			FlxG.log.error("Error parsing hscript: " + e.message);
			expr = parser.parseString("", name);
		}
		return new HScript(expr, name, additionalVars);
	}

	public static function parseFile(file:String, ?name:String)
	{
		if (name == null)
			name = file;
		return parseString(File.getContent(file), name);
	}

	public static function parseString(script:String, ?name:String = "Script")
	{
		return parser.parseString(script, name);
	}

	var interpreter:Interp;

	override public function scriptTrace(text:String)
	{
		var posInfo = interpreter.posInfos();
		haxe.Log.trace(text, posInfo);
	}

	public function new(parsed:Expr, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		scriptType = 'hscript';
		scriptName = name;

		interpreter = new Interp();

		setDefaultVars();
		set("FlxG", flixel.FlxG);
		set("FlxSprite", flixel.FlxSprite);
		set("Std", Std);
		set("state", flixel.FlxG.state);
		set("Math", Math);
		set("Assets", Assets);
		set("FlxSound", FlxSound);
		set("OpenFlAssets", openfl.utils.Assets);
		set("FlxCamera", flixel.FlxCamera);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxSave", flixel.util.FlxSave); // should probably give it 1 save instead of giving it FlxSave
		set("FlxBar", flixel.ui.FlxBar);
		set("StringTools", StringTools);
		set("BlendMode", { // because abstract enums are DUMB!! and importEnum doesnt seem to be working
			ADD: BlendMode.ADD,
			ALPHA: BlendMode.ALPHA,
			DARKEN: BlendMode.DARKEN,
			DIFFERENCE: BlendMode.DIFFERENCE,
			ERASE: BlendMode.ERASE,
			HARDLIGHT: BlendMode.HARDLIGHT,
			INVERT: BlendMode.INVERT,
			LAYER: BlendMode.LAYER,
			LIGHTEN: BlendMode.LIGHTEN,
			MULTIPLY: BlendMode.MULTIPLY,
			NORMAL: BlendMode.NORMAL,
			OVERLAY: BlendMode.OVERLAY,
			SCREEN: BlendMode.SCREEN,
			SHADER: BlendMode.SHADER,
			SUBTRACT: BlendMode.SUBTRACT
		});
		set("trace", function(text:String)
		{
			scriptTrace(text);
		});
		set("getClass", function(className:String)
		{
			return Type.resolveClass(className);
		});
		set("getEnum", function(enumName:String)
		{
			return Type.resolveEnum(enumName);
		});
		set("importClass", function(className:String)
		{
			// importClass("flixel.util.FlxSort") should give you FlxSort.byValues, etc
			// i would LIKE to do like.. flixel.util.* but idk if I can get everything in a namespace
			var classSplit:Array<String> = className.split(".");
			var daClassName = classSplit[classSplit.length - 1]; // last one
			if (daClassName == '*')
			{
				var daClass = Type.resolveClass(className);
				while (classSplit.length > 0 && daClass == null)
				{
					daClassName = classSplit.pop();
					daClass = Type.resolveClass(classSplit.join("."));
					if (daClass != null)
						break;
				}
				if (daClass != null)
				{
					for (field in Reflect.fields(daClass))
					{
						set(field, Reflect.field(daClass, field));
					}
				}
				else
				{
					FlxG.log.error('Could not import class ${daClass}');
					scriptTrace('Could not import class ${daClass}');
				}
			}
			else
			{
				var daClass = Type.resolveClass(className);
				set(daClassName, daClass);
			}
		});

		set("importEnum", function(enumName:String)
		{
			// same as importClass, but for enums
			// and it cant have enum.*;
			var splitted:Array<String> = enumName.split(".");
			var daEnum = Type.resolveEnum(enumName);
			if (daEnum != null)
				set(splitted.pop(), daEnum);
		});

		// FNF-specific things
		set("PlayState", PlayState);
		set("Paths", Paths);
		set("Conductor", Conductor);
		set("ReceptorStatus", ReceptorStatus);
		set("Notefield", Notefield);
		set("NoteData", NoteData);
		set("Player", Player);
		set("Receptor", Receptor);
		set("Judgements", Judgements);
		var currentState = flixel.FlxG.state;
		if ((currentState is PlayState))
		{
			var state:PlayState = cast currentState;
			set("global", state.hscriptGlobals);
			set("conductor", state.conductor);
		}
		set("state", flixel.FlxG.state);

		if (additionalVars != null)
		{
			for (key in additionalVars.keys())
				set(key, additionalVars.get(key));
		}

		trace('loading hscript ${scriptName}');
		try
		{
			interpreter.execute(parsed);
			trace('executed ${scriptName}');
		}
		catch (e:haxe.Exception)
		{
			trace('Error running hscript: ${e.details()}');
			FlxG.log.error("Error running hscript: " + e.message);
		}
	}

	override public function stop()
	{
		// idk if there's really a stop function or anythin for hscript so
		interpreter = null;
	}

	override public function get(varName:String):Dynamic
	{
		return interpreter.variables.get(varName);
	}

	override public function set(varName:String, value:Dynamic):Void
	{
		interpreter.variables.set(varName, value);
	}

	public function exists(varName:String)
	{
		return interpreter.variables.exists(varName);
	}

	override public function call(func:String, ?parameters:Array<Dynamic>):Dynamic
	{
		var returnValue:Dynamic = executeFunc(func, parameters);
		return returnValue;
	}

	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		if (extraVars == null)
			extraVars = [];
		if (exists(func))
		{
			var daFunc = get(func);
			if (Reflect.isFunction(daFunc))
			{
				var returnVal:Any = null;
				var defaultShit:Map<String, Dynamic> = [];
				for (key in extraVars.keys())
				{
					defaultShit.set(key, get(key));
					set(key, extraVars.get(key));
				}
				try
				{
					returnVal = Reflect.callMethod(this, daFunc, parameters);
				}
				catch (e:haxe.Exception)
				{
					Sys.println(e.message);
				}
				for (key in defaultShit.keys())
				{
					set(key, defaultShit.get(key));
				}
				return returnVal;
			}
		}
		return null;
	}
}
