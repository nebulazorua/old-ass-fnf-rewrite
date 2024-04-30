/*
 * Apache License, Version 2.0
 *
 * Copyright (c) 2022 Nebula_Zorua
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 *     http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package data;

import data.NoteData;
import flixel.FlxSprite;

enum Judgement
{
	TS_NONE;
	TIER1;
	TIER2;
	TIER3;
	TIER4;
	TIER5;
	MISS;
	HIT_MINE;
	AVOID_MINE;
}

typedef JudgementData =
{
	var internalName:String;
	var displayName:String;
	var window:Float;
	var score:Int;
	var accuracy:Float;
	var frame:Int;
}

class Judgements
{
	// static var judgementArray:Array<Int> = [45, 90, 135, 180];
	// static var judgementNames:Array<String> = ["sick", "good", "bad", "shit", "miss"];
	static var judgementDatas:Array<JudgementData> = [
		{
			internalName: "sick",
			displayName: "Sick",
			window: 45,
			score: 350,
			accuracy: 1,
			frame: 0
		},
		{
			internalName: "good",
			displayName: "Good",
			window: 90,
			score: 100,
			accuracy: 0.9,
			frame: 1
		},
		{
			internalName: "bad",
			displayName: "Bad",
			window: 135,
			score: 0,
			accuracy: 0.5,
			frame: 2
		},
		{
			internalName: "shit",
			displayName: "Shit",
			window: 180,
			score: -100,
			accuracy: -0.2,
			frame: 3
		},
		{
			internalName: "miss",
			displayName: "Miss",
			window: -1,
			score: -100,
			accuracy: -1,
			frame: 4
		},
		{
			internalName: "hitmine",
			displayName: "Hit Mine",
			window: 30,
			score: -100,
			accuracy: -2,
			frame: -1
		},
		{
			internalName: "avoidmine",
			displayName: "Avoid Mine",
			window: -1,
			score: 0,
			accuracy: 0,
			frame: -1
		},
	];

	static var judgements:Map<Judgement, JudgementData> = [
		TIER5 => judgementDatas[3],
		TIER4 => judgementDatas[3],
		TIER3 => judgementDatas[2],
		TIER2 => judgementDatas[1],
		TIER1 => judgementDatas[0],
		MISS => judgementDatas[4],
		HIT_MINE => judgementDatas[5],
		AVOID_MINE => judgementDatas[6]
	];

	static var judgableJudgements:Array<Judgement> = [TIER1, TIER2, TIER3, TIER4, TIER5]; // judgements which are gained by hitting normal tap notes

	@:isVar
	public static var hitWindow(get, null):Float = 0;

	static function get_hitWindow()
		return get(judgableJudgements[judgableJudgements.length - 1]).window;

	public static function getName(idx:Judgement)
		return get(idx).internalName;

	public static function get(idx:Judgement)
		return judgements.get(idx);

	public static function judgeNote(note:Note, time:Float)
	{
		var diff = note.hitTime - time;
		switch (note.noteType)
		{
			case MINE:
				if (diff <= get(HIT_MINE).window)
					return HIT_MINE;

				return TS_NONE;
			case FAKE:
				return TS_NONE;
			default:
				for (i in 0...judgableJudgements.length)
				{
					var k = judgableJudgements[i];
					var ms = get(k).window;
					if (Math.abs(diff) <= ms)
						return k;
				}
				return TS_NONE;
		}
	}

	public static function getIndexByName(name:String):Judgement
	{
		for (k in judgements.keys())
		{
			if (get(k).internalName == name || get(k).displayName == name)
				return k;
		}
		return TIER5;
	}

	public static function getByName(name:String)
		return get(getIndexByName(name));

	public static function getHoldSprite(name:String)
	{
		var judgement = new FlxSprite();
		judgement.loadGraphic(Paths.image("images/holdJudgements"), true, 403, 152);
		judgement.antialiasing = true;
		judgement.animation.add("ok", [0], 0, true);
		judgement.animation.add("bad", [1], 0, true);
		judgement.animation.play(name, true);
		judgement.setGraphicSize(Std.int(judgement.width * 0.6));
		judgement.updateHitbox();
		return judgement;
	}

	public static function getSprite(name:String)
	{
		var idx = getByName(name).frame;
		var judgement = new FlxSprite();
		judgement.loadGraphic(Paths.image("images/judgements"), true, 403, 152);
		judgement.antialiasing = true;
		judgement.animation.add("early", [2 * idx], 0, true);
		judgement.animation.add("late", [(2 * idx) + 1], 0, true);
		judgement.animation.play("early", true);
		judgement.setGraphicSize(Std.int(judgement.width * 0.8));
		judgement.updateHitbox();
		return judgement;
	}

	public static function getNumber(num:String)
	{
		var indexes = ["-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."];
		var idx = indexes.indexOf(num);
		var number = new FlxSprite();
		number.loadGraphic(Paths.image("images/numbers"), true, 91, 135);
		number.antialiasing = true;
		number.animation.add(num, [idx], 0, true);
		number.animation.play(num, true);
		number.setGraphicSize(Std.int(number.width * 0.5));
		number.updateHitbox();
		return number;
	}
}
