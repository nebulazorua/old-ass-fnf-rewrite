package compatibility;

import compatibility.Andromeda.SwagSong;
import data.NoteData;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Psych
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
					noteType: TAP,
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

		var json:CharacterFile = cast Json.parse(json);
		var spriteType:String = 'sparrow';
		var image = 'characters/images/' + json.image.replace("characters/", "");
		var packerPath = Paths.getPath('$image.txt', TEXT);
		if (FileSystem.exists(packerPath))
			spriteType = 'packer';

		switch (spriteType)
		{
			case 'packer':
				char.frames = Paths.packer(image);
			case 'sparrow':
				char.frames = Paths.sparrow(image);
		}
		if (json.scale != 1)
		{
			char.setGraphicSize(Std.int(char.width * json.scale));
			char.updateHitbox();
		}
		char.singDuration = json.sing_duration;
		char.posOffset.set(json.position[0], json.position[1]);
		char.antialiasing = !json.no_antialiasing;
		char.flipX = !!json.flip_x;

		var animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
				{
					char.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				}
				else
				{
					char.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}

				if (anim.offsets != null && anim.offsets.length > 1)
				{
					char.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
			}
		}
		else
		{
			char.animation.addByPrefix("idle", "BF idle dance", 24, false);
			// quickAnimAdd('idle', 'BF idle dance');
		}
		if ((char.animation.getByName('danceLeft') != null && char.animation.getByName('danceRight') != null))
		{
			char.danceBeats = 1;
			char.danceSequence = ['danceRight', 'danceLeft'];
		}
	}
}
