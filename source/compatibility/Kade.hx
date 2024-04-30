package compatibility;

import data.NoteData;
import haxe.Json;

using StringTools;

typedef SongData =
{
	var ?song:String;

	/**
	 * The readable name of the song, as displayed to the user.
	 		* Can be any string.
	 */
	var songName:String;

	/**
	 * The internal name of the song, as used in the file system.
	 */
	var ?songId:String;

	var chartVersion:String;
	var notes:Array<KadeSwagSection>;
	var eventObjects:Array<KadeEvent>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var player1:String;
	var player2:String;
	var gfVersion:String;
	var noteStyle:String;
	var stage:String;
	var ?validScore:Bool;
	var ?offset:Int;
}

typedef KadeSwagSection =
{
	var startTime:Float;
	var endTime:Float;
	var sectionNotes:Array<Array<Dynamic>>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
	var CPUAltAnim:Bool;
	var playerAltAnim:Bool;
}

class KadeEvent
{
	public var name:String;
	public var position:Float;
	public var value:Float;
	public var type:String;

	public function new(name:String, pos:Float, value:Float, type:String)
	{
		this.name = name;
		this.position = pos;
		this.value = value;
		this.type = type;
	}
}

class Kade
{
	public static function parseChart(rawJson:String, chart:Chart)
	{
		var chartFile:SongData = cast Json.parse(rawJson).song;
		if (chartFile.chartVersion == 'KE1' || chartFile.songId == null || chartFile.songId.trim() == '')
			chartFile.songId = chartFile.song;
		chart.baseBPM = chartFile.bpm;
		chart.player1 = chartFile.player1;
		chart.player2 = chartFile.player2;
		chart.gf = chartFile.gfVersion;

		chart.scrollSpeed = chartFile.speed;
		chart.songName = chartFile.songId;
		chart.stage = chartFile.stage;
		var tempConductor = new Conductor(chart.baseBPM);

		for (section in chartFile.notes)
		{
			for (note in section.sectionNotes)
			{
				var pNum:Int = section.mustHitSection ? 0 : 1;
				if (note[1] > 3)
					pNum = pNum == 0 ? 1 : 0;
				var noteQuant = NoteData.beatToQuant(note[4]);
				var holdDuration = Math.floor(note[2] / tempConductor.stepCrochet) * tempConductor.stepCrochet;
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
						tripTimer: 0,
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

	public function new() {}
}
