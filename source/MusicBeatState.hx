package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import lime.app.Application;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var oldStep:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public static var windowNameSuffix:String = "";
	public static var windowNameSuffix2:String = ""; //changes to "Outdated!" if the version of the engine is outdated
	public static var windowNamePrefix:String = "Friday Night Funkin': JS Engine";

	override public function new() {
		super();
	}

	override function create() {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		Application.current.window.title = windowNamePrefix + windowNameSuffix + windowNameSuffix2; // Actually change the window title

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		if (oldStep != curStep) oldStep = curStep;

		updateCurStep();
		updateBeat();
		updateSection();

		if (oldStep != curStep && curStep > 0)
		{
			stepHit();

			// New system for beat hits and section hits.
			if (curStep % 4 == 0)
				beatHit(); //troll mode no longer breaks beats
			if (curStep % 16 == 0)
				sectionHit(); //troll mode no longer breaks sections
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		FlxG.autoPause = ClientPrefs.autoPause;

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			//sectionHit(); Don't uncomment this
		}
		//trace(curSection); NO GOD WHY
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		final lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		final shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	override function startOutro(onOutroComplete:Void->Void):Void
	{
		if (!FlxTransitionableState.skipNextTransIn)
		{
			openSubState(new CustomFadeTransition(0.6, false));

			CustomFadeTransition.finishCallback = onOutroComplete;

			return;
		}

		FlxTransitionableState.skipNextTransIn = false;

		onOutroComplete();
	}

	//runs whenever the game hits a step
	public function stepHit():Void
	{
		//trace('Step: ' + curStep);
	}

	//runs whenever the game hits a beat
	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	//runs whenever the game hits a section
	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
