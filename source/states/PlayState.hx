package states;

import data.Judgements;
import data.NoteData.Note;
import data.NoteData;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import gameplay.Notefield;
import gameplay.Player;
import gameplay.Receptor.ReceptorStatus;
import gameplay.Receptor;
import input.Controls;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import scripts.HScript;
import states.substates.PauseSubstate;
import sys.io.File;

class PlayState extends MusicState
{
	// misc shit
	var paused:Bool = false;
	var pressed:Array<Bool> = [false, false, false, false];

	public var hscriptGlobals:Map<String, Any> = [];

	// characters
	public var bf:Character;
	public var opponent:Character;
	public var gf:Character;

	// cameras
	public var noteCam:FlxCamera;
	public var gameCam:FlxCamera;
	public var holdCam:FlxCamera;
	public var receptorCam:FlxCamera;
	public var hudCam:FlxCamera;

	// sounds
	var inst:FlxSound;
	var voices:FlxSound;

	// notefield / chart / notedata stuff
	public var chart:Chart;

	var playerNotes:NoteData;
	var dadNotes:NoteData;

	public var player1:Player; // the human player
	public var player2:Player; // the opponent

	// stats
	var combo:Int = 0;
	var missCombo:Int = 0;
	var score:Int = 0;
	var hitNotes:Float = 0;
	var maxHitNotes:Float = 0;

	// hud elements
	var scoreText:FlxText;

	// duh code

	override public function create()
	{
		super.create();
		FlxG.fixedTimestep = false;
		Controls.onActionChanged.add(onActionChanged);

		gameCam = new FlxCamera();
		noteCam = new FlxCamera();
		receptorCam = new FlxCamera();
		holdCam = new FlxCamera();
		hudCam = new FlxCamera();
		receptorCam.bgColor.alpha = 0;
		holdCam.bgColor.alpha = 0;
		noteCam.bgColor.alpha = 0;
		hudCam.bgColor.alpha = 0;
		FlxG.cameras.reset(gameCam);
		FlxG.cameras.add(holdCam, false);
		FlxG.cameras.add(receptorCam, false);
		FlxG.cameras.add(noteCam, false);
		FlxG.cameras.add(hudCam, false);

		FlxG.cameras.setDefaultDrawTarget(gameCam, true);

		chart = new Chart();
		// chart.parseRawJson(File.getContent(Paths.chart("gran-venta", "-erect")),
		//		Chart.ChartType.ANDROMEDA_LEGACY); // TODO: write an autodetector for the chart type
		chart.parseRawJson(File.getContent(Paths.chart("ghoul", "")), Chart.ChartType.KADE); // TODO: write an autodetector for the chart type


		conductor.changeBPM(chart.baseBPM, false);
		conductor.time = 0;

		Notefield.loadNotes();

		dadNotes = new NoteData();
		playerNotes = new NoteData();
		for (column in chart.notes.notes)
		{
			for (note in column)
			{
				if (note.playerNum == 1)
					dadNotes.push(note);
				else
					playerNotes.push(note);
			}
		}

		dadNotes.removeStacked();
		playerNotes.removeStacked();

		gf = new Character(400, -50, chart.gf, conductor);
		add(gf);

		opponent = new Character(100, -50, chart.player2, conductor);
		add(opponent);

		bf = new Character(800, -50, chart.player1, conductor);
		add(bf);

		var leftPadding = 40;
		var rightPadding = 40;

		var y:Float = 50;
		var lEdge = 0;
		var rEdge = FlxG.width;
		var space = (FlxG.width / 2) - leftPadding - rightPadding;
		var p1X:Float = rEdge - rightPadding - (space / 2);
		var p2X:Float = lEdge + leftPadding + (space / 2);
		player1 = new Player(p1X, y, 0, playerNotes, conductor, bf);
		player2 = new Player(p2X, y, 1, dadNotes, conductor, opponent);

		player1.autoPlayed = true;
		player2.humanPlayer = false;
		player2.autoPlayed = true;

		player1.noteHitCallback = noteHit;
		player1.noteMiss = noteMiss;
		player1.holdSegmentCallback = holdSegmentHit;
		player1.holdPressCallback = holdPress;
		player1.holdJudgeCallback = holdJudgeCallback;

		player2.noteHitCallback = noteHit;
		player2.noteMiss = noteMiss;
		player2.holdSegmentCallback = holdSegmentHit;
		player2.holdPressCallback = holdPress;
		player2.holdJudgeCallback = holdJudgeCallback;

		player1.field.cameras = [receptorCam];
		player2.field.cameras = [receptorCam];
		player1.field.noteCameras = [noteCam];
		player2.field.noteCameras = [noteCam];
		player1.field.holdCameras = [holdCam];
		player2.field.holdCameras = [holdCam];

		player2.field.noteSpeed = chart.scrollSpeed;
		player1.field.noteSpeed = chart.scrollSpeed;

		add(player1);
		add(player2);

		scoreText = new FlxText(0, FlxG.height * 0.95, 0, "Score: 0 - Accuracy: 100%", 16, true);
		scoreText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK, true);
		scoreText.screenCenter(X);
		scoreText.cameras = [hudCam];
		add(scoreText);

		inst = new FlxSound().loadEmbedded(Paths.inst(chart.songName), false, false);
		voices = new FlxSound().loadEmbedded(Paths.voices(chart.songName), false, false);
		FlxG.sound.list.add(inst);
		FlxG.sound.list.add(voices);
		conductor.time = -conductor.crochet * 3;
	}

	override function closeSubState()
	{
		if (paused)
		{
			paused = false;
			if (conductor.time >= 0)
			{
				inst.play();
				voices.play();
				conductor.time = inst.time;
				conductor.rawTime = inst.time;
				voices.time = inst.time;
			}
		}

		super.closeSubState();
	}

	override public function draw()
	{
		super.draw();
	}

	function onActionChanged(action:String, keyCode:Int, state:ActionState) // called whenever the state of an action changes (gets pressed/released)
	{
		if (paused)
			return;

		switch (action)
		{
			case 'botplay':
				if (state == DOWN)
					player1.autoPlayed = !player1.autoPlayed;
			case 'up' | 'down' | 'left' | 'right':
				if (player1.autoPlayed)
					return;
				var dirs = ["left", "down", "up", "right"];
				var idx = dirs.indexOf(action);
				switch (state)
				{
					case DOWN:
						if (player1.handleInput(idx, conductor.time) == null)
							player1.field.members[idx].setStatus(ReceptorStatus.PRESSED);

						pressed[idx] = true;
						player1.character.canDance = !pressed.contains(true);

					case UP:
						player1.field.members[idx].setStatus(ReceptorStatus.IDLE);
						pressed[idx] = false;
						player1.character.canDance = !pressed.contains(true);
				}
				player1.pressed = pressed;
			case 'pause':
				if (state == DOWN)
				{
					persistentDraw = true;
					persistentUpdate = false;
					paused = true;
					inst.pause();
					voices.pause();
					openSubState(new PauseSubstate());
				}
		}
	}

	function holdJudgeCallback(note:Note, player:Player)
	{
		var receptor = player.field.members[note.direction];
		receptor.runCommand("confirm", ["note" => note]);
		if (note.holdResult.judgement == TRIPPED)
		{
			var anims:Array<String> = ["left", "down", "up", "right"];
			var character = player.character;
			voices.volume = 0;

			character.holdTimer = 0;
			character.playAnim('sing${anims[note.direction].toUpperCase()}miss', true);
			if (player.humanPlayer)
			{
				hitNotes -= 0.5;
				score -= 50;
				updateHUD();
				showHoldJudgement('bad', player.field.members[note.direction]);
			}
		}
		else if (note.holdResult.judgement == OK)
		{
			voices.volume = 1;
			if (player.humanPlayer)
			{
				score += 100;
				updateHUD();
				showHoldJudgement('ok', player.field.members[note.direction]);
			}
		}
		player.field.data.notes[note.direction].remove(note);
	}

	function showMiss(idx:Int, character:Character)
	{
		var anims:Array<String> = ["left", "down", "up", "right"];
		voices.volume = 0;
		character.holdTimer = 0;
		character.playAnim('sing${anims[idx].toUpperCase()}miss', true);
	}

	function noteMiss(note:Note, player:Player)
	{
		switch (note.noteType)
		{
			case FAKE:
				return;
			case MINE:
				note.hitResult.judgement = AVOID_MINE;
			default:
				var character = player.character;
				showMiss(note.direction, character);

				if (player.humanPlayer)
				{
					combo = 0;
					missCombo--;
					judgeNote(note, true);
					// showJudgement('miss', 0);
				}
		}
	}

	function noteHit(note:Note, player:Player)
	{
		// trace('hit note, ${note.hitResult.difference} difference, ${Judgements.getName(note.hitResult.judgement)}');
		switch (note.noteType)
		{
			case MINE:
				note.hitResult.judgement = HIT_MINE;
				var character = player.character;
				showMiss(note.direction, character);
				judgeNote(note, false, true);
				combo = 0;
			default:
				var anims:Array<String> = ["left", "down", "up", "right"];
				var character = player.character;

				voices.volume = 1;
				character.holdTimer = 0;
				var anim = 'sing${anims[note.direction].toUpperCase()}';
				if (note.noteType == ALT_ANIM)
					if (character.animation.exists(anim + "-alt"))
						anim = anim + "-alt";

				character.playAnim(anim, true);
				player.field.members[note.direction].setStatus(CONFIRM, ["note" => note]);

				if (player.humanPlayer)
				{
					combo++;
					missCombo = 0;
					judgeNote(note);
				}
		}
	}

	function holdPress(note:Note, player:Player)
	{
		voices.volume = 1;
		var receptor = player.field.members[note.direction];
		receptor.runCommand("confirm", ["note" => note]);
	}

	function holdSegmentHit(note:Note, player:Player)
	{
		var receptor = player.field.members[note.direction];
		receptor.runCommand("confirm", ["note" => note]);
		var anims:Array<String> = ["left", "down", "up", "right"];
		var character = player.character;
		character.holdTimer = 0;
		var anim = 'sing${anims[note.direction].toUpperCase()}';
		if (note.noteType == ALT_ANIM)
			if (character.animation.exists(anim + "-alt"))
				anim = anim + "-alt";

		character.playAnim(anim, true);
		voices.volume = 1;
	}

	function showHoldJudgement(name:String, rec:Receptor)
	{
		var sprite = Judgements.getHoldSprite(name);
		sprite.x = rec.x - rec.width / 2;
		sprite.y = rec.y + rec.height / 2;
		sprite.cameras = [hudCam];
		FlxTween.tween(sprite, {alpha: 0}, 0.15, {
			ease: FlxEase.linear,
			startDelay: conductor.crochet / 3000,
			onComplete: function(twn:FlxTween)
			{
				sprite.kill();
			}
		});
		add(sprite);
	}

	function truncFloat(num:Float, precision:Int)
	{
		var pow = Math.pow(10, precision);
		return Math.floor(num * pow) / pow;
	}

	function judgeNote(note:Note, ?missed:Bool = false, ?show:Bool = true)
	{
		var data = missed ? Judgements.getByName("miss") : Judgements.get(note.hitResult.judgement);
		score += data.score;
		hitNotes += data.accuracy;
		maxHitNotes++;
		updateHUD();
		if (show)
			showJudgement(data.internalName, note.hitResult.difference);
	}

	function updateHUD()
	{
		scoreText.text = 'Score: $score - Accuracy: ${truncFloat((hitNotes / maxHitNotes) * 100, 2)}%';
		scoreText.screenCenter(X);
	}

	function showJudgement(name:String, diff:Float)
	{
		var sprite = Judgements.getSprite(name);
		sprite.screenCenter(XY);
		sprite.velocity.y = -FlxG.random.int(175, 200);
		sprite.velocity.x = FlxG.random.int(-50, 50);
		sprite.acceleration.y = FlxG.random.int(475, 650);
		FlxTween.tween(sprite, {alpha: 0}, 0.2, {
			ease: FlxEase.linear,
			startDelay: conductor.crochet / 1000,
			onComplete: function(twn:FlxTween)
			{
				sprite.kill();
			}
		});
		sprite.animation.play(diff < 0 ? "late" : "early");
		var shownCombo:Int = combo;
		if (name == 'miss')
			shownCombo = missCombo;

		add(sprite);
		if (Math.abs(shownCombo) >= 10)
		{
			var combos = Std.string(Math.abs(shownCombo)).split("");
			if (combos.length < 3)
			{
				for (i in combos.length...3)
					combos.unshift("0");
			}
			if (shownCombo < 0)
				combos.unshift("-");
			var i:Int = 0;
			for (num in combos)
			{
				var sprite = Judgements.getNumber(num);
				sprite.screenCenter(XY);
				sprite.x -= 150 - (50 * i);
				sprite.y += 50;
				sprite.velocity.y = -FlxG.random.int(100, 150);
				sprite.velocity.x = FlxG.random.int(-25, 25);
				sprite.acceleration.y = FlxG.random.int(250, 500);
				FlxTween.tween(sprite, {alpha: 0}, 0.2, {
					ease: FlxEase.linear,
					startDelay: conductor.crochet / 2000,
					onComplete: function(twn:FlxTween)
					{
						sprite.kill();
					}
				});
				if (name == 'miss')
					sprite.color = FlxColor.RED;
				add(sprite);
				i++;
			}
		}
	}

	override function beatHit(beat:Int)
	{
		super.beatHit(beat);
		if (beat % 4 == 0)
		{
			gameCam.zoom += 0.02;
			hudCam.zoom += 0.03;
		}
	}

	override function stepHit(step:Int)
	{
		super.stepHit(step);
	}

	var pressTimer:Array<Float> = [0, 0, 0, 0];

	function averageArray(arr:Array<Float>):Float
	{
		var average:Float = 0;
		for (cum in arr)
			average += cum;
		average /= arr.length;
		if (Math.isNaN(average))
			average = 0;

		return average;
	}

	var lastSongPos:Float = 0; // used to resync music
	var timeSinceChange:Float = 0; // used to resync music

	override public function update(elapsed:Float)
	{
		@:privateAccess
		Notefield.mineSprite.update(elapsed);

		super.update(elapsed);

		if (conductor.time < 0)
		{
			conductor.time += elapsed * 1000;
			conductor.rawTime = conductor.time;
			conductor.visualTime = conductor.time;
			if (conductor.time >= 0)
			{
				inst.play();
				voices.play();
			}
		}
		else
		{
			if (inst.playing)
			{
				if (lastSongPos == inst.time)
				{
					timeSinceChange += elapsed * 1000;
					conductor.rawTime = inst.time + timeSinceChange;
				}
				else
				{
					timeSinceChange = 0;
					conductor.rawTime = inst.time;
				}

				//trace(inst.time, conductor.rawTime, timeSinceChange);
				FlxG.watch.addQuick("inst time", inst.time);
				FlxG.watch.addQuick("raw time", conductor.rawTime);
				FlxG.watch.addQuick("sync timer", timeSinceChange);
				conductor.time = conductor.rawTime;
				conductor.visualTime = conductor.time;

				lastSongPos = inst.time;

				if (Math.abs(voices.time - inst.time) > 25)
					voices.time = inst.time;
			}
		}

		var lerpVal:Float = 0.04 * (elapsed / (1 / 60));
		gameCam.zoom = FlxMath.lerp(gameCam.zoom, 1, lerpVal);
		hudCam.zoom = FlxMath.lerp(hudCam.zoom, 1, lerpVal);

		noteCam.zoom = hudCam.zoom;
		receptorCam.zoom = hudCam.zoom;
		holdCam.zoom = hudCam.zoom;
	}

	override function destroy()
	{
		Controls.onActionChanged.remove(onActionChanged);
		return super.destroy();
	}
}
