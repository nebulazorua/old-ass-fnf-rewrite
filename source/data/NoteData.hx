package data;

import flixel.FlxSprite;
import data.Judgements;

// XXX: Maybe make it deal in rows instead of time, like in Stepmania

typedef HitResult =
{
	var difference:Float;
	var judgement:Judgement;
}

typedef HoldResult =
{
	var beingHeld:Bool; // if it is currently held down
	var tripTimer:Float;
	var judgement:HoldJudge;
	@:optional var hitSegments:Float;
}

enum HoldJudge
{
	NONE; // unhit, idle
	TRIPPED; // player was holding, but released it
	MISSED; // player never hit the tap
	OK; // held fully
}

enum HoldType
{
	NONE;
	HOLD;
	ROLL;
}

enum NoteType
{
	TAP;
	ALT_ANIM;
	MINE;
	FAKE;
	CUSTOM;
}

typedef Note =
{
	var hitTime:Float; // time when you hit the note
	var direction:Int; // the direction of the note
	var duration:Float; // the duration of the attached hold, if applicable
	var quant:NoteQuant; // the quant of the note
	var playerNum:Int; // 0 for player, 1 for opponent
	var hitResult:HitResult; // the result of when you hit a note. judgement and timing info
	var holdResult:HoldResult; // used to tell if the note is being held or not
	var noteType:NoteType; // used to tell ifits a mine, etc
	var holdType:HoldType; // used to tell if its a hold, roll, etc
	@:optional var sprite:FlxSprite; // used to tell the playfield what to render
	@:optional var customType:Int; // used for noteType == CUSTOM
}

enum NoteQuant
{
	N_4TH;
	N_8TH;
	N_12TH;
	N_16TH;
	N_24TH;
	N_32ND;
	N_48TH;
	N_64TH;
	N_192ND;
}

class NoteData
{
	// Class
	public var notes:Array<Array<Note>>;

	public function removeStacked()
	{
		for (column in notes)
		{
			var dead:Array<Note> = [];
			column.sort((a, b) -> Std.int(a.hitTime - b.hitTime));
			var last:Null<Note> = null;
			for (note in column)
			{
				if (last != null)
				{
					if (Math.abs(last.hitTime - note.hitTime) <= 4)
					{
						dead.push(note);
						continue;
					}
				}
				last = note;
			}

			for (note in dead)
				column.remove(note);
			last = null;
		}
	}

	public function new()
	{
		notes = [];
		for (i in 0...4)
			notes[i] = [];
	}

	public function push(note:Note)
		notes[note.direction].push(note);

	// Utility
	public static var ROWS_PER_BEAT = 48; // from Stepmania
	public static var BEATS_PER_MEASURE = 4; // TODO: time sigs
	public static var ROWS_PER_MEASURE = ROWS_PER_BEAT * BEATS_PER_MEASURE; // from Stepmania
	public static var MAX_NOTE_ROW = 1 << 30; // from Stepmania

	static var conversionMap:Map<Int, NoteQuant> = [
		64 => N_64TH,
		48 => N_48TH,
		32 => N_32ND,
		24 => N_24TH,
		16 => N_16TH,
		12 => N_12TH,
		8 => N_8TH,
		4 => N_4TH
	];

	public static function quantToBeat(quant:NoteQuant):Float
	{
		switch (quant)
		{
			case N_4TH:
				return 1;
			case N_8TH:
				return 1 / 2;
			case N_12TH:
				return 1 / 3;
			case N_16TH:
				return 1 / 4;
			case N_24TH:
				return 1 / 6;
			case N_32ND:
				return 1 / 8;
			case N_48TH:
				return 1 / 12;
			case N_64TH:
				return 1 / 16;
			default:
				return 1 / 48;
		}
	}

	public static function quantToString(quant:NoteQuant)
	{
		switch (quant)
		{
			case N_4TH:
				return '4th';
			case N_8TH:
				return '8th';
			case N_12TH:
				return '12th';
			case N_16TH:
				return '16th';
			case N_24TH:
				return '24th';
			case N_32ND:
				return '32nd';
			case N_48TH:
				return '48th';
			case N_64TH:
				return '64th';
			default:
				return '192nd';
		}
	}

	public inline static function beatToQuant(beat:Float):NoteQuant
		return rowToQuant(beatToRow(beat));

	public inline static function beatToRow(beat:Float):Int
		return Math.round(beat * ROWS_PER_BEAT);

	public inline static function rowToBeat(row:Int):Float
		return row / ROWS_PER_BEAT;

	public static function rowToQuant(row:Int):NoteQuant
	{
		for (key in conversionMap.keys())
		{
			if (row % (ROWS_PER_MEASURE / key) == 0)
				return conversionMap.get(key);
		}
		return N_192ND;
	}
}
