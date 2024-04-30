package;

import compatibility.Andromeda;
import compatibility.Kade;
import compatibility.Psych;
import data.NoteData;
import flixel.FlxG;
import haxe.Json;

enum ChartType
{
	SM; // hi hooda
	VANILLA;
	PSYCH;
	ANDROMEDA_LEGACY;
	KADE;
}

class Chart
{
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gf:String = 'gf';
	public var baseBPM:Float = 100;
	public var scrollSpeed:Float = 1.6;
	public var difficulty:String = ''; // maybe int or enum instead
	public var notes:NoteData;
	public var stage:String = 'stage';
	public var songName:String = '';

	public function fromFile(path:String) {}

	public function parseRawJson(text:String, type:ChartType = VANILLA)
	{
		switch (type)
		{
			case VANILLA:

			case SM:

			case PSYCH:
				Psych.parseChart(text, this);
			case KADE:
				Kade.parseChart(text, this);
			case ANDROMEDA_LEGACY:
				Andromeda.parseChart(text, this);
			default:
				FlxG.log.warn("Cannot parse chart!");
		}
	}

	public function new(song:String = 'bopeebo', player1:String = 'bf', player2:String = 'dad', bpm:Float = 100, scrollSpeed:Float = 1.6)
	{
		notes = new NoteData();
		this.songName = song;
		this.player1 = player1;
		this.player2 = player2;
		this.baseBPM = bpm;
		this.scrollSpeed = scrollSpeed;
	}
}
