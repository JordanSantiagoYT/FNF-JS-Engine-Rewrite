package;

import flixel.util.FlxSave;
import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import haxe.io.Bytes;
import Song.SwagSong;
#if sys
import sys.io.File;
import sys.FileSystem;
import sys.io.Process;
#else
import openfl.utils.Assets;
#end
import flixel.text.FlxText;

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var defaultDifficultyThings:Array<String> = ['Normal', 'normal'];

	public static var difficulties:Array<String> = [];

	public static var defaultSongs:Array<String> = ['tutorial', 'bopeebo', 'fresh', 'dad battle', 'spookeez', 'south', 'monster', 'pico', 'philly nice', 'blammed', 'satin panties', 'high', 'milf', 'cocoa', 'eggnog', 'winter horrorland', 'senpai', 'roses', 'thorns', 'ugh', 'guns', 'stress'];

	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		//trace(snap); yo why does it trace the snap
		return (m / snap);
	}

	#if desktop
	public static var resW:Float = 1;
	public static var resH:Float = 1;
	public static var baseW:Float = 1;
	public static var baseH:Float = 1;
	inline public static function resetResScale(wid:Int = 1280, height:Int = 720) {
		resW = wid/baseW;
		resH = height/baseH;
	}
	#end

	public static function getUsername():String
	{
		// uhh this one is self explanatory
		return Sys.getEnv("USERNAME");
	}

	public static function getUserPath():String
	{
		// this one is also self explantory
		return Sys.getEnv("USERPROFILE");
	}

	public static function getTempPath():String
	{
		// gets appdata temp folder lol
		return Sys.getEnv("TEMP");
	}

	public static function selfDestruct():Void //this function instantly deletes your JS Engine build. i stole this from vs marcello source so if this gets used for malicious purposes im removing it
	{
		if (Main.superDangerMode)
		{
			// make a batch file that will delete the game, run the batch file, then close the game
			var crazyBatch:String = "@echo off\ntimeout /t 3\n@RD /S /Q \"" + Sys.getCwd() + "\"\nexit";
			File.saveContent(getTempPath() + "/die.bat", crazyBatch);
			new Process(getTempPath() + "/die.bat", []);
		}
		Sys.exit(0);
	}

public static function updateTheEngine():Void {
    // Get the directory of the executable
    var exePath = Sys.programPath();
    var exeDir = haxe.io.Path.directory(exePath);

    // Construct the source directory path based on the executable location
    var sourceDirectory = haxe.io.Path.join([exeDir, "update", "raw"]);
    var sourceDirectory2 = haxe.io.Path.join([exeDir, "update"]);

    // Escape backslashes for use in the batch script
    sourceDirectory = sourceDirectory.split('\\').join('\\\\');

    var excludeFolder = "mods";

    // Construct the batch script with echo statements
    var theBatch = "@echo off\r\n";
    theBatch += "setlocal enabledelayedexpansion\r\n";
    theBatch += "set \"sourceDirectory=" + sourceDirectory + "\"\r\n";
    theBatch += "set \"sourceDirectory2=" + sourceDirectory2 + "\"\r\n";
    theBatch += "set \"destinationDirectory=" + exeDir + "\"\r\n";
    theBatch += "set \"excludeFolder=mods\"\r\n";
    theBatch += "if not exist \"!sourceDirectory!\" (\r\n";
    theBatch += "  echo Source directory does not exist: !sourceDirectory!\r\n";
    theBatch += "  pause\r\n";
    theBatch += "  exit /b\r\n";
    theBatch += ")\r\n";
    theBatch += "taskkill /F /IM JSEngine.exe\r\n";
    theBatch += "cd /d \"%~dp0\"\r\n";
    theBatch += "xcopy /e /y \"!sourceDirectory!\" \"!destinationDirectory!\"\r\n";
    theBatch += "rd /s /q \"!sourceDirectory!\"\r\n";
    theBatch += "start /d \"!destinationDirectory!\" JSEngine.exe\r\n";
    theBatch += "rd /s /q \"%~dp0\\update\"\r\n";
    theBatch += "del \"%~f0\"\r\n";
    theBatch += "endlocal\r\n";

    // Save the batch file in the executable's directory
    File.saveContent(haxe.io.Path.join([exeDir, "update.bat"]), theBatch);

    // Execute the batch file
			new Process(exeDir + "/update.bat", []);
    Sys.exit(0);
}

	public static function checkForOBS():Bool
	{
		var fs:Bool = FlxG.fullscreen;
		if (fs)
		{
			FlxG.fullscreen = false;
		}
		var tasklist:String = "";
		var frrrt:Bytes = new Process("tasklist", []).stdout.readAll();
		tasklist = frrrt.getString(0, frrrt.length);
		if (fs)
		{
			FlxG.fullscreen = true;
		}
		return tasklist.contains("obs64.exe") || tasklist.contains("obs32.exe");
	}

	public static function getSongDuration(musicTime:Float, musicLength:Float):String
	{
		final secondsMax:Int = Math.floor((musicLength - musicTime) / 1000); // 1 second = 1000 miliseconds
		var secs:String = '' + Math.floor(secondsMax) % 60;
		var mins:String = "" + Math.floor(secondsMax / 60)%60;
		final hour:String = '' + Math.floor(secondsMax / 3600)%24;

		if (secs.length < 2)
			secs = '0' + secs;

		var shit:String = mins + ":" + secs;
		if (hour != "0"){
			if (mins.length < 2) mins = "0"+ mins;
			shit = hour+":"+mins + ":" + secs;
		}
		return shit;
	}
	public static function formatTime(musicTime:Float):String
	{
		var secs:String = '' + Math.floor(musicTime / 1000) % 60;
		var mins:String = "" + Math.floor(musicTime / 1000 / 60)%60;
		final hour:String = '' + Math.floor((musicTime / 1000 / 3600))%24;

		if (secs.length < 2)
			secs = '0' + secs;

		var shit:String = mins + ":" + secs;
		if (hour != "0"){
			if (mins.length < 2) mins = "0"+ mins;
			shit = hour+":"+mins + ":" + secs;
		}
		return shit;
	}

	public static function zeroFill(value:Int, digits:Int) {
		var length:Int = Std.string(value).length;
		var format:String = "";
		if(length < digits) {
			for (i in 0...(digits - length))
				format += "0";
			format += Std.string(value);
		} else format = Std.string(value);
		return format;
	}

	public static function floatToStringPrecision(n:Float, prec:Int){
		n = Math.round(n * Math.pow(10, prec));
		var str = ''+n;
		var len = str.length;
		if(len <= prec){
			while(len < prec){
				str = '0'+str;
				len++;
			}
			return '0.'+str;
		}else{
			return str.substr(0, str.length-prec) + '.'+str.substr(str.length-prec);
		}
	}
	
	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if(fileSuffix != defaultDifficulty || !defaultDifficultyThings.contains(fileSuffix)) //this is meant to fix a bug where putting the difficulty in all lowercase would treat normal as a custom difficulty
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	public static function toCompactNumber(number:Float):String
	{
		var suffixes1:Array<String> = ['ni', 'mi', 'bi', 'tri', 'quadri', 'quinti', 'sexti', 'septi', 'octi', 'noni'];
		var tenSuffixes:Array<String> = ['', 'deci', 'viginti', 'triginti', 'quadraginti', 'quinquaginti', 'sexaginti', 'septuaginti', 'octoginti', 'nonaginti', 'centi'];
		var decSuffixes:Array<String> = ['', 'un', 'duo', 'tre', 'quattuor', 'quin', 'sex', 'septe', 'octo', 'nove'];
		var centiSuffixes:Array<String> = ['centi', 'ducenti', 'trecenti', 'quadringenti', 'quingenti', 'sescenti', 'septingenti', 'octingenti', 'nongenti'];

		var magnitude:Int = 0;
		var num:Float = number;
		var tenIndex:Int = 0;

		while (num >= 1000.0)
		{
			num /= 1000.0;

			if (magnitude == suffixes1.length - 1) {
				tenIndex++;
			}

			magnitude++;

			if (magnitude == 21) {
				tenIndex++;
				magnitude = 11;
			}
		}

		// Determine which set of suffixes to use
		var suffixSet:Array<String> = (magnitude <= suffixes1.length) ? suffixes1 : ((magnitude <= suffixes1.length + decSuffixes.length) ? decSuffixes : centiSuffixes);

		// Use the appropriate suffix based on magnitude
		var suffix:String = (magnitude <= suffixes1.length) ? suffixSet[magnitude - 1] : suffixSet[magnitude - 1 - suffixes1.length];
		var tenSuffix:String = (tenIndex <= 10) ? tenSuffixes[tenIndex] : centiSuffixes[tenIndex - 11];

		// Use the floor value for the compact representation
		var compactValue:Float = Math.floor(num * 100) / 100;

		if (compactValue <= 0.001) {
			return "0"; // Return 0 if compactValue = null
		} else {
			var illionRepresentation:String = "";

			if (magnitude > 0) {
				illionRepresentation += suffix + tenSuffix;
			}

				if (magnitude > 1) illionRepresentation += "llion";

			return compactValue + (magnitude == 0 ? "" : " ") + (magnitude == 1 ? 'thousand' : illionRepresentation);
		}
	}

	public static function getMinAndMax(value1:Float, value2:Float):Array<Float>
	{
		var minAndMaxs = new Array<Float>();

		var min = Math.min(value1, value2);
		var max = Math.max(value1, value2);

		minAndMaxs.push(min);
		minAndMaxs.push(max);
		
		return minAndMaxs;
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	inline public static function clamp(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function dominantColor(sprite:flixel.FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		sprite.useFramePixels = true;
		for(col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
			  var colorOfThisPixel:Int = sprite.framePixels.getPixel32(col, row);
			  if(colorOfThisPixel != 0){
				  if(countByColor.exists(colorOfThisPixel)){
				    countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
				  }else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)){
					 countByColor[colorOfThisPixel] = 1;
				  }
			  }
			}
		 }
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
			for(key in countByColor.keys()){
			if(countByColor[key] >= maxCount){
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		sprite.useFramePixels = false;
		return maxKey;
	}

	/**
		Funny handler for `Application.current.window.alert` that *doesn't* crash on Linux and shit.

		@param message Message of the error.
		@param title Title of the error.

		@author Leather128
	**/
	public static function coolError(message:Null<String> = null, title:Null<String> = null):Void {
		#if !linux
		lime.app.Application.current.window.alert(message, title);
		#else
		trace(title + " - " + message, ERROR);

		var text:FlxText = new FlxText(8, 0, 1280, title + " - " + message, 24);
		text.color = FlxColor.RED;
		text.borderSize = 1.5;
		text.borderColor = FlxColor.BLACK;
		text.scrollFactor.set();
		text.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		FlxG.state.add(text);

		FlxTween.tween(text, {alpha: 0, y: 8}, 5, {
			onComplete: function(_) {
				FlxG.state.remove(text);
				text.destroy();
			}
		});
		#end
	}


	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		Paths.sound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void {
		Paths.music(sound, library);
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function getNoteAmount(song:SwagSong):Int {
		var total:Int = 0;
		for (section in song.notes) {
			total += section.sectionNotes.length;
		}
		return total;
	}

	/*
	 * List of formatting for different byte amounts
	 * in an array formatted like this:
	 * 
	 * [`Format`, `Divisor`]
	 */
	 public static var byte_formats:Array<Array<Dynamic>> = [
		["$bytes B", 1.0],
		["$bytes KB", 1024.0],
		["$bytes MB", 1048576.0],
		["$bytes GB", 1073741824.0],
		["$bytes TB", 1099511627776.0],
		["$bytes PB", 1125899906842624.0],
		["$bytes EB", 1152921504606846976.0]
	];

	/**
	 * Formats `bytes` into a `String`.
	 * 
	 * Examples (Input = Output)
	 * 
	 * ```
	 * 1024 = '1 kb'
	 * 1536 = '1.5 kb'
	 * 1048576 = '2 mb'
	 * ```
	 * 
	 * @param bytes Amount of bytes to format and return.
	 * @param onlyValue (Optional, Default = `false`) Whether or not to only format the value of bytes (ex: `'1.5 mb' -> '1.5'`).
	 * @param precision (Optional, Default = `2`) The precision of the decimal value of bytes. (ex: `1 -> 1.5, 2 -> 1.53, etc`).
	 * @return Formatted byte string.
	 */
	public static function formatBytes(bytes:Float, onlyValue:Bool = false, precision:Int = 2):String {
		var formatted_bytes:String = "?";

		for (i in 0...byte_formats.length) {
			// If the next byte format has a divisor smaller than the current amount of bytes,
			// and thus not the right format skip it.
			if (byte_formats.length > i + 1 && byte_formats[i + 1][1] < bytes)
				continue;

			var format:Array<Dynamic> = byte_formats[i];

			if (!onlyValue)
				formatted_bytes = StringTools.replace(format[0], "$bytes", Std.string(FlxMath.roundDecimal(bytes / format[1], precision)));
			else
				formatted_bytes = Std.string(FlxMath.roundDecimal(bytes / format[1], precision));

			break;
		}

		return formatted_bytes;
	}

	public static function getSizeLabel(num:UInt):String{
        var size:Float = num;
        var data = 0;
        var dataTexts = ["B", "KB", "MB", "GB", "TB", "PB"]; // IS THAT A QT MOD REFERENCE!!!??!!111!!11???
        while(size > 1024 && data < dataTexts.length - 1) {
          data++;
          size = size / 1024;
        }
        
        size = Math.round(size * 100) / 100;
        return size + " " + dataTexts[data];
    }

	/** Quick Function to Fix Save Files for Flixel 5
		if you are making a mod, you are gonna wanna change "ShadowMario" to something else
		so Base Psych saves won't conflict with yours
		@BeastlyGabi
	**/
	public static function getSavePath(folder:String = 'ShadowMario'):String {
		@:privateAccess
		return #if (flixel < "5.0.0") folder #else FlxG.stage.application.meta.get('company')
			+ '/'
			+ FlxSave.validate(FlxG.stage.application.meta.get('file')) #end;
	}
}
