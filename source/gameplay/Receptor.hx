package gameplay;

import flixel.FlxSprite;
import scripts.HScript;
import sys.FileSystem;

enum ReceptorStatus
{
	IDLE;
	PRESSED;
	CONFIRM;
}

class Receptor extends OffsettedSprite
{
	public var hscript:HScript;

	var direction:Int = 0;
	var status:ReceptorStatus = IDLE;
	var parent:Notefield;

	public function setDefault()
	{
		frames = Paths.sparrow("images/NOTE_assets");
		antialiasing = true;
		var dirs:Array<String> = ["left", "down", "up", "right"]; // should probably store this in NoteData
		var direction:String = dirs[direction];
		animation.addByPrefix("idle", 'arrow${direction.toUpperCase()}', 24);
		animation.addByPrefix("press", '$direction press', 24, false);
		animation.addByPrefix("confirm", '$direction confirm', 24, false);
		playAnim("idle", true);
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	public function new(x:Float, y:Float, direction:Int, ?parent:Notefield)
	{
		super(x, y);
		this.parent = parent;
		this.direction = direction;
		var hscriptPath:String = Paths.hscript('data/receptor');
		if (FileSystem.exists(hscriptPath))
			hscript = HScript.fromFile(hscriptPath, 'receptor${direction}', ["this" => this]);
		else
			hscript = HScript.fromString("");

		if (hscript.exists("create"))
			hscript.executeFunc("create", [direction], []);
		else
			setDefault();
	}

	public function runCommand(command:String, ?extraParams:Map<String, Any>)
	{
		if (extraParams == null)
			extraParams = [];

		var func = '${command}Command';
		if (hscript.exists(func))
			hscript.executeFunc(func, [extraParams]);
		else if (hscript.exists("handleCommand"))
			hscript.executeFunc("handleCommand", [command, extraParams]);
		else
			handleCommandInternal(command, extraParams);
	}

	function handleCommandInternal(command:String, ?extraParams:Map<String, Any>)
	{
		if (extraParams == null)
			extraParams = [];

		switch (command)
		{
			case 'idle' | 'press' | 'confirm':
				animation.play(command, true);
				centerOrigin();
				centerOffsets();
			default:
				trace('unhandled command ${command}');
		}
	}

	// extra params would have stuff like the pressed note for confirm, etc
	public function setStatus(status:ReceptorStatus, ?extraParams:Map<String, Any>)
	{
		if (extraParams == null)
			extraParams = [];
		if (status != this.status)
		{
			hscript.executeFunc("onSetStatus", [status, extraParams], []);
			switch (status)
			{
				case IDLE:
					runCommand("idle", extraParams);
				case PRESSED:
					runCommand("press", extraParams);
				case CONFIRM:
					runCommand("confirm", extraParams);
			}

			this.status = status;
		}
	}

	override function draw()
	{
		hscript.executeFunc("preDraw", []);
		super.draw();
		hscript.executeFunc("postDraw", []);
	}

	override function update(elapsed:Float)
	{
		hscript.executeFunc("update", [elapsed]);
		super.update(elapsed);
	}

	override function destroy()
	{
		hscript.executeFunc("destroy", []); // tell scripts to destroy anything that it may have created
		hscript.stop(); // stop the script
		hscript = null; // and free up memory
		super.destroy();
	}
}
