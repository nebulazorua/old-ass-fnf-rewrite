package gameplay;

import data.Judgements;
import data.NoteData;
import flixel.FlxG;
import flixel.group.FlxGroup;

class Player extends FlxGroup
{
	public var x:Float = 0;
	public var y:Float = 0;

	public var field:Notefield;
	public var data:NoteData;
	public var score:Int = 0;
	public var combo:Int = 0;
	public var missCombo:Int = 0;
	public var pn:Int = 1;
	public var pressed:Array<Bool> = [false, false, false, false];
	public var character:Character;

	public var autoPlayed:Bool = false;
	public var humanPlayer:Bool = true;

	var conductor:Conductor;
	var pressTimer:Array<Float> = [0, 0, 0, 0]; // for autoplaying

	// callbacks
	public var noteHitCallback:(Note, Player) -> Void;
	public var noteMiss:(Note, Player) -> Void;
	public var holdSegmentCallback:(Note, Player) -> Void;
	public var holdPressCallback:(Note, Player) -> Void;
	public var holdReleaseCallback:(Note, Player) -> Void;
	public var holdJudgeCallback:(Note, Player) -> Void; // called when the judgement of a hold changes

	public function new(x:Float, y:Float, playerNumber:Int, notedata:NoteData, conductor:Conductor, ?character:Character)
	{
		super();
		pn = playerNumber;
		data = notedata;

		field = new Notefield(x, y, conductor, data);
		this.conductor = conductor;
		this.character = character;
		add(field);
	}

	public function input(note:Note, time:Float)
	{
		var difference = note.hitTime - time;
		var judge:Judgement = Judgements.judgeNote(note, time);

		if (judge != TS_NONE)
		{
			if (note.holdType == NONE)
				field.data.notes[note.direction].remove(note);
			else
			{
				// this note is a hold so do all that shit
				note.holdResult.beingHeld = true;
				note.holdResult.tripTimer = 1;
			}

			note.hitResult.difference = difference;
			note.hitResult.judgement = judge;
			noteHitCallback(note, this);
			return note;
		}
		return null;
	}

	public function handleInput(column:Int, time:Float)
	{
		var theData = field.existingNotes[column];
		for (idx in 0...theData.length)
		{
			var noteToHit = theData[idx];
			if (noteToHit != null && noteToHit.hitResult.judgement == TS_NONE)
			{
				var r = input(noteToHit, time);
				if (r != null)
					return r;
			}
		}

		return null;
	}

	function autoplayShouldIgnore(note:Note)
	{
		return note.noteType == MINE || note.noteType == FAKE;
	}

	override public function update(elapsed:Float)
	{
		if (autoPlayed)
		{
			var newPressed:Array<Bool> = [];
			for (idx in 0...pressTimer.length)
			{
				newPressed[idx] = false;
				if (pressTimer[idx] > 0)
				{
					pressTimer[idx] -= elapsed * 1000;
					if (pressTimer[idx] <= 0)
						field.members[idx].setStatus(IDLE);
					else
						newPressed[idx] = true;
				}
			}
			for (column in field.existingNotes)
			{
				for (idx in 0...column.length)
				{
					var noteToHit:Note = column[idx];
					if (noteToHit != null && noteToHit.hitResult.judgement == TS_NONE)
					{
						var judge = Judgements.judgeNote(noteToHit, conductor.time);
						if (noteToHit.hitTime <= conductor.time && judge != HIT_MINE && judge != TS_NONE)
						{
							// handleInput(noteToHit.direction, conductor.time);
							input(noteToHit, conductor.time);
							pressTimer[noteToHit.direction] = noteToHit.duration + conductor.stepCrochet;
							newPressed[noteToHit.direction] = true;
						}
					}
				}
			}
			pressed = newPressed;
		}
		else {}

		// update hold notes
		for (idx in 0...field.existingNotes.length)
		{
			var dead:Array<Note> = [];
			var column = field.existingNotes[idx];
			for (note in column)
			{
				if (note.hitResult.judgement != TS_NONE && note.duration > 0) // if the note's been judged, then it's been hit
				{
					var wasHeld = note.holdResult.beingHeld;
					var isPressed = pressed[idx];
					note.holdResult.beingHeld = isPressed;
					if (wasHeld != isPressed)
					{
						if (isPressed && holdPressCallback != null)
							holdPressCallback(note, this);
						else if (!isPressed && holdReleaseCallback != null)
							holdReleaseCallback(note, this);
					}

					if (note.holdResult.beingHeld)
						note.holdResult.tripTimer = 1;
					else
						note.holdResult.tripTimer -= elapsed / 0.1;
					var endTime:Float = note.hitTime + note.duration;

					var diff = endTime - conductor.time;
					var heldTime = note.duration - diff;
					if (heldTime < 0)
						heldTime = 0;
					if (heldTime > note.duration)
						heldTime = note.duration;

					var hitSegs = Math.ceil(heldTime / conductor.stepCrochet);

					if (note.holdResult.hitSegments == null)
						note.holdResult.hitSegments = hitSegs;

					if (note.holdResult.tripTimer <= 0)
					{
						note.holdResult.judgement = TRIPPED;
						if (holdJudgeCallback != null)
							holdJudgeCallback(note, this);
					}
					else if (diff <= 0)
					{
						note.holdResult.judgement = OK;
						if (holdJudgeCallback != null)
							holdJudgeCallback(note, this);
						dead.push(note);
					}

					if (note.holdResult.hitSegments != hitSegs)
					{
						note.holdResult.hitSegments = hitSegs;
						if (holdSegmentCallback != null)
							holdSegmentCallback(note, this);
					}
				}
			}
			for (note in dead)
				column.remove(note);
		}

		// update misses, etc
		for (column in field.existingNotes)
		{
			var dead:Array<Note> = [];
			for (note in column)
			{
				var missed = (note.hitTime - conductor.time) < -Judgements.hitWindow && note.hitResult.judgement == TS_NONE;
				if (missed)
					note.holdResult.judgement = MISSED;

				var canRemove = missed || note.hitResult.judgement != TS_NONE && note.holdResult.judgement != NONE;

				if (missed && noteMiss != null)
					noteMiss(note, this);

				if (canRemove)
				{
					dead.push(note); // dead note!!!
				}
			}
			for (note in dead)
				field.data.notes[note.direction].remove(note);
		}
		super.update(elapsed);
	}
}
