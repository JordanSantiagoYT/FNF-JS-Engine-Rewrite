package openfl.display;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.math.FlxMath;
import flixel.util.FlxStringUtil;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
import flixel.FlxG;
#if flash
import openfl.Lib;
#end
import external.memory.Memory;
#if openfl
import openfl.system.System;
#end
import Main;
import flixel.util.FlxColor;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public static var instance:FPS;

	public static var mainThing:Main;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("VCR OSD Mono", 12, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		var currentFPS = (1 / FlxG.elapsed);

		text = (ClientPrefs.showFPS ? "FPS: " + (ClientPrefs.ffmpegMode ? ClientPrefs.targetFPS : Std.int(currentFPS)) : "");
		if (ClientPrefs.ffmpegMode) {
			text += " (Rendering Mode)";
		}
		
		if (ClientPrefs.showRamUsage) text += "\nMemory: " + CoolUtil.formatBytes(Memory.getCurrentUsage(), false, 2) + (ClientPrefs.showMaxRamUsage ? " / " + CoolUtil.formatBytes(Memory.getPeakUsage(), false, 2) : "");

		if (ClientPrefs.debugInfo) {
			text += '\nState: ${Type.getClassName(Type.getClass(FlxG.state))}';
			if (FlxG.state.subState != null)
				text += '\nSubstate: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';
			text += "\nSystem: " + '${lime.system.System.platformLabel} ${lime.system.System.platformVersion}';
		}

		if (!ClientPrefs.ffmpegMode)
		{
			textColor = 0xFFFFFFFF;
			if (currentFPS <= ClientPrefs.framerate / 2 && currentFPS >= ClientPrefs.framerate / 3)
			{
				textColor = 0xFFFFFF00;
			}
			if (currentFPS <= ClientPrefs.framerate / 3 && currentFPS >= ClientPrefs.framerate / 4)
			{
				textColor = 0xFFFF8000;
			}
			if (currentFPS <= ClientPrefs.framerate / 4)
			{
				textColor = 0xFFFF0000;
			}
		}

		#if (gl_stats && !disable_cffi && (!html5 || !canvas))
		text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
		text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
		text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
		#end

		text += "\n";
	}
}
