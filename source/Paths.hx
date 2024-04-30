package;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Paths
{
	// maybe add libraries? idk lol
	public static function getPath(file:String, type:AssetType)
	{
		if (Assets.exists('assets/$file', type))
			return 'assets/$file';

		return '';
	}

	public static function image(path:String)
	{
		return getPath('${path}.png', IMAGE);
	}

	public static function txt(path:String)
	{
		return getPath('${path}.txt', TEXT);
	}

	public static function xml(path:String)
	{
		return getPath('${path}.xml', TEXT);
	}

	public static function json(path:String)
	{
		return getPath('${path}.json', TEXT);
	}

	public static function chart(name:String, suffix:String = '')
	{
		trace('songs/$name/${name}${suffix}.json');
		return getPath('songs/$name/${name}${suffix}.json', TEXT);
	}

	public static function formatSong(name:String)
	{
		return name.toLowerCase().replace(" ", "-");
	}

	public static function inst(name:String)
	{
		return getPath('songs/${formatSong(name)}/Inst.ogg', MUSIC); // TODO: sound_ext which changes depending on html or desktop
	}

	public static function voices(name:String)
	{
		return getPath('songs/${formatSong(name)}/Voices.ogg', MUSIC); // TODO: sound_ext which changes depending on html or desktop
	}

	public static function splitTxt(path:String)
	{
		var data = File.getContent(txt(path));
		var daList:Array<String> = data.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function hscript(path:String)
	{
		var extensions = ['hscript', 'hxs', 'hx'];
		for (ext in extensions)
		{
			var p = getPath('${path}.$ext', TEXT);
			if (p != '')
				return p;
		}
		return '';
	}

	public static function packer(path:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(path), txt(path));
	}

	public static function sparrow(path:String)
	{
		return FlxAtlasFrames.fromSparrow(image(path), xml(path));
	}
}
