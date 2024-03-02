package options;

#if desktop
import DiscordClient;
#end
import flash.text.TextField;
import Note;
import StrumNote;
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

using StringTools;

class VisualsUISubState extends BaseOptionsMenu
{

	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Note Splashes',
			"If checked, hitting \"Sick!\" notes shows particles.",
			'noteSplashes',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show NPS',
			'If checked, the game will show your current NPS.',
			'showNPS',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Note Splash Limit: ',
			"How many note splashes should be allowed on screen at the same time?\n(0 means no limit)",
			'noteSplashLimit',
			'int',
			16);

		option.minValue = 0;
		option.maxValue = 50;
		option.displayFormat = '%v Splashes';
		addOption(option);

		var option:Option = new Option('Opponent Note Alpha:',
			"How visible do you want the opponent's notes to be when Middlescroll is enabled? \n(0% = invisible, 100% = fully visible)",
			'oppNoteAlpha',
			'percent',
			0.65);
		option.scrollSpeed = 1.8;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option("Taunt on \"GO!\"",
			"If checked, the characters will taunt when the countdown says go before the song starts.",
			'tauntOnGo',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Rendered Notes',
			'If checked, the game will show how many notes are currently rendered on screen.',
			'showRendered',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Results Screen',
			'If unchecked, the results screen will be skipped.',
			'resultsScreen',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Compact UI Numbers',
			'If checked, Score, combo, misses and NPS will be compact.',
			'compactNumbers',
			'bool',
			false);
		addOption(option);

		option.minValue = 0;
		option.maxValue = 100;

		var option:Option = new Option('Smooth Health',
			"If checked, the health will adjust smoothly.",
			'smoothHealth',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Smooth Health Bug',
			'This was too cool to be removed, apparently.\nIf checked, the icons will be able to go past the normal boundaries of the health bar.',
			'smoothHPBug',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Note Hit Offset Bug',
			'If checked, the opponent\'s notes will be able to go past the strumline\'s hit time and still get hit, and the' +
			'\nplayer strums will still have semi-transparent notes when the game lags (Mostly with rating popups because spawning a lot of them affects performance).',
			'noteHitOffsetBug',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('OG HP Colors',
			'If checked, the health bar will globally use Red/Green as the colors.',
			'ogHPColor',
			'bool',
			false);
		addOption(option);
		
		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			'string',
			'Time Left',
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Strum Light Up Style:',
			"How would you like the strum animations to play when lit up? \nNote: Turn on 'Light Opponent/Botplay Strums' to see this in action!",
			'strumLitStyle',
			'string',
			'Full Anim',
			['Full Anim', 'BPM Based']);
		addOption(option);

		var option:Option = new Option('Use Wrong Popup Camera',
			'If checked, the popups will use the game world camera instead of the HUD.',
			'showWrongPopupCameras',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Use Old Note Sorting',
			'Basically, the notes are added at the beginning of the note groups\' members like vanilla' +
			'\npsych engine instead of adding them at the end.\nIf you prefer psych\'s note sorting like on older versions of JS Engine, enable this.',
			'useOldNoteSorting',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit',
			"If unchecked, disables the Score text zooming\neverytime you hit a note.",
			'scoreZoom',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Health Bar Transparency',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			'percent',
			1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		#if !mobile
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			'bool',
			true);
		addOption(option);
		option.onChange = onChangeFPSCounter;
		#end

		var option:Option = new Option('Botplay Text Fading',
			"If checked, the botplay text will do cool fading.",
			'botTxtFade',
			'bool',
			true);
		addOption(option);
		
		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			'Tea Time',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;
				
		var option:Option = new Option('Menu Song:',
			"What song do you prefer when you're in menus?",
			'daMenuMusic',
			'string',
			'Mashup',
			['Mashup', 'Base Game', 'DDTO+', 'Dave & Bambi', 'Dave & Bambi (Old)', 'VS Impostor', 'VS Nonsense V2']);
		addOption(option);
		option.onChange = onChangeMenuMusic;
		
		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			'bool',
			true);
		addOption(option);
		#end

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show RAM Usage',
			"If checked, the game will show your RAM usage.",
			'showRamUsage',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Peak RAM Usage',
			"If checked, the game will show your maximum RAM usage.",
			'showMaxRamUsage',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Debug Info',
			"If checked, the game will show additional debug info.\nNote: Turn on FPS Counter before using this!",
			'debugInfo',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Main Menu Tips',
			"If unchecked, hides those tips at the top in the main menu!",
			'tipTexts',
			'bool',
			true);
		addOption(option);

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC',
			'bool',
			true);
		addOption(option);
		#end

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];

		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)));

		changedMusic = true;
	}

	var menuMusicChanged:Bool = false;
	function onChangeMenuMusic()
	{
		if (ClientPrefs.daMenuMusic != 'Mashup') FlxG.sound.playMusic(Paths.music('freakyMenu-' + ClientPrefs.daMenuMusic));
		if (ClientPrefs.daMenuMusic == 'Mashup') FlxG.sound.playMusic(Paths.music('freakyMenu'));
		menuMusicChanged = true;
	}

	override function destroy()
	{
		if(changedMusic) FlxG.sound.playMusic(Paths.music('freakyMenu-' + ClientPrefs.daMenuMusic));
		super.destroy();
	}

	#if !mobile
	function onChangeFPSCounter()
	{
		if(Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.showFPS;
	}
	#end
}
