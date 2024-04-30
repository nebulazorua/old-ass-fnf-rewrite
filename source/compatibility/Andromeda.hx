package compatibility;

import data.NoteData;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import openfl.display.BitmapData;
import sys.FileSystem;
import sys.io.File;

typedef AnimShit =
{
	var prefix:String;
	var name:String;
	var fps:Int;
	var looped:Bool;
	var offsets:Array<Float>;
	@:optional var indices:Array<Int>;
}

typedef CharJson =
{
	var anims:Array<AnimShit>;
	var spritesheet:String;
	var singDur:Float; // dadVar
	var iconName:String;
	var healthColor:String;
	var charOffset:Array<Float>;
	var beatDancer:Bool; // dances every beat like gf and spooky kids
	var flipX:Bool;

	@:optional var format:String;
	@:optional var camMovement:Float;
	@:optional var camOffset:Array<Float>;
	@:optional var scale:Float;
	@:optional var antialiasing:Bool;
}

typedef VelocityChange =
{
	var startTime:Float;
	var multiplier:Float;
}

typedef SwagSong =
{
	var song:String;
	var notes:Array<AndroSwagSection>;
	var bpm:Int;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var stage:String;
	var validScore:Bool;
	var noteModifier:String;
	@:optional var format:String;
	@:optional var sliderVelocities:Array<VelocityChange>;
	@:optional var initialSpeed:Float;
}

typedef Event =
{
	@:optional var time:Float;
	@:optional var name:String;
	@:optional var args:Array<Dynamic>;

	@:optional var events:Array<Event>;
}

typedef AndroSwagSection =
{
	var sectionNotes:Array<Array<Dynamic>>;
	@:optional var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Int;
	var changeBPM:Bool;
	var altAnim:Bool;
	@:optional var events:Array<Event>;
}

class Andromeda
{
	public static function parseChart(rawJson:String, chart:Chart)
	{
		var chartFile:SwagSong = cast Json.parse(rawJson).song;
		chart.baseBPM = chartFile.bpm;
		chart.player1 = chartFile.player1;
		chart.player2 = chartFile.player2;
		chart.scrollSpeed = chartFile.speed;
		chart.songName = chartFile.song;
		chart.stage = chartFile.stage;
		var tempConductor = new Conductor(chart.baseBPM);

		for (section in chartFile.notes)
		{
			for (note in section.sectionNotes)
			{
				var pNum:Int = section.mustHitSection ? 0 : 1;
				if (note[1] > 3)
					pNum = pNum == 0 ? 1 : 0;
				var noteQuant = NoteData.beatToQuant(tempConductor.getBeat(note[0]));
				var holdDuration = Math.round(note[2] / tempConductor.stepCrochet) * tempConductor.stepCrochet;
				var type = TAP;
				switch (note[3]) // TODO: array/map
				{
					case 1:
						type = ALT_ANIM;
					case 2:
						type = MINE;
					case 3:
						type = FAKE;
					default:
						type = TAP;
				}

				chart.notes.push({
					hitTime: note[0], // time when you hit the note
					direction: Math.floor(note[1] % 4), // the direction of the note
					duration: holdDuration, // the duration of the attached hold, if applicable
					quant: noteQuant, // the quant of the note
					playerNum: pNum, // 0 for player, 1 for opponent
					hitResult: {
						difference: 0,
						judgement: TS_NONE
					},
					holdResult: {
						tripTimer: 0, // how long its been held
						beingHeld: false,
						judgement: NONE
					},
					noteType: type,
					holdType: holdDuration > 0 ? HOLD : NONE
				});
			}
		}
		trace("chart read");
		tempConductor = null;
	}

	public static function loadCharacter(char:Character, json:String)
	{
		if (FileSystem.exists(json))
			json = File.getContent(json);

		var charData:CharJson = cast Json.parse(json);

		var chars = "assets/characters/images/";

		var spritesheet = charData.spritesheet;
		var path = chars + spritesheet;

		// NOTE: should probably use paths here
		if (FileSystem.exists(path + ".png"))
		{
			var image = FlxG.bitmap.get(path);
			if (image == null)
				image = FlxG.bitmap.add(BitmapData.fromFile(path + ".png"), false, path);

			if (FileSystem.exists(path + ".txt"))
				char.frames = FlxAtlasFrames.fromSpriteSheetPacker(image, File.getContent(path + ".txt"));
			else if (FileSystem.exists(path + ".xml"))
				char.frames = FlxAtlasFrames.fromSparrow(image, File.getContent(path + ".xml"));
		}

		for (anim in charData.anims)
		{
			var prefix = anim.prefix;
			var name = anim.name;
			var fps = anim.fps;
			var loop = anim.looped;
			var offset = anim.offsets;
			if (offset.length < 2)
				offset = [0, 0];

			if (anim.indices == null)
				char.animation.addByPrefix(name, prefix, fps, loop);
			else
				char.animation.addByIndices(name, prefix, anim.indices, "", fps, loop);

			char.addOffset(name, offset[0], offset[1]);
		}
		char.posOffset.set(charData.charOffset[0], charData.charOffset[1]);
		if (charData.camOffset != null)
			char.camOffset.set(charData.camOffset[0], charData.camOffset[1]);

		if (charData.antialiasing != null)
			char.antialiasing = charData.antialiasing;
		else
			char.antialiasing = true;

		char.singDuration = charData.singDur;
		if (charData.beatDancer)
			char.danceBeats = 1;

		if (charData.scale != null && charData.scale != 1)
		{
			char.setGraphicSize(Std.int(char.width * charData.scale));
			char.updateHitbox();
		}

		if (char.animation.getByName("danceLeft") != null && char.animation.getByName("danceRight") != null)
			char.danceSequence = ["danceLeft", "danceRight"];
	}
}
