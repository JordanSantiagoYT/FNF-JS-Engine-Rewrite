package options;

#if desktop
import DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import openfl.Lib;

using StringTools;

class OptimizationSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Optimization';
		rpcTitle = 'Optimization Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Enable GC" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Enable GC', //Name
			"If checked, then the game will be allowed to garbage collect, reducing RAM usage I suppose.\nIf you experience memory leaks, turn this on, and\nif you experience lag with it on then turn it off.", //Description
			'enableGC', //Save data variable name
			'bool', //Variable type
			false); //Default value
		addOption(option);

		var option:Option = new Option('Light Opponent Strums',
			"If this is unchecked, the Opponent strums won't light up when the Opponent hits a note.",
			'opponentLightStrum',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Light Botplay Strums',
			"If this is unchecked, the Player strums won't light when Botplay is active.",
			'botLightStrum',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Ratings & Combo',
			"If checked, shows the ratings & combo. Kinda defeats the purpose of this engine though...",
			'ratesAndCombo',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Progressive Audio Loading', //Name
			"If checked, audio will load as it's played instead of loading the entire audio.", //Description
			'progAudioLoad',
			'bool',
			false); //Don't turn this on by default
		addOption(option);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
		
		super();
	}
}