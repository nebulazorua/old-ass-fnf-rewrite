package gameplay;

import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import data.Judgements;
import data.NoteData;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import lime.math.Vector2;
import lime.math.Vector4;
import openfl.Vector;
import scripts.HScript;
import sys.FileSystem;

enum SpriteType
{
	TAP;
	HOLD_BODY;
	HOLD_END;
}

class Notefield extends FlxTypedGroup<Receptor>
{
	public var baseX:Float = 0;
	public var baseY:Float = 0;
	public var data:NoteData;
	public var existingNotes:Array<Array<Note>> = [];
	public var noteCount:Int = 0;
	public var noteCameras:Array<FlxCamera> = [];
	public var holdCameras:Array<FlxCamera> = [];
	public var noteSpeed:Float = 1.6;

	public var drawCount:Int = 0;

	public var pressed:Array<Bool> = [];

	var conductor:Conductor;

	static var mineSprite:FlxSprite;
	static var cachedSprites:Array<FlxSprite> = [];
	static var cachedHolds:Array<FlxSprite> = [];
	static var cachedCaps:Array<FlxSprite> = [];

	public static function loadNotes()
	{
		loadTaps();
		loadHolds();
		loadCaps();
	}

	static function loadCaps()
	{
		var anims = ["pruple end hold", "blue hold end", "green hold end", "red hold end"];
		for (dir in 0...4)
		{
			var spr = new FlxSprite();
			spr.frames = Paths.sparrow("images/NOTE_assets");
			spr.antialiasing = true;
			spr.animation.addByPrefix("idle", anims[dir], 24);
			spr.animation.play("idle", true);

			@:privateAccess
			spr.checkEmptyFrame();
			spr.scale.set(0.7, 0.7);
			spr.updateHitbox();

			spr.shader = new FlxShader();
			spr.shader.bitmap.input = spr.graphic.bitmap;
			spr.shader.bitmap.filter = LINEAR;
			spr.shader.hasColorTransform.value = [false];
			spr.shader.alpha.value = [1];
			cachedCaps[dir] = spr;

			spr.centerOrigin();
			trace(spr.origin.y);
			spr.origin.y = 0;
			spr.centerOffsets();
		}
	}

	static function loadHolds()
	{
		var colors = ["purple", "blue", "green", "red"];
		for (dir in 0...4)
		{
			var spr = new FlxSprite();
			spr.frames = Paths.sparrow("images/NOTE_assets");
			spr.antialiasing = true;
			spr.animation.addByPrefix("idle", '${colors[dir]} hold piece0', 24);
			spr.animation.play("idle", true);

			@:privateAccess
			spr.checkEmptyFrame();
			spr.scale.set(0.7, 0.7);
			spr.updateHitbox();

			spr.shader = new FlxShader();
			spr.shader.bitmap.input = spr.graphic.bitmap;
			spr.shader.bitmap.filter = LINEAR;
			spr.shader.hasColorTransform.value = [false];
			spr.shader.alpha.value = [1];
			cachedHolds[dir] = spr;

			spr.centerOrigin();
			spr.centerOffsets();
		}
	}

	static function loadTaps()
	{
		var colors = ["purple", "blue", "green", "red"];
		for (dir in 0...4)
		{
			var spr = new FlxSprite();
			spr.frames = Paths.sparrow("images/NOTE_assets");
			spr.antialiasing = true;
			spr.animation.addByPrefix("idle", '${colors[dir]}0', 24);
			spr.animation.play("idle", true);

			@:privateAccess
			spr.checkEmptyFrame();

			spr.shader = new FlxShader();
			spr.shader.bitmap.input = spr.graphic.bitmap;
			spr.shader.bitmap.wrap = CLAMP_U_REPEAT_V;
			spr.shader.bitmap.filter = LINEAR;
			spr.shader.hasColorTransform.value = [false];
			spr.shader.alpha.value = [1];
			cachedSprites[dir] = spr;

			spr.setGraphicSize(Std.int(spr.width * 0.7));
			spr.updateHitbox();
			spr.centerOrigin();
			spr.centerOffsets();
		}

		mineSprite = new FlxSprite();
		mineSprite.frames = Paths.sparrow("images/MINES");
		mineSprite.antialiasing = true;
		mineSprite.animation.addByPrefix("idle", 'mine', 24);
		mineSprite.animation.play("idle", true);

		@:privateAccess
		mineSprite.checkEmptyFrame();

		mineSprite.shader = new FlxShader();
		mineSprite.shader.bitmap.input = mineSprite.graphic.bitmap;
		mineSprite.shader.bitmap.wrap = CLAMP_U_REPEAT_V;
		mineSprite.shader.bitmap.filter = LINEAR;
		mineSprite.shader.hasColorTransform.value = [false];
		mineSprite.shader.alpha.value = [1];

		mineSprite.setGraphicSize(Std.int(mineSprite.width * 0.7));
		mineSprite.updateHitbox();
		mineSprite.centerOrigin();
		mineSprite.centerOffsets();
	}

	function getSprite(note:Note, spriteType:SpriteType)
	{
		// TODO: noteskin stuff
		switch (spriteType)
		{
			case HOLD_BODY:
				return cachedHolds[note.direction];
			case HOLD_END:
				return cachedCaps[note.direction];
			case TAP:
				switch (note.noteType)
				{
					case MINE:
						return mineSprite;
					default:
						return cachedSprites[note.direction];
				}
		}
	}

	public function new(x:Float = 0, y:Float = 0, conductor:Conductor, data:NoteData)
	{
		super();
		baseX = x;
		baseY = y;
		this.conductor = conductor;
		this.data = data;
		for (column in data.notes)
			column.sort((a, b) -> Std.int(a.hitTime - b.hitTime));

		for (i in 0...4)
			existingNotes[i] = [];

		generateReceptors();
	}

	public function clearReceptors()
	{
		while (members.length > 0)
		{
			var note:Receptor = members.pop();
			note.kill();
			note.destroy();
		}
	}

	public function generateReceptors(?x:Float)
	{
		if (x == null)
			x = baseX;

		clearReceptors();
		for (data in 0...4)
		{
			var receptor = new Receptor(x, baseY, data, this);
			receptor.x -= 56;
			switch (data)
			{
				case 0:
					receptor.x -= 112 + 56;
				case 1:
					receptor.x -= 56;
				case 2:
					receptor.x += 56;
				case 3:
					receptor.x += 112 + 56;
			}
			add(receptor);
			receptor.hscript.executeFunc("added", [this]);
		}
	}

	function getY(timeDiff:Float, ?speed:Float)
	{
		if (speed == null)
			speed = noteSpeed;
		return Math.round(baseY - (timeDiff) * (0.45 * speed));
	}

	function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		var p = point == null ? FlxPoint.weak() : point;
		p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
		return p;
	}

	// thanks schmoovin'
	function rotateV4(vec:Vector4, xA:Float, yA:Float, zA:Float):Vector4
	{
		var rotateZ = rotate(vec.x, vec.y, zA);
		var offZ = new Vector4(rotateZ.x, rotateZ.y, vec.z);

		var rotateY = rotate(offZ.x, offZ.z, yA);
		var offY = new Vector4(rotateY.x, offZ.y, rotateY.y);

		var rotateX = rotate(offY.z, offY.y, xA);
		var offX = new Vector4(offY.x, rotateX.y, rotateX.x);

		rotateZ.putWeak();
		rotateX.putWeak();
		rotateY.putWeak();

		return offX;
	}


	function drawSprite(x:Float, y:Float, sprite:FlxSprite, ?cameras:Array<FlxCamera>, ?width:Float, ?height:Float)
	{
		if (cameras == null)
			cameras = noteCameras;

		if (width == null)
			width = sprite.frameWidth * sprite.scale.x;

		if (height == null)
			height = sprite.frameHeight * sprite.scale.y;

		var quad = [
			[-width / 2, -height / 2], // top left
			[width / 2, -height / 2], // top right
			[-width / 2, height / 2], // bottom left
			[width / 2, height / 2] // bottom right
		];
        
		// sprite.angle += 1;
		for (side in quad)
		{
			var pos = rotateV4(new Vector4(side[0], side[1], 0), 0, 0, FlxAngle.TO_RAD * sprite.angle);
			side[0] = pos.x;
			side[1] = pos.y;
		}

		var frameRect = sprite.frame.frame;
		var sourceBitmap = sprite.graphic.bitmap;

		var leftUV = frameRect.left / sourceBitmap.width;
		var rightUV = frameRect.right / sourceBitmap.width;
		var topUV = frameRect.top / sourceBitmap.height;
		var bottomUV = frameRect.bottom / sourceBitmap.height;
		// order should be TL, TR, BR, TL, BL, BR

		var x = x + sprite.origin.x - sprite.offset.x;
		var y = y + sprite.origin.y - sprite.offset.y;
		var vertices = new Vector<Float>(12, false, [
			x + quad[0][0], y + quad[0][1],
			x + quad[1][0], y + quad[1][1],
			x + quad[3][0], y + quad[3][1],

			x + quad[0][0], y + quad[0][1],
			x + quad[2][0], y + quad[2][1],
			x + quad[3][0], y + quad[3][1]
		]);

		var uvtDat = new Vector<Float>(12, false, [
			 leftUV,    topUV,
			rightUV,    topUV,
			rightUV, bottomUV,

			 leftUV,    topUV,
			 leftUV, bottomUV,
			rightUV, bottomUV,
		]);

		drawCount++;

		for (camera in cameras)
		{
			camera.canvas.graphics.beginShaderFill(sprite.shader);
			camera.canvas.graphics.drawTriangles(vertices, null, uvtDat);
			camera.canvas.graphics.endFill();
		}
	}

	function drawHoldNote(note:Note, sprite:FlxSprite)
	{
		var width:Float = sprite.frameWidth * sprite.scale.x;
		var sourceHeight = sprite.frameHeight * sprite.scale.y;
		var endTime = note.hitTime + note.duration;

		var cap = getSprite(note, HOLD_END);
		var capHeight = cap.frameHeight * cap.scale.y;
		var capWidth = cap.frameWidth * cap.scale.x;
		var x:Float = members[note.direction].x;
		var y:Float = getY(0) + members[note.direction].height / 2 - sourceHeight / 2;
		var startY:Float = getY((conductor.visualTime - note.hitTime));
		if (note.hitResult.judgement != TS_NONE)
			startY = y;
		var endY:Float = getY((conductor.visualTime - endTime));
		var height:Float = Math.round(endY - startY);

		if (height < 0)
			height = 0;

		var frameRect = sprite.frame.frame;
		var sourceBitmap = sprite.graphic.bitmap;

		var leftUV = frameRect.left / sourceBitmap.width;
		var rightUV = frameRect.right / sourceBitmap.width;
		var topUV = (frameRect.top) / sourceBitmap.height;
		var bottomUV = (frameRect.bottom) / sourceBitmap.height;

		var quad = [
			[-width / 2, -height / 2], // top left
			[width / 2, -height / 2], // top right
			[-width / 2, height / 2], // bottom left
			[width / 2, height / 2] // bottom right
		];
		var x = x + sprite.origin.x - sprite.offset.x;
		x += width;
		var y = startY + sprite.origin.y - sprite.offset.y + height / 2;
		var vertices = new Vector<Float>(12, false, [
			x + quad[0][0], y + quad[0][1],
			x + quad[1][0], y + quad[1][1],
			x + quad[3][0], y + quad[3][1],

			x + quad[0][0], y + quad[0][1],
			x + quad[2][0], y + quad[2][1],
			x + quad[3][0], y + quad[3][1]
		]);

		var uvtDat = new Vector<Float>(12, false, [
			 leftUV,    topUV,
			rightUV,    topUV,
			rightUV, bottomUV,

			 leftUV,    topUV,
			 leftUV, bottomUV,
			rightUV, bottomUV,
		]);

		sprite.shader.alpha.value = [0.5];
		cap.shader.alpha.value = [0.5];
		for (camera in holdCameras)
		{
			camera.canvas.graphics.beginShaderFill(sprite.shader);
			camera.canvas.graphics.drawTriangles(vertices, null, uvtDat);
			camera.canvas.graphics.endFill();
		}
		drawCount++;
		drawSprite(x - capWidth / 2, endY + capHeight + 1, cap, holdCameras);
	}

	function drawTapNote(note:Note, sprite:FlxSprite)
	{
		var x:Float = members[note.direction].x;
		var y:Float = getY((conductor.visualTime - note.hitTime));
		if (note.hitResult.judgement != TS_NONE)
			return;
		drawSprite(x, y, sprite, noteCameras);
	}

	public function drawNotes()
	{
		noteCount = 0;
		for (dir in 0...data.notes.length)
		{
			existingNotes[dir] = [];
			var column = data.notes[dir];
			for (note in column)
			{
				var tapSprite = getSprite(note, TAP);
				var holdSprite = getSprite(note, HOLD_BODY);
				tapSprite.shader.bitmap.input = tapSprite.graphic.bitmap;
				if (holdSprite != null)
					holdSprite.shader.bitmap.input = holdSprite.graphic.bitmap;
				var y = getY((conductor.visualTime - note.hitTime));
				if (y <= 720)
				{
					existingNotes[note.direction].push(note);
					noteCount++;
					if (note.holdType != NONE && holdSprite != null)
						drawHoldNote(note, holdSprite);

					drawTapNote(note, tapSprite);
				}
			}
		}
	}

	override public function draw()
	{
		drawNotes();
		super.draw();
	}
}
