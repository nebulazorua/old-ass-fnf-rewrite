package;

import compatibility.Andromeda;
import compatibility.Psych;
import flixel.math.FlxPoint;
import haxe.Json;
import scripts.HScript;
import sys.FileSystem;
import sys.io.File;

using StringTools;

enum JSONType
{
	PSYCH;
	ANDROMEDA_LEGACY;
	ANDROMEDA;
}

typedef CharAnim =
{
	var name:String;
	var prefix:String;
	var fps:Int;
	var looped:Bool;
	var indices:Array<Int>;
	var offset:Array<Int>;
	@:optional var camOffset:Array<Float>;
}

typedef CharacterJSON =
{
	// graphic properties
	var animations:Array<CharAnim>;
	var spritesheet:String;
	var scale:Float;
	var antialiasing:Bool;
	var flipX:Bool;
	// rhythm properties
	var danceBeats:Int;
	var singDuration:Float;
	// offset properties
	var posOffset:Array<Float>;
	var camOffset:Array<Float>;
	// health properties
	var healthIcon:String;
	var healthColor:String;

	// just for compat
	@:optional var format:String;
}

class Character extends OffsettedSprite
{
	public var holdTimer:Float = 0;
	public var posOffset = FlxPoint.get(0, 0);
	public var camOffset = FlxPoint.get(150, -100);
	public var curCharacter:String = '';
	public var singDuration:Float = 4; // in steps
	public var danceSequence:Array<String> = ['idle'];
	public var danceIdx:Int = 0;
	public var danceBeats:Int = 2;
	public var iconName:String;
	@:isVar
	public var isSinging(get, null):Bool = false;

	public var canDance:Bool = true; // whether the character can default to dancing
	public var conductor(default, set):Conductor; // the conductor on which the character dances with

	function set_conductor(newConductor:Conductor)
	{
		var oldConductor:Null<Conductor> = conductor;
		conductor = newConductor;
		if (oldConductor != null)
		{
			if (hscript != null)
				hscript.executeFunc("setConductor", [oldConductor]);
			oldConductor.onBeat.remove(beatHit);
			oldConductor.onStep.remove(stepHit);
		}
		if (hscript != null)
			hscript.set("conductor", conductor);
		if (conductor != null)
		{
			conductor.onBeat.add(beatHit);
			conductor.onStep.add(stepHit);
		}
		return conductor;
	}

	function get_isSinging()
	{
		if (animation.curAnim == null)
			return false;
		return animation.curAnim.name.startsWith("sing") || animation.curAnim.name.startsWith("hold");
	}

	public var hscript:HScript;

	public function dance()
	{
		if (hscript.exists("dance"))
			hscript.executeFunc("dance", []);
		else
		{
			holdTimer = 0;
			danceIdx++;
			if (danceIdx >= danceSequence.length)
				danceIdx = 0;
			var animName = danceSequence[danceIdx];
			playAnim(animName, true);
		}
		hscript.executeFunc("onDance", []);
	}

	public function loadJSON(path:String, type:JSONType)
	{
		switch (type)
		{
			case ANDROMEDA_LEGACY:
				Andromeda.loadCharacter(this, path);
			case PSYCH:
				Psych.loadCharacter(this, path);
			case ANDROMEDA:
				if (FileSystem.exists(path))
					path = File.getContent(path);

				var json:CharacterJSON = cast Json.parse(path);
				var spriteType:String = 'sparrow';
				var image = 'characters/images/' + json.spritesheet;
				var packerPath = Paths.txt(image);
				if (FileSystem.exists(packerPath))
					spriteType = 'packer';

				switch (spriteType)
				{
					case 'packer':
						frames = Paths.packer(image);
					case 'sparrow':
						frames = Paths.sparrow(image);
				}

				if (json.scale != 1)
				{
					setGraphicSize(Std.int(width * json.scale));
					updateHitbox();
				}

				for (anim in json.animations)
				{
					var prefix = anim.prefix;
					var name = anim.name;
					var fps = anim.fps;
					var loop = anim.looped;
					var offset = anim.offset;
					if (offset.length < 2)
						offset = [0, 0];

					if (anim.indices == null)
						animation.addByPrefix(name, prefix, fps, loop);
					else
						animation.addByIndices(name, prefix, anim.indices, "", fps, loop);

					addOffset(name, offset[0], offset[1]);
				}

				singDuration = json.singDuration;
				danceBeats = json.danceBeats;

				posOffset.set(json.posOffset[0], json.posOffset[1]);
				camOffset.set(json.camOffset[0], json.camOffset[1]);
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		hscript.executeFunc("onPlayAnim", [AnimName, Force, Reversed, Frame]);
		return super.playAnim(AnimName, Force, Reversed, Frame);
	}

	public function new(x:Float, y:Float, char:String, ?conductor:Conductor)
	{
		super(x, y);
		curCharacter = char;
		antialiasing = true;
		this.conductor = conductor;
		var hscriptPath:String = Paths.hscript('characters/scripts/$char');
		if (FileSystem.exists(hscriptPath))
		{
			hscript = HScript.fromFile(hscriptPath, char, ["this" => this, "JSONType" => JSONType, "conductor" => this.conductor]);
			hscript.executeFunc("new", []);
		}
		else
			hscript = HScript.fromString("");

		if (hscript.exists("create"))
			hscript.executeFunc("create", []);
		else
		{
			var jsonPath:String = Paths.json('characters/data/$char');
			if (FileSystem.exists(jsonPath))
			{
				var json = cast Json.parse(File.getContent(jsonPath));
				var format = Reflect.field(json, 'format');
				if (Reflect.field(json, 'flip_x') != null)
					format = 'psych';
				else if (Reflect.field(json, 'danceBeats') != null)
					format = 'andromeda2';
				else if (Reflect.field(json, 'singDur') != null)
					format = 'andromeda1';

				switch (format)
				{
					case 'psych':
						loadJSON(jsonPath, PSYCH);
					case 'andromeda1':
						loadJSON(jsonPath, ANDROMEDA_LEGACY);
					case 'andromeda2':
						loadJSON(jsonPath, ANDROMEDA);
					default:
						trace("JSON found, but doesn't fit any supported formats");
				}
			}
			else
			{
				frames = Paths.sparrow('characters/images/DADDY_DEAREST');
				animation.addByPrefix('idle', 'Dad idle dance', 24, false);
				animation.addByPrefix('singUP', 'Dad Sing note UP', 24, false);
				animation.addByPrefix('singRIGHT', 'Dad Sing Note LEFT', 24, false);
				animation.addByPrefix('singDOWN', 'Dad Sing Note DOWN', 24, false);
				animation.addByPrefix('singLEFT', 'dad sing note right', 24, false);

				addOffset('idle', 0, 0);
				addOffset("singUP", -6, 50);
				addOffset("singLEFT", -10, 10);
				addOffset("singRIGHT", 0, 27);
				addOffset("singDOWN", 0, -30);
				singDuration = 6.1;
			}
		}

		dance();

		this.x += posOffset.x;
		this.y += posOffset.y;
	}

	function beatHit(beat:Int)
	{
		if (beat % danceBeats == 0 && !isSinging)
			dance();

		hscript.executeFunc("beatHit", [beat]);
	}

	function stepHit(step:Int)
	{
		if (holdTimer > singDuration * conductor.stepCrochet * 0.001 && isSinging && canDance)
			dance();
		hscript.executeFunc("stepHit", [step]);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		hscript.executeFunc("update", [elapsed]);
		if (isSinging)
			holdTimer += elapsed;
	}

	override function destroy()
	{
		conductor = null; // setting it to null disconnects the default onBeat and onStep events

		hscript.executeFunc("destroy", []); // tell scripts to destroy anything that it may have created
		hscript.stop(); // stop the script
		hscript = null; // and free up memory
		super.destroy();
	}
}
