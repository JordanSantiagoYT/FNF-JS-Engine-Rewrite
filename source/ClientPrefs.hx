package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

class ClientPrefs { //default settings if it can't find a save file containing your current settings
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var showFPS:Bool = true;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var spaceVPose:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var cacheOnGPU:Bool = false;
	public static var progAudioLoad:Bool = false;
	public static var JSEngineRecharts:Bool = false;
	public static var alwaysTriggerCutscene:Bool = false;
	public static var instaRestart:Bool = false;
	public static var enableGC:Bool = false;
	public static var lowQuality:Bool = false;
	public static var smoothHPBug:Bool = false;
	public static var noteHitOffsetBug:Bool = false;
	public static var shaders:Bool = true;
	public static var framerate:Int = 60;
	public static var cursing:Bool = true;
	public static var noteSplashLimit:Int = 16;
	public static var tauntOnGo:Bool = true;
	public static var autosaveInterval:Float = 5.0;
	public static var noteMotionBlur:Bool = false;
	public static var noteMBMult:Float = 1;
	public static var autosaveCharts:Bool = true;
	public static var discordRPC:Bool = true;
	public static var tipTexts:Bool = true;
	public static var showRamUsage:Bool = true;
	public static var showMaxRamUsage:Bool = true;
	public static var strumLitStyle:String = 'Full Anim';
	public static var daMenuMusic:String = 'Mashup';
	public static var autoPause:Bool = true;
	public static var opponentLightStrum:Bool = true;
	public static var botLightStrum:Bool = true;
	public static var violence:Bool = true;
	public static var camZooms:Bool = true;
	public static var resultsScreen:Bool = true;
	public static var botTxtFade:Bool = true;
	public static var hideHud:Bool = false;
	public static var debugInfo:Bool = false;
	public static var voiidTrollMode:Bool = false;
	public static var compactNumbers:Bool = false;
	public static var ezSpam:Bool = false;
	public static var hitboxSelection:String = 'Original';
	public static var hitboxAlpha:Float = 0.5;
	public static var virtualPadAlpha:Float = 0.5;
	public static var hitboxSpace:Bool = false;
	public static var hitboxSpaceLocation:String = 'Bottom';
	public static var resolution:String = '1280x720';
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var ghostTapping:Bool = true;
	public static var showWrongPopupCameras:Bool = false;
	public static var shitGivesMiss:Bool = false;
	public static var trollMaxSpeed:String = 'Medium';
	public static var noteSpawnTime:Float = 1;
	public static var dynamicSpawnTime:Bool = false;
	public static var useOldNoteSorting:Bool = false;
	public static var oppNoteAlpha:Float = 0.65;
	public static var ratesAndCombo:Bool = false;
	public static var showNPS:Bool = false;
	public static var noPausing:Bool = false;
	public static var moreSpecificSpeed:Bool = true;
	public static var ogHPColor:Bool = false;
	public static var smoothHealth:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var checkForUpdates:Bool = true;
	public static var showRendered:Bool = false;
	public static var comboStacking = true;

	// Video Renderer
	public static var ffmpegMode:Bool = false;
	public static var ffmpegInfo:Bool = false;
	public static var targetFPS:Float = 60;
	public static var lossless:Bool = false;
	public static var quality:Int = 80;
	public static var noCapture:Bool = false;

	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'onlySicks' => false,
		'practice' => false,
		'botplay' => false,
		'thetrollingever' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],

		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],

		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],

		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],

		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT],
		'qt_taunt'		=> [SPACE]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		//trace(defaultKeys);
	}

	public static function saveSettings() { //changes settings when you exit so that it doesn't reset every time you close the game
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.opponentStrums = opponentStrums;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.flashing = flashing;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.debugInfo = debugInfo;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.smoothHPBug = smoothHPBug;
		FlxG.save.data.noteHitOffsetBug = noteHitOffsetBug;
		FlxG.save.data.shaders = shaders;
		FlxG.save.data.ezSpam = ezSpam;
		FlxG.save.data.JSEngineRecharts = JSEngineRecharts;
		FlxG.save.data.alwaysTriggerCutscene = alwaysTriggerCutscene;
		FlxG.save.data.framerate = framerate;
		//FlxG.save.data.cursing = cursing;
		//FlxG.save.data.violence = violence;
		FlxG.save.data.progAudioLoad = progAudioLoad;
		FlxG.save.data.tipTexts = tipTexts;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.daMenuMusic = daMenuMusic;
		FlxG.save.data.noteSplashLimit = noteSplashLimit;
		FlxG.save.data.autosaveInterval = autosaveInterval;
		FlxG.save.data.autosaveCharts = autosaveCharts;
		FlxG.save.data.discordRPC = discordRPC;
		FlxG.save.data.botTxtFade = botTxtFade;
		FlxG.save.data.enableGC = enableGC;
		FlxG.save.data.showRamUsage = showRamUsage;
		FlxG.save.data.showMaxRamUsage = showMaxRamUsage;
		FlxG.save.data.showWrongPopupCameras = showWrongPopupCameras;
		FlxG.save.data.autoPause = autoPause;
		FlxG.save.data.ogHPColor = ogHPColor;
		FlxG.save.data.hitboxSelection = hitboxSelection;
		FlxG.save.data.hitboxAlpha = hitboxAlpha;
		FlxG.save.data.virtualPadAlpha = virtualPadAlpha;
		FlxG.save.data.hitboxSpace = hitboxSpace;
		FlxG.save.data.hitboxSpaceLocation = hitboxSpaceLocation;
		FlxG.save.data.resolution = resolution;
		FlxG.save.data.strumLitStyle = strumLitStyle;
		FlxG.save.data.showNPS = showNPS;
		FlxG.save.data.resultsScreen = resultsScreen;
		FlxG.save.data.instaRestart = instaRestart;
		FlxG.save.data.voiidTrollMode = voiidTrollMode;
		FlxG.save.data.compactNumbers = compactNumbers;
		FlxG.save.data.noteSpawnTime = noteSpawnTime;
		FlxG.save.data.cacheOnGPU = cacheOnGPU;
		FlxG.save.data.dynamicSpawnTime = dynamicSpawnTime;
		FlxG.save.data.useOldNoteSorting = useOldNoteSorting;
		FlxG.save.data.botLightStrum = botLightStrum;
		FlxG.save.data.opponentLightStrum = opponentLightStrum;
		FlxG.save.data.oppNoteAlpha = oppNoteAlpha;
		FlxG.save.data.noPausing = noPausing;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.ratesAndCombo = ratesAndCombo;
		FlxG.save.data.hideHud = hideHud;
		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.trollMaxSpeed = trollMaxSpeed;
		FlxG.save.data.smoothHealth = smoothHealth;
		FlxG.save.data.moreSpecificSpeed = moreSpecificSpeed;
		FlxG.save.data.spaceVPose = spaceVPose;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.tauntOnGo = tauntOnGo;
		FlxG.save.data.timeBarType = timeBarType;
		FlxG.save.data.scoreZoom = scoreZoom;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.shitGivesMiss = shitGivesMiss;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.gameplaySettings = gameplaySettings;
		FlxG.save.data.controllerMode = controllerMode;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.pauseMusic = pauseMusic;
		FlxG.save.data.checkForUpdates = checkForUpdates;
		FlxG.save.data.showRendered = showRendered;
		FlxG.save.data.comboStacking = comboStacking;

		//RENDERING SETTINGS
		FlxG.save.data.ffmpegMode = ffmpegMode;
		FlxG.save.data.ffmpegInfo = ffmpegInfo;
		FlxG.save.data.targetFPS = targetFPS;
		FlxG.save.data.lossless = lossless;
		FlxG.save.data.quality = quality;
		FlxG.save.data.noCapture = noCapture;

		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', CoolUtil.getSavePath()); //Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() { //loads settings if it finds a save file containing the settings
		if (FlxG.save.data.resolution != null) {
			resolution = FlxG.save.data.resolution;
			#if desktop
				var resolutionValue = cast(ClientPrefs.resolution, String);

				if (resolutionValue != null) {
					var parts = resolutionValue.split('x');

					if (parts.length == 2) {
						var width = Std.parseInt(parts[0]);
						var height = Std.parseInt(parts[1]);

						if (width != null && height != null) {
							CoolUtil.resetResScale(width, height);
							FlxG.resizeGame(width, height);
							lime.app.Application.current.window.width = width;
							lime.app.Application.current.window.height = height;
						}
					}
				}
			#end
		}
		if(FlxG.save.data.downScroll != null) {
			downScroll = FlxG.save.data.downScroll;
		}
		if(FlxG.save.data.middleScroll != null) {
			middleScroll = FlxG.save.data.middleScroll;
		}
		if(FlxG.save.data.opponentStrums != null) {
			opponentStrums = FlxG.save.data.opponentStrums;
		}
		if(FlxG.save.data.showFPS != null) {
			showFPS = FlxG.save.data.showFPS;
			if(Main.fpsVar != null) {
				Main.fpsVar.visible = showFPS;
			}
		}
		if(FlxG.save.data.flashing != null) {
			flashing = FlxG.save.data.flashing;
		}
		if(FlxG.save.data.debugInfo != null) {
			debugInfo = FlxG.save.data.debugInfo;
		}
		if(FlxG.save.data.ezSpam != null) {
			ezSpam = FlxG.save.data.ezSpam;
		}
		if(FlxG.save.data.JSEngineRecharts != null) {
			JSEngineRecharts = FlxG.save.data.JSEngineRecharts;
		}
		if(FlxG.save.data.alwaysTriggerCutscene != null) {
			alwaysTriggerCutscene = FlxG.save.data.alwaysTriggerCutscene;
		}
		if(FlxG.save.data.progAudioLoad != null) {
			progAudioLoad = FlxG.save.data.progAudioLoad;
		}
		if(FlxG.save.data.noteSplashLimit != null) {
			noteSplashLimit = FlxG.save.data.noteSplashLimit;
		}
		if(FlxG.save.data.ogHPColor != null) {
			ogHPColor = FlxG.save.data.ogHPColor;
		}
		if(FlxG.save.data.showRamUsage != null) {
			showRamUsage = FlxG.save.data.showRamUsage;
		}
		if(FlxG.save.data.showMaxRamUsage != null) {
			showMaxRamUsage = FlxG.save.data.showMaxRamUsage;
		}
		if (FlxG.save.data.hitboxSelection != null) {
			hitboxSelection = FlxG.save.data.hitboxSelection;
		}
		if (FlxG.save.data.hitboxAlpha != null) {
			hitboxAlpha = FlxG.save.data.hitboxAlpha;
		}
		if (FlxG.save.data.virtualPadAlpha != null) {
			virtualPadAlpha = FlxG.save.data.virtualPadAlpha;
		}
		if(FlxG.save.data.tipTexts != null) {
			tipTexts = FlxG.save.data.tipTexts;
		}
		if(FlxG.save.data.botTxtFade != null) {
			botTxtFade = FlxG.save.data.botTxtFade;
		}
		if(FlxG.save.data.enableGC != null) {
			enableGC = FlxG.save.data.enableGC;
		}
		if(FlxG.save.data.showNPS != null) {
			showNPS = FlxG.save.data.showNPS;
		}
		if(FlxG.save.data.resultsScreen != null) {
			resultsScreen = FlxG.save.data.resultsScreen;
		}
		if(FlxG.save.data.globalAntialiasing != null) {
			globalAntialiasing = FlxG.save.data.globalAntialiasing;
		}
		if(FlxG.save.data.autoPause != null) {
			autoPause = FlxG.save.data.autoPause;
		}
		if(FlxG.save.data.voiidTrollMode != null) {
			voiidTrollMode = FlxG.save.data.voiidTrollMode;
		}
		if(FlxG.save.data.compactNumbers != null) {
			compactNumbers = FlxG.save.data.compactNumbers;
		}
		if(FlxG.save.data.cacheOnGPU != null) {
			cacheOnGPU = FlxG.save.data.cacheOnGPU;
		}
		if(FlxG.save.data.autosaveInterval != null) {
			autosaveInterval = FlxG.save.data.autosaveInterval;
		}
		if(FlxG.save.data.autosaveCharts != null) {
			autosaveCharts = FlxG.save.data.autosaveCharts;
		}
		if(FlxG.save.data.discordRPC != null) {
			discordRPC = FlxG.save.data.discordRPC;
		}
		if(FlxG.save.data.daMenuMusic != null) {
			daMenuMusic = FlxG.save.data.daMenuMusic;
		}
		if(FlxG.save.data.strumLitStyle != null) {
			strumLitStyle = FlxG.save.data.strumLitStyle;
		}
		if(FlxG.save.data.showWrongPopupCameras != null) {
			showWrongPopupCameras = FlxG.save.data.showWrongPopupCameras;
		}
		if(FlxG.save.data.dynamicSpawnTime != null) {
			dynamicSpawnTime = FlxG.save.data.dynamicSpawnTime;
		}
		if(FlxG.save.data.useOldNoteSorting != null) {
			useOldNoteSorting = FlxG.save.data.useOldNoteSorting;
		}
		if(FlxG.save.data.oppNoteAlpha != null) {
			oppNoteAlpha = FlxG.save.data.oppNoteAlpha;
		}
		if(FlxG.save.data.noPausing != null) {
			noPausing = FlxG.save.data.noPausing;
		}
		if(FlxG.save.data.noteSplashes != null) {
			noteSplashes = FlxG.save.data.noteSplashes;
		}
		if(FlxG.save.data.tauntOnGo != null) {
			tauntOnGo = FlxG.save.data.tauntOnGo;
		}
		if(FlxG.save.data.noteSpawnTime != null) {
			noteSpawnTime = FlxG.save.data.noteSpawnTime;
		}
		if(FlxG.save.data.trollMaxSpeed != null) {
			trollMaxSpeed = FlxG.save.data.trollMaxSpeed;
		}
		if(FlxG.save.data.instaRestart != null) {
			instaRestart = FlxG.save.data.instaRestart;
		}
		if(FlxG.save.data.lowQuality != null) {
			lowQuality = FlxG.save.data.lowQuality;
		}
		if(FlxG.save.data.smoothHPBug != null) {
			smoothHPBug = FlxG.save.data.smoothHPBug;
		}
		if(FlxG.save.data.noteHitOffsetBug != null) {
			noteHitOffsetBug = FlxG.save.data.noteHitOffsetBug;
		}
		if(FlxG.save.data.shaders != null) {
			shaders = FlxG.save.data.shaders;
		}
		if(FlxG.save.data.moreSpecificSpeed != null) {
			moreSpecificSpeed = FlxG.save.data.moreSpecificSpeed;
		}
		if(FlxG.save.data.botLightStrum != null) {
			botLightStrum = FlxG.save.data.botLightStrum;
		}
		if(FlxG.save.data.ratesAndCombo != null) {
			ratesAndCombo = FlxG.save.data.ratesAndCombo;
		}
		if(FlxG.save.data.opponentLightStrum != null) {
			opponentLightStrum = FlxG.save.data.opponentLightStrum;
		}
		if(FlxG.save.data.framerate != null) {
			framerate = FlxG.save.data.framerate;
			if(framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}
		/*if(FlxG.save.data.cursing != null) {
			cursing = FlxG.save.data.cursing;
		}
		if(FlxG.save.data.violence != null) {
			violence = FlxG.save.data.violence;
		}*/
		if(FlxG.save.data.camZooms != null) {
			camZooms = FlxG.save.data.camZooms;
		}
		if(FlxG.save.data.shitGivesMiss != null) {
			shitGivesMiss = FlxG.save.data.shitGivesMiss;
		}
		if(FlxG.save.data.hideHud != null) {
			hideHud = FlxG.save.data.hideHud;
		}
		if(FlxG.save.data.noteOffset != null) {
			noteOffset = FlxG.save.data.noteOffset;
		}
		if(FlxG.save.data.arrowHSV != null) {
			arrowHSV = FlxG.save.data.arrowHSV;
		}
		if(FlxG.save.data.ghostTapping != null) {
			ghostTapping = FlxG.save.data.ghostTapping;
		}
		if(FlxG.save.data.smoothHealth != null) {
			smoothHealth = FlxG.save.data.smoothHealth;
		}
		if(FlxG.save.data.spaceVPose != null) {
			spaceVPose = FlxG.save.data.spaceVPose;
		}
		if(FlxG.save.data.timeBarType != null) {
			timeBarType = FlxG.save.data.timeBarType;
		}
		if(FlxG.save.data.scoreZoom != null) {
			scoreZoom = FlxG.save.data.scoreZoom;
		}
		if(FlxG.save.data.noReset != null) {
			noReset = FlxG.save.data.noReset;
		}
		if(FlxG.save.data.healthBarAlpha != null) {
			healthBarAlpha = FlxG.save.data.healthBarAlpha;
		}
		if(FlxG.save.data.comboOffset != null) {
			comboOffset = FlxG.save.data.comboOffset;
		}

		if(FlxG.save.data.ratingOffset != null) {
			ratingOffset = FlxG.save.data.ratingOffset;
		}
		// Why was this saved twice??? I've never seen something like that before.
		/*if(FlxG.save.data.marvWindow != null) {
			perfectWindow = FlxG.save.data.perfectWindow;
		}
		if(FlxG.save.data.perfectWindow != null) {
			perfectWindow = FlxG.save.data.perfectWindow;
		}*/
		if(FlxG.save.data.sickWindow != null) {
			sickWindow = FlxG.save.data.sickWindow;
		}
		if(FlxG.save.data.goodWindow != null) {
			goodWindow = FlxG.save.data.goodWindow;
		}
		if(FlxG.save.data.badWindow != null) {
			badWindow = FlxG.save.data.badWindow;
		}
		if(FlxG.save.data.safeFrames != null) {
			safeFrames = FlxG.save.data.safeFrames;
		}
		if(FlxG.save.data.controllerMode != null) {
			controllerMode = FlxG.save.data.controllerMode;
		}
		if(FlxG.save.data.pauseMusic != null) {
			pauseMusic = FlxG.save.data.pauseMusic;
		}
		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
			{
				gameplaySettings.set(name, value);
			}
		}

		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}
		if (FlxG.save.data.checkForUpdates != null)
		{
			checkForUpdates = FlxG.save.data.checkForUpdates;
		}
		if(FlxG.save.data.showRendered != null) {
			showRendered = FlxG.save.data.showRendered;
		}
		if (FlxG.save.data.comboStacking != null)
			comboStacking = FlxG.save.data.comboStacking;

		//rendering stuff
		if(FlxG.save.data.ffmpegMode != null) {
			ffmpegMode = FlxG.save.data.ffmpegMode;
		}
		if(FlxG.save.data.ffmpegInfo != null) {
			ffmpegInfo = FlxG.save.data.ffmpegInfo;
		}
		if(FlxG.save.data.targetFPS != null) {
			targetFPS = FlxG.save.data.targetFPS;
		}
		if(FlxG.save.data.lossless != null) {
			lossless = FlxG.save.data.lossless;
		}
		if(FlxG.save.data.quality != null) {
			quality = FlxG.save.data.quality;
		}
		if(FlxG.save.data.noCapture != null) {
			noCapture = FlxG.save.data.noCapture;
		}

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', CoolUtil.getSavePath());
		if(save != null && save.data.customControls != null) {
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls) {
				keyBinds.set(control, keys);
			}
			reloadControls();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls() {
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}
	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey> {
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len) {
			if(copiedArray[i] == NONE) {
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}
