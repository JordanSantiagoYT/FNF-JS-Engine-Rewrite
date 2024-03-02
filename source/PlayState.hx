package;

import flixel.graphics.FlxGraphic;
#if DISCORD_ALLOWED
import DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.filters.BitmapFilter;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSave;
import flixel.animation.FlxAnimationController;
import animateatlas.AtlasFrameMaker;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import Conductor.Rating;
import Shaders;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;

#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEOS_ALLOWED
#if (hxCodec >= "3.0.0" || hxCodec == "git")
import hxcodec.flixel.FlxVideo as MP4Handler;
#elseif (hxCodec == "2.6.1")
import hxcodec.VideoHandler as MP4Handler;
#elseif (hxCodec == "2.6.0")
import VideoHandler as MP4Handler;
#else
import vlc.MP4Handler;
#end
#end

using StringTools;

typedef PreloadedChartNote = {
	strumTime:Float,
	noteData:Int,
	mustPress:Bool,
	noteType:String,
	noteskin:String,
	texture:String,
	noAnimation:Bool,
	noMissAnimation:Bool,
	gfNote:Bool,
	isSustainNote:Bool,
	isSustainEnd:Bool,
	sustainLength:Float,
	parent:Note,
	prevNote:Note,
	strum:StrumNote
}

class PlayState extends MusicBeatState
{
	var noteRows:Array<Array<Array<Note>>> = [[],[]];
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public static var instance:PlayState;
	public static var STRUM_X = 48.5;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [];


	private var tauntKey:Array<FlxKey>;

	public var shader_chromatic_abberation:ChromaticAberrationEffect;
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];

	var lastUpdateTime:Float = 0.0;

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();
	#end

	public var hitSoundString:String = ClientPrefs.hitsoundType;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	var randomBotplayText:String;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";

	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var npsSpeedMult:Float = 1;

	public var frameCaptured:Int = 0;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var shaderUpdates:Array<Float->Void> = [];
	var botplayUsed:Bool = false;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public var tries:Int = 0;
	public var firstNoteStrumTime:Float = 0;
	var winning:Bool = false;
	var losing:Bool = false;

	var curTime:Float = 0;
	var songCalc:Float = 0;

	public var healthDrainAmount:Float = 0.023;
	public var healthDrainFloor:Float = 0.1;

	public var strumAnimsPerFrame:Array<Int> = [0, 0];

	public var vocals:FlxSound;
	public var dadGhostTween:FlxTween;
	public var bfGhostTween:FlxTween;
	public var gfGhostTween:FlxTween;
	public var dadGhost:FlxSprite;
	public var bfGhost:FlxSprite;
	public var gfGhost:FlxSprite;
	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;
	public var bfNoteskin:String = null;
	public var dadNoteskin:String = null;
	public static var death:FlxSprite;
	public static var deathanim:Bool = false;
	public static var dead:Bool = false;

	public static var iconOffset:Int = 26;

	var tankmanAscend:Bool = false; // funni (2021 nostalgia oh my god)
	public var isEkSong:Bool = false; //we'll use this so that the game doesn't load all notes twice?
	public var usingEkFile:Bool = false; //we'll also use this so that the game doesn't load all notes twice?

	public var memoryOver6GB:Bool = false; //For Rendering Mode

	public var notes:NoteGroup;
	public var sustainNotes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<PreloadedChartNote> = [];
	public var unspawnNotesCopy:Array<PreloadedChartNote> = [];
	public var eventNotes:Array<EventNote> = [];
	public var eventNotesCopy:Array<EventNote> = [];

	private var strumLine:FlxPoint;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;
	public var judgeColours:Map<String, FlxColor> = [
		"perfect" => 0xFFE367E5,
		"sick" => FlxColor.CYAN,
		"good" => FlxColor.LIME,
		"bad" => FlxColor.ORANGE,
		"shit" => FlxColor.RED,
		"miss" => 0xFF7F2626
	];

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var laneunderlay:FlxSprite;
	public var laneunderlayOpponent:FlxSprite;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float;
	private var displayedHealth:Float;
	public var maxHealth:Float = 2;


	public var totalNotesPlayed:Float = 0;
	public var combo:Float = 0;
	public var maxCombo:Float = 0;
	public var missCombo:Int = 0;

	public var timeThreshold:Float = 0;

		var notesAddedCount:Int = 0;
		var notesToRemoveCount:Int = 0;
		var oppNotesToRemoveCount:Int = 0;
	public var iconBopsThisFrame:Int = 0;
	public var iconBopsTotal:Int = 0;

	var endingTimeLimit:Int = 20;

	var camBopInterval:Int = 4;
	var camBopIntensity:Float = 1;

	var twistShit:Float = 1;
	var twistAmount:Float = 1;
	var camTwistIntensity:Float = 0;
	var camTwistIntensity2:Float = 3;
	var camTwist:Bool = false;

	private var healthBarBG:AttachedSprite; //The image used for the health bar.
	public var healthBar:FlxBar;
	var songPercent:Float = 0;
	var songPercentThing:Float = 0;
	var playbackRateDecimal:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var perfects:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	public var nps:Float = 0;
	public var maxNPS:Float = 0;
	public var oppNPS:Float = 0;
	public var maxOppNPS:Float = 0;
	public var enemyHits:Float = 0;
	public var opponentNoteTotal:Float = 0;
	public var polyphony:Float = 1;
	public var comboMultiplier:Float = 1;
	private var allSicks:Bool = true;

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

	public var oldNPS:Float = 0;
	public var oldOppNPS:Float = 0;

	private var lerpingScore:Bool = false;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;
	public static var playerIsCheating:Bool = false; //Whether the player is cheating. Enables if you change BOTPLAY or Practice Mode in the Pause menu

	public var shownScore:Float = 0;

	public var fcStrings:Array<String> = ['No Play', 'PFC', 'SFC', 'GFC', 'BFC', 'FC', 'SDCB', 'Clear', 'TDCB', 'QDCB'];
	public var hitStrings:Array<String> = ['Perfect!!!', 'Sick!!', 'Good!', 'Bad.', 'Shit.', 'Miss..'];
	public var judgeCountStrings:Array<String> = ['Perfects', 'Sicks', 'Goods', 'Bads', 'Shits', 'Misses'];

	var charChangeTimes:Array<Float> = [];
	var charChangeNames:Array<String> = [];
	var charChangeTypes:Array<Int> = [];

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var hpDrainLevel:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var sickOnly:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	inline function set_cpuControlled(value:Bool){
		cpuControlled = value;
		if (botplayTxt != null && !ClientPrefs.showcaseMode) // this assures it'll always show up
			botplayTxt.visible = (!ClientPrefs.hideHud) ? cpuControlled : false;

		return cpuControlled;
	}
	public var practiceMode:Bool = false;
	public var opponentDrain:Bool = false;
	public static var opponentChart:Bool = false;
	public static var bothsides:Bool = false;
	var randomMode:Bool = false;
	var flip:Bool = false;
	var stairs:Bool = false;
	var waves:Bool = false;
	var oneK:Bool = false;
	var randomSpeedThing:Bool = false;
	var trollingMode:Bool = false;
	public var jackingtime:Float = 0;

	public var songWasLooped:Bool = false; //If the song was looped. Used in Troll Mode
	public var shouldKillNotes:Bool = true; //Whether notes should be killed when you hit them. Disables automatically when in Troll Mode because you can't end the song anyway

	private var npsIncreased:Bool = false;
	private var npsDecreased:Bool = false;

	private var oppNpsIncreased:Bool = false;
	private var oppNpsDecreased:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	public var renderedTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	var hueh231:FlxSprite;
	var secretsong:FlxSprite;
	var SPUNCHBOB:FlxSprite;

	//ok moxie this doesn't cause memory leaks
	public var scoreTxtUpdateFrame:Int = 0;
	public var judgeCountUpdateFrame:Int = 0;
	public var compactUpdateFrame:Int = 0;
	public var popUpsFrame:Int = 0;
	public var missRecalcsPerFrame:Int = 0;
	public var charAnimsFrame:Int = 0;
	public var oppAnimsFrame:Int = 0;

	var notesHitArray:Array<Float> = [];
	var oppNotesHitArray:Array<Float> = [];
	var notesHitDateArray:Array<Float> = [];
	var oppNotesHitDateArray:Array<Float> = [];

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var EngineWatermark:FlxText;
	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	final phillyLightsColors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;
		public var compactCombo:String;
	public var compactScore:String;
	public var compactMisses:String;
	public var compactNPS:String;
		public var compactMaxCombo:String;
	public var compactTotalPlays:String;

	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	public static var screenshader:Shaders.PulseEffectAlt = new PulseEffectAlt();

	var disableTheTripper:Bool = false;
	var disableTheTripperAt:Int;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;
	public var singDurMult:Int = 1;

	public var disableCoolHealthTween:Bool = false;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	//ms timing popup shit
	public var msTxt:FlxText;
	public var msTimer:FlxTimer = null;
	public var restartTimer:FlxTimer = null;

	//ms timing popup shit except for simplified ratings
	public var judgeTxt:FlxText;
	public var judgeTxtTimer:FlxTimer = null;

	public var maxScore:Float = 0;
	public var oppScore:Float = 0;
	public var songScore:Float = 0;
	public var songHits:Int = 0;
	public var songMisses:Float = 0;
	public var scoreTxt:FlxText;
	var comboTxt:FlxText;
	var missTxt:FlxText;
	var accuracyTxt:FlxText;
	var npsTxt:FlxText;
	var timeTxt:FlxText;
	public var timerNow:FlxText = null;
	public var timerFinal:FlxText = null;
	var timePercentTxt:FlxText;

	var hitTxt:FlxText;

	var scoreTxtTween:FlxTween;
	var timeTxtTween:FlxTween;
	var judgementCounter:FlxText;

	public static var campaignScore:Float = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public static var shouldDrainHealth:Bool = false;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	var heyStopTrying:Bool = false;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public var luaArray:Array<FunkinLua> = [];
	public var achievementArray:Array<FunkinLua> = [];
	public var achievementWeeks:Array<String> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	var precacheList:Map<String, String> = new Map<String, String>();

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	//cam panning
	var moveCamTo:HaxeVector<Float> = new HaxeVector(2);

	var getTheBotplayText:Int = 0;

	var theListBotplay:Array<String> = [];

		var formattedMaxScore:String;
		var formattedSongScore:String;
		var formattedScore:String;
		var formattedSongMisses:String;
		var formattedCombo:String;
		var formattedMaxCombo:String;
		var formattedNPS:String;
		var formattedMaxNPS:String;
		var formattedOppNPS:String;
		var formattedMaxOppNPS:String;
		var formattedEnemyHits:String;
		var npsString:String;
		var accuracy:String;
		var fcString:String;
		var hitsound:FlxSound;

		var botText:String;
		var tempScore:String;

	// FFMpeg values :)
	var ffmpegMode = ClientPrefs.ffmpegMode;
	var ffmpegInfo = ClientPrefs.ffmpegInfo;
	var targetFPS = ClientPrefs.targetFPS;
	var noCapture = ClientPrefs.noCapture;
	static var capture:Screenshot = new Screenshot();

	override public function create()
	{
		if (Main.getMemoryAmount() > Math.pow(2, 32) * 1.5) memoryOver6GB = true;
		//Stops playing on a height that isn't divisible by 2
		if (ClientPrefs.ffmpegMode && ClientPrefs.resolution != null) {
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
		}
		if (ffmpegMode) {
			FlxG.fixedTimestep = true;
			FlxG.animationTimeScale = ClientPrefs.framerate / targetFPS;
		}
			var compactCombo:String = formatCompactNumber(combo);
			var compactMaxCombo:String = formatCompactNumber(maxCombo);
		var compactScore:String = formatCompactNumber(songScore);
		var compactMisses:String = formatCompactNumber(songMisses);
		var compactNPS:String = formatCompactNumber(nps);
		var compactTotalPlays:String = formatCompactNumber(totalNotesPlayed);
		theListBotplay = CoolUtil.coolTextFile(Paths.txt('botplayText'));

		randomBotplayText = theListBotplay[FlxG.random.int(0, theListBotplay.length - 1)];
		//trace('Playback Rate: ' + playbackRate);

			cpp.vm.Gc.enable(ClientPrefs.enableGC || ffmpegMode); //lagspike prevention
			Paths.clearStoredMemory();

			#if sys
			openfl.system.System.gc();
			#end


		// for lua
		instance = this;


	if (ClientPrefs.moreMaxHP)
	{
	maxHealth = 3;
	} else
	{
	maxHealth = 2;
	}

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
		tauntKey = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('qt_taunt'));

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		//Ratings
		if (!ClientPrefs.noMarvJudge)
		{
		ratingsData.push(new Rating('perfect'));
		}

		var rating:Rating = new Rating('sick');
		rating.ratingMod = 1;
		rating.score = 350;
		rating.noteSplash = true;
		ratingsData.push(rating);

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		screenshader.waveAmplitude = 1;
		screenshader.waveFrequency = 2;
		screenshader.waveSpeed = 1;
		screenshader.shader.uTime.value[0] = new flixel.math.FlxRandom().float(-100000, 100000);
		screenshader.shader.uampmul.value[0] = 0;

		#if windows
		screenshader.waveAmplitude = 1;
	   		screenshader.waveFrequency = 2;
			screenshader.waveSpeed = 1;
			screenshader.shader.uTime.value[0] = new flixel.math.FlxRandom().float(-100000, 100000);
		#end

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		hpDrainLevel = ClientPrefs.getGameplaySetting('drainlevel', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		sickOnly = ClientPrefs.getGameplaySetting('onlySicks', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		opponentChart = ClientPrefs.getGameplaySetting('opponentplay', false);
		trollingMode = ClientPrefs.getGameplaySetting('thetrollingever', false);
		opponentDrain = ClientPrefs.getGameplaySetting('opponentdrain', false);
		randomMode = ClientPrefs.getGameplaySetting('randommode', false);
		flip = ClientPrefs.getGameplaySetting('flip', false);
		stairs = ClientPrefs.getGameplaySetting('stairmode', false);
		waves = ClientPrefs.getGameplaySetting('wavemode', false);
		oneK = ClientPrefs.getGameplaySetting('onekey', false);
		randomSpeedThing = ClientPrefs.getGameplaySetting('randomspeed', false);
		jackingtime = ClientPrefs.getGameplaySetting('jacks', 0);

		if (trollingMode || SONG.song.toLowerCase() == 'anti-cheat-song')
			shouldKillNotes = false;

		if (ClientPrefs.showcaseMode)
			cpuControlled = true;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>((ClientPrefs.maxSplashLimit != 0 ? ClientPrefs.maxSplashLimit : 10000));

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;
		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "BRB! - " + detailsText;
		#end

		if (ClientPrefs.ratingType == 'Tails Gets Trolled V4')
		{
			fcStrings = ['No Play', 'KFC', 'AFC', 'CFC', 'SDC', 'FC', 'SDCB', 'Clear', 'TDCB', 'QDCB'];
			hitStrings = ['Killer!!!', 'Awesome!!', 'Cool!', 'Gay.', 'Retarded.', 'Fail..'];
			judgeCountStrings = ['Killers', 'Awesomes', 'Cools', 'Gays', 'Retardeds', 'Fails'];
		}
		if (ClientPrefs.longFCName) fcStrings = ['No Play', 'Perfect Full Combo', 'Sick Full Combo', 'Great Full Combo', 'Bad Full Combo', 'Full Combo', 'Single Digit Misses', 'Clear', 'TDCB', 'QDCB'];
		if (ClientPrefs.longFCName && ClientPrefs.ratingType == 'Tails Gets Trolled V4')
		{
			fcStrings = ['No Play', 'Killer Full Combo', 'Awesome Full Combo', 'Cool Full Combo', 'Gay Full Combo', 'Full Combo', 'Single Digit Misses', 'Clear', 'TDCB', 'QDCB'];
			hitStrings = ['Killer!!!', 'Awesome!!', 'Cool!', 'Gay.', 'Retarded.', 'Fail..'];
			judgeCountStrings = ['Killers', 'Awesomes', 'Cools', 'Gays', 'Retardeds', 'Fails'];
		}

		if (ClientPrefs.ratingType == 'Doki Doki+')
		{
			hitStrings = ['Very Doki!!!', 'Doki!!', 'Good!', 'OK.', 'No.', 'Miss..'];
			judgeCountStrings = ['Very Doki', 'Doki', 'Good', 'OK', 'No', 'Misses'];
		}

		if (ClientPrefs.ratingType == 'VS Impostor')
		{
			hitStrings = ['VERY SUSSY!!!', 'Sussy!!', 'Sus!', 'Sad.', 'ASS!', 'Miss..'];
			judgeCountStrings = ['Very Sussy', 'Sussy', 'Sus', 'Sad', 'Ass', 'Miss'];
		}
		if (ClientPrefs.ratingType == 'FIRE IN THE HOLE')
		{
			hitStrings = ['Easy :D', 'Normal!!', 'Hard!', 'Harder.', 'INSANE!', 'FIRE IN THE HOLE!'];
			judgeCountStrings = ['Easys', 'Normals', 'Hards', 'Harders', 'Insanes', 'Extreme Demon Fails'];
		}

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = (!ClientPrefs.charsAndBG ? "" : SONG.stage);
		//trace('stage is: ' + curStage);
		if(SONG.stage == null || SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
				dadbattleSmokes = new FlxSpriteGroup(); //troll'd

			case 'spooky': //Week 2
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');

			case 'philly': //Week 3
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					precacheList.set('dancerdeath', 'sound');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				precacheList.set('Lights_Shut_off', 'sound');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

			case 'tank': //Week 7 - Ugh, Guns, Stress
				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(sky);

				if(!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if(!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);
				moveTank();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
		}

		switch(Paths.formatToSongPath(SONG.song))
		{
			case 'stress':
				GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		dadGhost = new FlxSprite();
		bfGhost = new FlxSprite();
		gfGhost = new FlxSprite();
		add(gfGroup); //Needed for blammed lights
		if (ClientPrefs.doubleGhost)
		{
		add(bfGhost);
		add(gfGhost);
		add(dadGhost);
		}

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(boyfriendGroup);

		switch(curStage)
		{
			case 'spooky':
				add(halloweenWhite);
			case 'tank':
				add(foregroundSprites);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						if (Std.string(file) == 'extra keys hscript.lua')
						{
						trace ('theres a lua extra keys file');
						usingEkFile = true;
						}
						filesPushed.push(file);
					}
				}
			}
		}
		#end


		//CUSTOM ACHIVEMENTS
		#if (MODS_ALLOWED && LUA_ALLOWED && ACHIEVEMENTS_ALLOWED)
		var luaFiles:Array<String> = Achievements.getModAchievements().copy();
		if(luaFiles.length > 0){
			for(luaFile in luaFiles)
			{
				var lua = new FunkinLua(luaFile);
				luaArray.push(lua);
				achievementArray.push(lua);
			}
		}

		var achievementMetas = Achievements.getModAchievementMetas().copy();
		for (i in achievementMetas) {
			if(i.lua_code != null) {
				var lua = new FunkinLua(null, i.lua_code);
				luaArray.push(lua);
				achievementArray.push(lua);
			}
			if(i.week_nomiss != null) {
				achievementWeeks.push(i.week_nomiss);
			}
		}
		#end

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		startLuasOnFolder('stages/' + curStage + '.lua');
		#end
			if(ClientPrefs.communityGameMode)
			{
				SONG.gfVersion = 'gf-bent';
				trace('using the suspicious gf skin, horny ass mf.');
			}
		var gfVersion:String = SONG.gfVersion;

		if(gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}


			switch(Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor

		}
		health = maxHealth / 2;
		displayedHealth = maxHealth / 2;

		if (!stageData.hide_girlfriend && ClientPrefs.charsAndBG)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);

			if(gfVersion == 'pico-speaker')
			{
				if(!ClientPrefs.lowQuality)
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length)
					{
						if(FlxG.random.bool(16)) {
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
							tankmanRun.add(tankBih);
						}
					}
				}
			}
		}

	if (ClientPrefs.rateNameStuff == 'Quotes')
	{
	ratingStuff = [
		['you suck ass lol', 0.2], //From 0% to 19%
		['you aint doin good', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['funny number', 0.69417], //69.0% to 69.419% ( ͡° ͜ʖ ͡°)
		['( ͡° ͜ʖ ͡°)', 0.6943], //69.420% ( ͡° ͜ʖ ͡°)
		['funny number', 0.7], //69.421% to 69.999% ( ͡° ͜ʖ ͡°)
		['nice', 0.8], //From 70% to 79%
		['awesome', 0.9], //From 80% to 89%
		['thats amazing', 1], //From 90% to 99%
		['PERFECT!!!!!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	}
	if (ClientPrefs.rateNameStuff == 'Psych Quotes')
	{
	ratingStuff = [
		['How are you this bad?', 0.1], //From 0% to 9%
		['You Suck!', 0.2], //From 10% to 19%
		['Horribly Shit', 0.3], //From 20% to 29%
		['Shit', 0.4], //From 30% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	}
	if (ClientPrefs.rateNameStuff == 'Shaggyverse Quotes')
	{
	ratingStuff = [
		['G - Ruh Rouh!', 0.2], //From 0% to 19%
		['F - OOF', 0.4], //From 20% to 39%
		["E - Like, You're Bad", 0.5], //From 40% to 49%
		['D - Like, how are you still alive?', 0.6], //From 50% to 59%
		['C - ZOINKS!', 0.69], //From 60% to 68%
		["Nice - WOW, that's a funny number man!", 0.7], //69%
		["B - That's like, really cool...", 0.75], //From 70% to 74%
		["B+ - Hey, man, you're starting to improve!", 0.8], //From 75% to 79%
		['A - This is a challenge!', 0.85], //From 80% to 84%
		['AA - Hey Scoob, This kid is good!', 0.9], //From 85% to 90%
		['S - Like, Thats Good', 0.95], //From 90% to 94%
		['SS - Like, Thats Great!', 0.99], //From 95% to 98%
		['SSS - Like, Thats Sick!', 1], //99%
		['SSSS - Like, WOW', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	}
	if (ClientPrefs.rateNameStuff == 'Letters')
	{
	ratingStuff = [
		['HOW?', 0.2], //From 0% to 19%
		['F', 0.4], //From 20% to 39%
		['E', 0.5], //From 40% to 49%
		['D', 0.6], //From 50% to 59%
		['C', 0.69], //From 60% to 68%
		['FUNNY', 0.7], //69%
		['B', 0.8], //From 70% to 79%
		['A', 0.9], //From 80% to 89%
		['S', 0.97], //From 90% to 98%
		['S+', 1], //98% to 99%
		['X', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	}
		if (!ClientPrefs.charsAndBG)
		{
		dad = new Character(0, 0, "");
		dadGroup.add(dad);

		boyfriend = new Boyfriend(0, 0, "");
		boyfriendGroup.add(boyfriend);
		} else
		{
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
		dadNoteskin = dad.noteskin;

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		bfNoteskin = boyfriend.noteskin;
		}
		if (ClientPrefs.charsAndBG && ClientPrefs.doubleGhost)
		{
		dadGhost.visible = false;
		dadGhost.antialiasing = true;
		dadGhost.scale.copyFrom(dad.scale);
		dadGhost.updateHitbox();
		bfGhost.visible = false;
		bfGhost.antialiasing = true;
		bfGhost.scale.copyFrom(boyfriend.scale);
		bfGhost.updateHitbox();
		if (!stageData.hide_girlfriend || ClientPrefs.charsAndBG && !stageData.hide_girlfriend) { //stops crashes if the stage data specifies to hide gf
		gfGhost.visible = false;
		gfGhost.antialiasing = true;
		gfGhost.scale.copyFrom(gf.scale);
		gfGhost.updateHitbox();
		}
		}

		shouldDrainHealth = (opponentDrain || (opponentChart ? boyfriend.healthDrain : dad.healthDrain));
		if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainAmount)) healthDrainAmount = opponentChart ? boyfriend.drainAmount : dad.drainAmount;
		if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainFloor)) healthDrainFloor = opponentChart ? boyfriend.drainFloor : dad.drainFloor;

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				addBehindGF(fastCar);

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				addBehindDad(evilTrail);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000 / Conductor.songPosition;

		laneunderlayOpponent = new FlxSprite(70, 0).makeGraphic(500, FlxG.height * 2, FlxColor.BLACK);
		laneunderlayOpponent.alpha = ClientPrefs.laneUnderlayAlpha;
		laneunderlayOpponent.scrollFactor.set();
		laneunderlayOpponent.screenCenter(Y);
		laneunderlayOpponent.visible = ClientPrefs.laneUnderlay;

		laneunderlay = new FlxSprite(70 + (FlxG.width / 2), 0).makeGraphic(500, FlxG.height * 2, FlxColor.BLACK);
		laneunderlay.alpha = ClientPrefs.laneUnderlayAlpha;
		laneunderlay.scrollFactor.set();
		laneunderlay.screenCenter(Y);
		laneunderlay.visible = ClientPrefs.laneUnderlay;

		if (ClientPrefs.laneUnderlay)
		{
			add(laneunderlayOpponent);
			add(laneunderlay);
		}

		strumLine = FlxPoint.get(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, (ClientPrefs.downScroll) ? FlxG.height - 150 : 50);

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;
		switch (ClientPrefs.hudType)
		{
		case 'Psych Engine':
			timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.borderSize = 2;

		case 'Leather Engine':
			timeTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.borderSize = 2;

		case 'JS Engine':
			timeTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.borderSize = 3;

		case 'Tails Gets Trolled V4':
			timeTxt.setFormat(Paths.font("calibri.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.borderSize = 2;

		case 'Kade Engine':
			timeTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.borderSize = 1;

		case 'Dave and Bambi':
			timeTxt.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.borderSize = 2;

		case 'Doki Doki+':
			timeTxt.setFormat(Paths.font("Aller_rg.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.borderSize = 2;

		case 'VS Impostor':
			timeTxt.x = STRUM_X + (FlxG.width / 2) - 585;
			timeTxt.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.borderSize = 1;
		}


		if(ClientPrefs.timeBarType == 'Song Name' && !ClientPrefs.timebarShowSpeed)
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;


		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);  // Adjust y position if needed for specific hudTypes
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime && !ClientPrefs.timeBarType.contains('(No Bar)');
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.numDivisions = 800; // Adjust numDivisions if needed for performance
		timeBar.alpha = 0;
		timeBar.visible = showTime && !ClientPrefs.timeBarType.contains('(No Bar)');
		if (ClientPrefs.hudType != 'Dave and Bambi') add(timeBar);
		timeBarBG.sprTracker = timeBar;

		switch (ClientPrefs.hudType) {
			case 'VS Impostor':
				timeBarBG.loadGraphic(Paths.image('impostorTimeBar'));
				timeBar.createFilledBar(0xFF2e412e, 0xFF44d844);
				timeTxt.x += 10;
				timeTxt.y += 4;

			case 'Psych Engine', 'Tails Gets Trolled V4':
				timeBarBG.loadGraphic(Paths.image('timeBar'));
				timeBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
				timeBarBG.color = FlxColor.BLACK;

			case 'Leather Engine':
				if (timeBarBG != null && timeBar != null){
					timeBarBG.destroy();
					timeBar.destroy();
				}
				timeBarBG = new AttachedSprite('editorHealthBar');
				timeBarBG.x = timeTxt.x;
				timeBarBG.y = timeTxt.y + (timeTxt.height / 8);
				timeBarBG.scrollFactor.set();
				timeBarBG.alpha = 0;
				timeBarBG.visible = showTime;
				timeBarBG.color = FlxColor.BLACK;
				timeBarBG.xAdd = -4;
				timeBarBG.yAdd = -4;
				timeBarBG.screenCenter(X);
				add(timeBarBG);

				timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
				'songPercent', 0, 1);
				timeBar.scrollFactor.set();
				timeBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
				timeBar.numDivisions = 400; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
				timeBar.alpha = 0;
				timeBar.visible = showTime;
				add(timeBar);
				timeBarBG.sprTracker = timeBar;

			case 'Kade Engine':
				if (timeBarBG != null && timeBar != null){
					timeBarBG.destroy();
					timeBar.destroy();
				}
				timeBarBG = new AttachedSprite('editorHealthBar');
				timeBarBG.x = timeTxt.x;
				timeBarBG.y = timeTxt.y + (timeTxt.height / 8);
				timeBarBG.scrollFactor.set();
				timeBarBG.alpha = 0;
				timeBarBG.visible = showTime;
				timeBarBG.color = FlxColor.BLACK;
				timeBarBG.xAdd = -4;
				timeBarBG.yAdd = -4;
				timeBarBG.screenCenter(X);
				add(timeBarBG);

				timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
				'songPercent', 0, 1);
				timeBar.scrollFactor.set();
				timeBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
				timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
				timeBar.alpha = 0;
				timeBar.visible = showTime;
				add(timeBar);
				timeBarBG.sprTracker = timeBar;

			case 'Dave and Bambi':
				if (timeBarBG != null && timeBar != null){
					timeBarBG.destroy();
					timeBar.destroy();
				}
				timeBarBG = new AttachedSprite('DnBTimeBar');
				timeBarBG.screenCenter(X);
				timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
				timeBarBG.antialiasing = true;
				timeBarBG.scrollFactor.set();
				timeBarBG.visible = showTime;
				timeBarBG.xAdd = -4;
				timeBarBG.yAdd = -4;
				add(timeBarBG);

				timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
				'songPercent', 0, 1);
				timeBar.scrollFactor.set();
				timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
				timeBar.alpha = 0;
				timeBar.visible = showTime;
				timeBarBG.sprTracker = timeBar;
				timeBar.createFilledBar(FlxColor.GRAY, FlxColor.fromRGB(57, 255, 20));
				insert(members.indexOf(timeBarBG), timeBar);

			case 'Doki Doki+':
				timeBarBG.loadGraphic(Paths.image("dokiTimeBar"));
				timeBarBG.screenCenter(X);
				timeBar.createGradientBar([FlxColor.TRANSPARENT], [FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2])]);

			case 'JS Engine':
				if (timeBarBG != null && timeBar != null){
					timeBarBG.destroy();
					timeBar.destroy();
				}
				timeBarBG = new AttachedSprite('healthBar');
				timeBarBG.screenCenter(X);
				timeBarBG.x = timeTxt.x;
				timeBarBG.y = timeTxt.y + (timeTxt.height / 8);
				timeBarBG.scrollFactor.set();
				timeBarBG.alpha = 0;
				timeBarBG.visible = showTime;
				timeBarBG.color = FlxColor.BLACK;
				timeBarBG.xAdd = -4;
				timeBarBG.yAdd = -4;
				timeBarBG.screenCenter(X);
				add(timeBarBG);

				timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
				'songPercent', 0, 1);
				timeBar.scrollFactor.set();
				timeBar.numDivisions = 1000; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
				timeBar.alpha = 0;
				timeBar.visible = showTime;
				timeBarBG.sprTracker = timeBar;
				timeBar.createGradientBar([FlxColor.TRANSPARENT], [FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]), FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2])]);
			add(timeBar);
		}
			add(timeTxt);

		sustainNotes = new FlxTypedGroup<Note>();
		add(sustainNotes);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		notes = new NoteGroup();
		add(notes);
		notes.visible = ClientPrefs.showNotes; //that was easier than expected

		add(grpNoteSplashes);


		if(ClientPrefs.timeBarType == 'Song Name' && ClientPrefs.hudType == 'VS Impostor')
		{
			timeTxt.size = 14;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		playerStrums = new FlxTypedGroup<StrumNote>();
		opponentStrums = new FlxTypedGroup<StrumNote>();

		trace ('Loading chart...');
		generateSong(SONG.song, startOnTime);

		if (SONG.event7 == null || SONG.event7 == '') SONG.event7 == 'None';

		if (curSong.toLowerCase() == "guns") // added this to bring back the old 2021 fnf vibes, i wish the fnf fandom revives one day :(
		{
			var randomVar:Int = 0;
			if (!ClientPrefs.noGunsRNG) randomVar = Std.random(15);
			if (ClientPrefs.noGunsRNG) randomVar = 8;
			trace(randomVar);
			if (randomVar == 8)
			{
				trace('AWW YEAH, ITS ASCENDING TIME');
				tankmanAscend = true;
			}
		}

		if (notes.members[0] != null) firstNoteStrumTime = notes.members[0].strumTime;

		camFollow = FlxPoint.get();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		if (!ClientPrefs.charsAndBG) FlxG.camera.zoom = 100; //zoom it in very big to avoid high RAM usage!!
		if (ClientPrefs.charsAndBG)
		{
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		}
		FlxG.fixedTimestep = false;
		moveCameraSection();

		msTxt = new FlxText(0, 0, 0, "");
		msTxt.cameras = (ClientPrefs.wrongCameras ? [camGame] : [camHUD]);
		msTxt.scrollFactor.set();
		msTxt.setFormat("vcr.ttf", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.hudType == 'Tails Gets Trolled V4') msTxt.setFormat("calibri.ttf", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.hudType == 'Dave and Bambi') msTxt.setFormat("comic.ttf", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.hudType == 'Doki Doki+') msTxt.setFormat("Aller_rg.ttf", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		msTxt.x = 408 + 250;
		msTxt.y = 290 - 25;
		if (PlayState.isPixelStage) {
			msTxt.x = 408 + 260;
			msTxt.y = 290 + 20;
		}
		msTxt.x += ClientPrefs.comboOffset[0];
		msTxt.y -= ClientPrefs.comboOffset[1];
		msTxt.active = false;
		msTxt.visible = false;
		insert(members.indexOf(strumLineNotes), msTxt);

		judgeTxt = new FlxText(400, timeBarBG.y + 120, FlxG.width - 800, "");
		judgeTxt.cameras = (ClientPrefs.wrongCameras ? [camGame] : [camHUD]);
		judgeTxt.scrollFactor.set();
		judgeTxt.setFormat("vcr.ttf", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.hudType == 'Tails Gets Trolled V4') judgeTxt.setFormat("calibri.ttf", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.hudType == 'Dave and Bambi') judgeTxt.setFormat("comic.ttf", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.hudType == 'Doki Doki+') judgeTxt.setFormat("Aller_rg.ttf", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		judgeTxt.active = false;
		judgeTxt.size = 32;
		judgeTxt.visible = false;
		add(judgeTxt);
		if (ClientPrefs.hudType == 'Dave and Bambi')
		{
			if (ClientPrefs.longHPBar)
			{
				healthBarBG = new AttachedSprite('longDnBHealthBar');
			} else
			{
				healthBarBG = new AttachedSprite('DnBHealthBar');
			}
		}
		if (ClientPrefs.hudType == 'Doki Doki+')
		{
			if (ClientPrefs.longHPBar)
			{
				healthBarBG = new AttachedSprite('longDokiHealthBar');
			} else
			{
				healthBarBG = new AttachedSprite('dokiHealthBar');
			}
		} else if (ClientPrefs.hudType != 'Dave and Bambi' && ClientPrefs.hudType != 'Doki Doki+') {
			if (ClientPrefs.longHPBar)
			{
				healthBarBG = new AttachedSprite('longHealthBar');
			} else
			{
				healthBarBG = new AttachedSprite('healthBar');
			}
		}
		healthBarBG.y = (disableCoolHealthTween ? FlxG.height * 0.89 : FlxG.height * 1.13);
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = (disableCoolHealthTween ? 0.11 * FlxG.height : -0.13 * FlxG.height);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'displayedHealth', 0, maxHealth);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		insert(members.indexOf(healthBarBG), healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors(dad.healthColorArray, boyfriend.healthColorArray);

		if (ClientPrefs.smoothHealth && ClientPrefs.smoothHealthType == 'Golden Apple 1.5') healthBar.numDivisions = Std.int(healthBar.width);

		if (SONG.player1 == 'bf' || SONG.player1 == 'boyfriend') {
			final iconToChange:String = switch (ClientPrefs.bfIconStyle){
				case 'VS Nonsense V2': 'bfnonsense';
				case 'Doki Doki+': 'bfdoki';
				case 'Leather Engine': 'bfleather';
				case "Mic'd Up": 'bfmup';
				case "FPS Plus": 'bffps';
				case "SB Engine": 'bfsb';
				case "OS 'Engine'": 'bfos';
				default:
					'bf';
			}
			if (iconToChange != 'bf')
				iconP1.changeIcon(iconToChange);
		}

		if (ClientPrefs.timeBarType == 'Disabled') {
			timeBarBG.destroy();
			timeBar.destroy();
		}

		if (ClientPrefs.hudType == 'Kade Engine') {
			EngineWatermark = new FlxText(4,FlxG.height * 0.9 + 50,0,"", 16);
			EngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			EngineWatermark.scrollFactor.set();
			add(EngineWatermark);
			EngineWatermark.text = SONG.song + " " + CoolUtil.difficultyString() + " | JSE " + MainMenuState.psychEngineJSVersion;
		}
		if (ClientPrefs.hudType == 'JS Engine') {
			EngineWatermark = new FlxText(4,FlxG.height * 0.1 - 70,0,"", 15);
			EngineWatermark.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			EngineWatermark.scrollFactor.set();
			if (ClientPrefs.downScroll) EngineWatermark.y = (FlxG.height * 0.9 + 50);
			add(EngineWatermark);
			EngineWatermark.text = "You are now playing " + SONG.song + " on " + CoolUtil.difficultyString() + "! (JSE v" + MainMenuState.psychEngineJSVersion + ")";
		}
		if (ClientPrefs.hudType == 'Dave and Bambi') {
			EngineWatermark = new FlxText(4,FlxG.height * 0.9 + 50,0,"", 16);
			EngineWatermark.setFormat(Paths.font("comic.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			EngineWatermark.scrollFactor.set();
			add(EngineWatermark);
			EngineWatermark.text = SONG.song;
		}

		if (ClientPrefs.showcaseMode && !ClientPrefs.charsAndBG) {
			hitTxt = new FlxText(0, 20, 10000, "test", 42);
			hitTxt.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			hitTxt.scrollFactor.set();
			hitTxt.borderSize = 2;
			hitTxt.visible = true;
			hitTxt.cameras = [camHUD];
			//hitTxt.alignment = FlxTextAlign.LEFT; // center the text
			//hitTxt.screenCenter(X);
			hitTxt.screenCenter(Y);
			add(hitTxt);
				var chromaScreen = new FlxSprite(-5000, -2000).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.GREEN);
				chromaScreen.scrollFactor.set(0, 0);
				chromaScreen.scale.set(3, 3);
				chromaScreen.updateHitbox();
				add(chromaScreen);
		}

		if (ClientPrefs.hudType == 'Kade Engine')
		{
			scoreTxt = new FlxText(0, healthBarBG.y + 50, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 1;
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
			add(scoreTxt);
		}
		if (ClientPrefs.hudType == 'JS Engine')
		{
			scoreTxt = new FlxText(0, healthBarBG.y + 50, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 2;
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
			add(scoreTxt);
		}
		if (ClientPrefs.hudType == "Mic'd Up")
		{
			scoreTxt = new FlxText(healthBarBG.x - (healthBarBG.width / 2), healthBarBG.y - 26, 0, "", 20);
			if (ClientPrefs.downScroll)
				scoreTxt.y = healthBarBG.y + 18;
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
			scoreTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			scoreTxt.scrollFactor.set();
			add(scoreTxt);
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;

			missTxt = new FlxText(scoreTxt.x, scoreTxt.y - 26, 0, "", 20);
			if (ClientPrefs.downScroll)
				missTxt.y = scoreTxt.y + 26;
			missTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
			missTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			missTxt.scrollFactor.set();
			add(missTxt);
			missTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;

			accuracyTxt = new FlxText(missTxt.x, missTxt.y - 26, 0, "", 20);
			if (ClientPrefs.downScroll)
				accuracyTxt.y = missTxt.y + 26;
			accuracyTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
			accuracyTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			accuracyTxt.scrollFactor.set();
			add(accuracyTxt);
			accuracyTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;

			comboTxt = new FlxText(scoreTxt.x, scoreTxt.y + 26, 0, "", 21);
			if (ClientPrefs.downScroll)
				comboTxt.y = scoreTxt.y - 26;
			comboTxt.setFormat(Paths.font("vcr.ttf"), 21, FlxColor.WHITE, RIGHT);
			comboTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			comboTxt.scrollFactor.set();
			add(comboTxt);
			comboTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;

			npsTxt = new FlxText(accuracyTxt.x, accuracyTxt.y - 46, 0, "", 20);
			if (ClientPrefs.downScroll)
				npsTxt.y = accuracyTxt.y + 46;
			npsTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
			npsTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			npsTxt.scrollFactor.set();
			add(npsTxt);
			npsTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
		}
		if (ClientPrefs.hudType == 'Box Funkin')
		{
			scoreTxt = new FlxText(25, healthBarBG.y - 26, 0, "", 21);
			if (ClientPrefs.downScroll)
				scoreTxt.y = healthBarBG.y + 26;
			scoreTxt.setFormat(Paths.font("MilkyNice.ttf"), 21, FlxColor.WHITE, RIGHT);
			scoreTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			scoreTxt.scrollFactor.set();
			add(scoreTxt);
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;

			missTxt = new FlxText(scoreTxt.x, scoreTxt.y - 26, 0, "", 21);
			if (ClientPrefs.downScroll)
				missTxt.y = scoreTxt.y + 26;
			missTxt.setFormat(Paths.font("MilkyNice.ttf"), 21, FlxColor.WHITE, RIGHT);
			missTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			missTxt.scrollFactor.set();
			add(missTxt);
			missTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;

			accuracyTxt = new FlxText(missTxt.x, missTxt.y - 26, 0, "", 21);
			if (ClientPrefs.downScroll)
				accuracyTxt.y = missTxt.y + 26;
			accuracyTxt.setFormat(Paths.font("MilkyNice.ttf"), 21, FlxColor.WHITE, RIGHT);
			accuracyTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			accuracyTxt.scrollFactor.set();
			add(accuracyTxt);
			accuracyTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;

			comboTxt = new FlxText(scoreTxt.x, scoreTxt.y + 26, 0, "", 21);
			if (ClientPrefs.downScroll)
				comboTxt.y = scoreTxt.y - 26;
			comboTxt.setFormat(Paths.font("MilkyNice.ttf"), 21, FlxColor.WHITE, RIGHT);
			comboTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			comboTxt.scrollFactor.set();
			add(comboTxt);
			comboTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;

			npsTxt = new FlxText(accuracyTxt.x, accuracyTxt.y - 46, 0, "", 21);
			if (ClientPrefs.downScroll)
				npsTxt.y = accuracyTxt.y + 46;
			npsTxt.setFormat(Paths.font("MilkyNice.ttf"), 21, FlxColor.WHITE, RIGHT);
			npsTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
			npsTxt.scrollFactor.set();
			add(npsTxt);
			npsTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
		}
		if (ClientPrefs.hudType == 'Leather Engine')
		{
			scoreTxt = new FlxText(0, healthBarBG.y + 50, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 1;
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
			add(scoreTxt);
		}
		if (ClientPrefs.hudType == 'Dave and Bambi')
		{
			scoreTxt = new FlxText(0, healthBarBG.y + 40, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("comic.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 1.25;
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
			add(scoreTxt);
		}
		if (ClientPrefs.hudType == 'Psych Engine')
		{
			scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 1.25;
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
			add(scoreTxt);
		}
		if (ClientPrefs.hudType == 'Doki Doki+')
		{
			scoreTxt = new FlxText(0, healthBarBG.y + 48, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("Aller_rg.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 1.25;
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
			add(scoreTxt);
		}
		if (ClientPrefs.hudType == 'Tails Gets Trolled V4')
		{
			scoreTxt = new FlxText(0, healthBarBG.y + 48, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("calibri.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 1.25;
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
			add(scoreTxt);
		}
		if (ClientPrefs.hudType == 'VS Impostor')
		{
			scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
			scoreTxt.scrollFactor.set();
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 1.25;
			scoreTxt.visible = !ClientPrefs.hideHud || !ClientPrefs.showcaseMode;
			add(scoreTxt);
		}
		if (ClientPrefs.hideScore || ClientPrefs.showcaseMode) {
			scoreTxt.destroy();
			healthBarBG.visible = false;
			healthBar.visible = false;
			iconP2.visible = iconP1.visible = false;
		}
		if (ClientPrefs.hideHud) {
			scoreTxt.destroy();
			final daArray:Array<Dynamic> = [botplayTxt, healthBarBG, healthBar, iconP2, iconP1];
						for (i in daArray){
				if (i != null)
					i.visible = false;
			}
		}
		if (!ClientPrefs.charsAndBG) {
			remove(dadGroup);
			remove(boyfriendGroup);
			remove(gfGroup);
			gfGroup.destroy();
			dadGroup.destroy();
			boyfriendGroup.destroy();
		}
		if (ClientPrefs.scoreTxtSize > 0 && scoreTxt != null && !ClientPrefs.showcaseMode && !ClientPrefs.hideScore) scoreTxt.size = ClientPrefs.scoreTxtSize;
		if (!ClientPrefs.hideScore) updateScore();

		renderedTxt = new FlxText(0, healthBarBG.y - 50, FlxG.width, "", 40);
		renderedTxt.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		renderedTxt.scrollFactor.set();
		renderedTxt.borderSize = 1.25;
		renderedTxt.cameras = [camHUD];
		renderedTxt.visible = ClientPrefs.showRendered;

		if (ClientPrefs.downScroll) renderedTxt.y = healthBar.y + 50;
		if (ClientPrefs.hudType == 'VS Impostor') renderedTxt.y = healthBar.y + (ClientPrefs.downScroll ? 100 : -100);
		add(renderedTxt);

		judgementCounter = new FlxText(0, FlxG.height / 2 - 80, 0, "", 20);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		judgementCounter.borderSize = 2;
		judgementCounter.scrollFactor.set();
		judgementCounter.visible = ClientPrefs.ratingCounter && !ClientPrefs.showcaseMode;
		add(judgementCounter);
		if (ClientPrefs.ratingCounter) updateRatingCounter();

		// just because, people keep making issues about it
		try{
			if (ClientPrefs.hudType == 'Psych Engine')
			{
				botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
				botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.borderSize = 1.25;
				botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
				add(botplayTxt);
				if (ClientPrefs.downScroll)
					botplayTxt.y = timeBarBG.y - 78;
			}
			if (ClientPrefs.hudType == 'JS Engine')
			{
				botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "Botplay Mode", 30);
				botplayTxt.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.borderSize = 1.5;
				botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
				add(botplayTxt);
				if (ClientPrefs.downScroll)
					botplayTxt.y = timeBarBG.y - 78;
			}
			if (ClientPrefs.hudType == 'Box Funkin')
			{
				botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
				botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.borderSize = 1.25;
				botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
				add(botplayTxt);
				if (ClientPrefs.downScroll)
					botplayTxt.y = timeBarBG.y - 78;
			}
			if (ClientPrefs.hudType == "Mic'd Up")
			{
				botplayTxt = new FlxText((healthBarBG.width / 2), healthBar.y, 0, "AutoPlayCPU", 20);
				botplayTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.screenCenter(X);
				botplayTxt.borderSize = 3;
				botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
				add(botplayTxt);
				if (ClientPrefs.downScroll)
					botplayTxt.y = timeBarBG.y - 78;
			}
			if (ClientPrefs.hudType == 'Kade Engine')
			{
				botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
				botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.borderSize = 1.25;
				botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
				add(botplayTxt);
				if (ClientPrefs.downScroll)
					botplayTxt.y = timeBarBG.y - 78;
			}
			if (ClientPrefs.hudType == 'Doki Doki+')
			{
				botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
				botplayTxt.setFormat(Paths.font("Aller_rg.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.borderSize = 1.25;
				botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
				add(botplayTxt);
				if (ClientPrefs.downScroll)
					botplayTxt.y = timeBarBG.y - 78;
			}
			if (ClientPrefs.hudType == 'Tails Gets Trolled V4')
			{
				botplayTxt = new FlxText(400, timeBarBG.y + (ClientPrefs.downScroll ? -78 : 55), FlxG.width - 800, "[BUTTPLUG]", 32);
				botplayTxt.setFormat(Paths.font("calibri.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.borderSize = 1.25;
				botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
				add(botplayTxt);
				if (ClientPrefs.downScroll)
					botplayTxt.y = timeBarBG.y - 78;
			}
			if (ClientPrefs.hudType == 'Dave and Bambi')
			{
				botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
				botplayTxt.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.borderSize = 1.25;
				botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
				add(botplayTxt);
				if (ClientPrefs.downScroll)
					botplayTxt.y = timeBarBG.y - 78;
			}
			if (ClientPrefs.hudType == 'VS Impostor')
			{
				botplayTxt = new FlxText(400, healthBarBG.y - 55, FlxG.width - 800, "BOTPLAY", 32);
				botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				botplayTxt.scrollFactor.set();
				botplayTxt.borderSize = 1.25;
				botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
				add(botplayTxt);
				if (ClientPrefs.downScroll)
				{
					botplayTxt.y = timeBarBG.y - 78;
				}
			}
		}
		catch(e){
			trace("Failed to display/create botplayTxt " + e);
			// just in case, we default it to the regular psych botplayTxt
			botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
			botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			botplayTxt.scrollFactor.set();
			botplayTxt.borderSize = 1.25;
			botplayTxt.visible = cpuControlled && !ClientPrefs.showcaseMode;
			add(botplayTxt);
			if (ClientPrefs.downScroll)
				botplayTxt.y = timeBarBG.y - 78;
		}
		if (botplayTxt != null){
			if (!cpuControlled && practiceMode) {
			botplayTxt.text = 'Practice Mode';
			botplayTxt.visible = true;
			}
			if (ClientPrefs.showcaseMode) {
			botplayTxt.y += (!ClientPrefs.downScroll ? 60 : -60);
			botplayTxt.text = 'NPS: $nps/$maxNPS\nOpp NPS: $oppNPS/$maxOppNPS';
			botplayTxt.visible = true;
			}
		}
			if (ClientPrefs.showRendered)
			renderedTxt.text = 'Rendered Notes: ' + FlxStringUtil.formatMoney(notes.length, false);

		if (ClientPrefs.communityGameBot && botplayTxt != null) botplayTxt.destroy();

		laneunderlayOpponent.cameras = [camHUD];
		laneunderlay.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		sustainNotes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		if (EngineWatermark != null) EngineWatermark.cameras = [camHUD];
		judgementCounter.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		if (botplayTxt != null) botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		startingSong = true;
		MusicBeatState.windowNameSuffix = " - " + SONG.song + " " + (isStoryMode ? "(Story Mode)" : "(Freeplay)");

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			startLuasOnFolder('custom_notetypes/' + notetype + '.lua');
		}
		for (event in eventPushedMap.keys())
		{
			startLuasOnFolder('custom_events/' + event + '.lua');
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/' ));// using push instead of insert because these should run after everything else
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					tankIntro();

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (hitSoundString != "none")
			hitsound = FlxG.sound.load(Paths.sound("hitsounds/" + Std.string(hitSoundString).toLowerCase()));
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		hitsound.volume = ClientPrefs.hitsoundVolume;
		hitsound.pitch = playbackRate;
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end


		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		callOnLuas('onCreatePost', []);

		super.create();

		if(cpuControlled && ClientPrefs.randomBotplayText && ClientPrefs.hudType != 'Leather Engine' && botplayTxt != null && !ffmpegInfo)
			{
				botplayTxt.text = theListBotplay[FlxG.random.int(0, theListBotplay.length - 1)];
			}

		cacheCountdown();
		if (ClientPrefs.ratingType != 'Simple') cachePopUpScore();
		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
			Paths.clearUnusedMemory();

		CustomFadeTransition.nextCamera = camOther;
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if (ratio != 1)
			{
				for (note in notes){
				 	if (note == null)
						continue;
					note.resizeByRatio(ratio);
				}
				for (note in sustainNotes){
				 	if (note == null)
						continue;
					note.resizeByRatio(ratio);
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		trace('Anim speed: ' + FlxG.animationTimeScale);
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors(leftColorArray:Array<Int>, rightColorArray:Array<Int>) {
		if (!ClientPrefs.ogHPColor) {
				healthBar.createFilledBar(FlxColor.fromRGB(leftColorArray[0], leftColorArray[1], leftColorArray[2]),
				FlxColor.fromRGB(rightColorArray[0], rightColorArray[1], rightColorArray[2]));
		} else if (ClientPrefs.ogHPColor) {
				healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		}

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	public function addShaderToCamera(cam:String,effect:Dynamic){//STOLE FROM ANDROMEDA	// actually i got it from old psych engine



		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud':
					camHUDShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camHUDShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camHUD.filters = newCamEffects;
			case 'camother' | 'other':
					camOtherShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camOtherShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.filters = newCamEffects;
			case 'camgame' | 'game':
					camGameShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camGameShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGame.filters = newCamEffects;
			default:
				if(modchartSprites.exists(cam)) {
					Reflect.setProperty(modchartSprites.get(cam),"shader",effect.shader);
				} else if(modchartTexts.exists(cam)) {
					Reflect.setProperty(modchartTexts.get(cam),"shader",effect.shader);
				} else {
					var OBJ = Reflect.getProperty(PlayState.instance,cam);
					Reflect.setProperty(OBJ,"shader", effect.shader);
				}




		}




  }

  public function removeShaderFromCamera(cam:String,effect:ShaderEffect){


		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud':
	camHUDShaders.remove(effect);
	var newCamEffects:Array<BitmapFilter>=[];
	for(i in camHUDShaders){
	  newCamEffects.push(new ShaderFilter(i.shader));
	}
	camHUD.filters = newCamEffects;
			case 'camother' | 'other':
					camOtherShaders.remove(effect);
					var newCamEffects:Array<BitmapFilter>=[];
					for(i in camOtherShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.filters = newCamEffects;
			default:
				if(modchartSprites.exists(cam)) {
					Reflect.setProperty(modchartSprites.get(cam),"shader",null);
				} else if(modchartTexts.exists(cam)) {
					Reflect.setProperty(modchartTexts.get(cam),"shader",null);
				} else {
					var OBJ = Reflect.getProperty(PlayState.instance,cam);
					Reflect.setProperty(OBJ,"shader", null);
				}

		}


  }



  public function clearShaderFromCamera(cam:String){


		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud':
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camHUD.filters = newCamEffects;
			case 'camother' | 'other':
				camOtherShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camOther.filters = newCamEffects;
			case 'camgame' | 'game':
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camGame.filters = newCamEffects;
			default:
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camGame.filters = newCamEffects;
		}


  }

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String, ?callback:Void->Void = null)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			if (callback != null)
				callback();
			else
						startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		#if (hxCodec < "3.0.0")
		video.playVideo(filepath);
		if (callback != null)
			video.finishCallback = callback;
		else{
			video.finishCallback = function()
				{
					startAndEnd();
					if (heyStopTrying) openfl.system.System.exit(0);
					return;
				}
		}
		#else
		video.play(filepath);
		if (callback != null)
			video.onEndReached.add(callback);
		else{
			video.onEndReached.add(function(){
					video.dispose();
					startAndEnd();
					if (heyStopTrying) openfl.system.System.exit(0);
					return;
				});
		}
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		if (callback != null)
			callback();
		else
				startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	public function changeTheSettingsBitch() {
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		hpDrainLevel = ClientPrefs.getGameplaySetting('drainlevel', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		sickOnly = ClientPrefs.getGameplaySetting('onlySicks', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		opponentChart = ClientPrefs.getGameplaySetting('opponentplay', false);
		trollingMode = ClientPrefs.getGameplaySetting('thetrollingever', false);
		opponentDrain = ClientPrefs.getGameplaySetting('opponentdrain', false);
		randomMode = ClientPrefs.getGameplaySetting('randommode', false);
		flip = ClientPrefs.getGameplaySetting('flip', false);
		stairs = ClientPrefs.getGameplaySetting('stairmode', false);
		waves = ClientPrefs.getGameplaySetting('wavemode', false);
		oneK = ClientPrefs.getGameplaySetting('onekey', false);
		randomSpeedThing = ClientPrefs.getGameplaySetting('randomspeed', false);
		jackingtime = ClientPrefs.getGameplaySetting('jacks', 0);
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		shouldDrainHealth = (opponentDrain || (opponentChart ? boyfriend.healthDrain : dad.healthDrain));
		if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainAmount)) healthDrainAmount = opponentChart ? boyfriend.drainAmount : dad.drainAmount;
		if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainFloor)) healthDrainFloor = opponentChart ? boyfriend.drainFloor : dad.drainFloor;
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function camPanRoutine(anim:String = 'singUP', who:String = 'bf'):Void {
		if (SONG.notes[curSection] != null)
		{
		var fps:Float = FlxG.updateFramerate;
		final bfCanPan:Bool = SONG.notes[curSection].mustHitSection;
		final dadCanPan:Bool = !SONG.notes[curSection].mustHitSection;
		var clear:Bool = false;
		switch (who) {
			case 'bf': clear = bfCanPan;
			case 'oppt': clear = dadCanPan;
		}
		//FlxG.elapsed is stinky poo poo for this, it just makes it look jank as fuck
		if (clear) {
			if (fps == 0) fps = 1;
			switch (anim.split('-')[0])
			{
				case 'singUP': moveCamTo[1] = -40*ClientPrefs.panIntensity*240*playbackRate/fps;
				case 'singDOWN': moveCamTo[1] = 40*ClientPrefs.panIntensity*240*playbackRate/fps;
				case 'singLEFT': moveCamTo[0] = -40*ClientPrefs.panIntensity*240*playbackRate/fps;
				case 'singRIGHT': moveCamTo[0] = 40*ClientPrefs.panIntensity*240*playbackRate/fps;
			}
		}
		}
	}


	function tankIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true);
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch(songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('killYou'));
				});

			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('tankSong2', 'sound');

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!ClientPrefs.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!ClientPrefs.lowQuality)
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
					if (calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if(name == 'dieBitch') //Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if(name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function()
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function()
				{
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage) introAlts = introAssets.get('pixel');

		for (asset in introAlts)
			Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);

	}

	private function updateCompactNumbers():Void
	{
		compactUpdateFrame++;
			compactCombo = formatCompactNumber(combo);
			compactMaxCombo = formatCompactNumber(maxCombo);
		compactScore = formatCompactNumber(songScore);
		compactMisses = formatCompactNumber(songMisses);
		compactNPS = formatCompactNumber(nps);
		compactTotalPlays = formatCompactNumber(totalNotesPlayed);
	}

	public static function formatCompactNumber(number:Float):String
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

	public static function formatCompactNumberInt(number:Int):String //this entire function is ai generated LMAO
	{
		var suffixes:Array<String> = ['', 'thousand', 'million', 'billion']; //Illions up to billion, nothing higher because integers can't go past 2,147,483,647
		var magnitude:Int = 0;
		var num:Float = number;

		while (num >= 1000.0 && magnitude < suffixes.length - 1)
		{
			num /= 1000.0;
			magnitude++;
		}

		var compactValue:Float = Math.floor(num * 100) / 100;
	if (compactValue <= 0.001) {
		return "0"; //Return 0 if compactValue = null
	} else {
			return compactValue + (magnitude == 0 ? "" : " ") + suffixes[magnitude];
	}
	}

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);

		if (ClientPrefs.coolGameplay)
		{
			hueh231 = new FlxSprite();
			hueh231.frames = Paths.getSparrowAtlas('dokistuff/coolgameplay');
			hueh231.animation.addByPrefix('idle', 'Symbol', 24, true);
			hueh231.animation.play('idle');
			hueh231.antialiasing = ClientPrefs.globalAntialiasing;
			hueh231.scrollFactor.set();
			hueh231.setGraphicSize(Std.int(hueh231.width / FlxG.camera.zoom));
			hueh231.updateHitbox();
			hueh231.screenCenter();
			hueh231.cameras = [camGame];
			add(hueh231);
		}
		if (SONG.song.toLowerCase() == 'anti-cheat-song')
		{
			secretsong = new FlxSprite().loadGraphic(Paths.image('secretSong'));
			secretsong.antialiasing = ClientPrefs.globalAntialiasing;
			secretsong.scrollFactor.set();
			secretsong.setGraphicSize(Std.int(secretsong.width / FlxG.camera.zoom));
			secretsong.updateHitbox();
			secretsong.screenCenter();
			secretsong.cameras = [camGame];
			add(secretsong);
		}
		if (ClientPrefs.middleScroll || ClientPrefs.mobileMidScroll)
		{
			laneunderlayOpponent.alpha = 0;
			laneunderlay.screenCenter(X);
		}

		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (ClientPrefs.charsAndBG) {
					if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
					{
						gf.dance();
					}
					if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
					{
						boyfriend.dance();
					}
					if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					{
						dad.dance();
					}
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						if (ClientPrefs.tauntOnGo && ClientPrefs.charsAndBG)
						{
							final charsToHey = [dad, boyfriend, gf];
							for (char in charsToHey)
							{
								if(char != null)
								{
									if (char.animOffsets.exists('hey') || char.animOffsets.exists('cheer'))
									{
										char.playAnim(char.animOffsets.exists('hey') ? 'hey' : 'cheer', true);
										char.specialAnim = true;
										char.heyTimer = 0.6;
									} else if (char.animOffsets.exists('singUP') && (!char.animOffsets.exists('hey') || !char.animOffsets.exists('cheer')))
									{
										char.playAnim('singUP', true);
										char.specialAnim = true;
										char.heyTimer = 0.6;
									}
								}
							}
						}
					case 4:
					if (SONG.songCredit != null && SONG.songCredit.length > 0)
					{
						var creditsPopup:CreditsPopUp = new CreditsPopUp(FlxG.width, 200, SONG.song, SONG.songCredit);
						creditsPopup.cameras = [camHUD];
						creditsPopup.scrollFactor.set();
						creditsPopup.x = creditsPopup.width * -1;
						add(creditsPopup);

						FlxTween.tween(creditsPopup, {x: 0}, 0.5, {ease: FlxEase.backOut, onComplete: function(tweeen:FlxTween)
						{
							FlxTween.tween(creditsPopup, {x: creditsPopup.width * -1} , 1, {ease: FlxEase.backIn, onComplete: function(tween:FlxTween)
							{
								creditsPopup.destroy();
							}, startDelay: 3});
						}});
					}
				}

				for (group in [notes, sustainNotes]) group.forEachAlive(function(note:Note) {
					if(ClientPrefs.opponentStrums || !ClientPrefs.opponentStrums && ClientPrefs.mobileMidScroll || ClientPrefs.middleScroll || !note.mustPress)
					{
							note.alpha *= 0.35;
					}
					if(ClientPrefs.opponentStrums || !ClientPrefs.opponentStrums && ClientPrefs.mobileMidScroll || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
						if(ClientPrefs.mobileMidScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(notes), spr);
		FlxTween.tween(spr, {"scale.x": 0, "scale.y": 0, alpha: 0}, Conductor.crochet / 1000 / playbackRate, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				notes.remove(daNote, true);
			}
			--i;
		}

		i = sustainNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = sustainNotes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				sustainNotes.remove(daNote, true);
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		scoreTxtUpdateFrame++;
		if (!scoreTxt.visible) return;
		//GAH DAYUM THIS IS MORE OPTIMIZED THAN BEFORE
		formattedMaxScore = ClientPrefs.showMaxScore ? ' / ' + FlxStringUtil.formatMoney(maxScore, false) : '';
		formattedSongScore = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(songScore, false) : compactScore;
		formattedScore = (!ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(songScore, false) : compactScore) + formattedMaxScore;
		formattedSongMisses = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(songMisses, false) : compactMisses;
		formattedCombo = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(combo, false) : compactCombo;
		formattedNPS = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(nps, false) : compactNPS;
		formattedMaxNPS = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(maxNPS, false) : formatCompactNumber(maxNPS);
		npsString = ClientPrefs.showNPS ? (ClientPrefs.hudType != 'Leather Engine' ? ' | ' : ' ~ ') + (cpuControlled && !ClientPrefs.communityGameBot ? 'Bot ' : '') + 'NPS/Max: ' + formattedNPS + '/' + formattedMaxNPS : '';
		accuracy = Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
		fcString = ratingFC;

		botText = cpuControlled && !ClientPrefs.communityGameBot ? ' | Botplay Mode' : '';

		if (cpuControlled && !ClientPrefs.communityGameBot)
		{
			tempScore = 'Bot Score: ' + formattedScore + ' | Bot Combo: ' + formattedCombo + npsString + botText;
			if (ClientPrefs.healthDisplay) scoreTxt.text += ' | Health: ' + FlxMath.roundDecimal(health * 50, 2) + '%';
		}
		else switch (ClientPrefs.hudType)
			{
				case 'Kade Engine':
					tempScore = 'Score: ' + formattedScore + ' | Misses: ' + formattedSongMisses  + ' | Combo: ' + formattedCombo + npsString + ' | Accuracy: ' + accuracy + ' | (' + fcString + ') ' + ratingCool;

				case "Doki Doki+":
					tempScore = 'Score: ' + formattedScore + ' | Breaks: ' + formattedSongMisses + ' | Combo: ' + formattedCombo + npsString + ' | Accuracy: ' + accuracy + ' | (' + fcString + ') ' + ratingCool;

				case "Dave and Bambi":
					tempScore = 'Score: ' + formattedScore + ' | Misses: ' + formattedSongMisses + ' | Combo: ' + formattedCombo + npsString + ' | Accuracy: ' + accuracy + ' | ' + fcString;

				case "Psych Engine", "JS Engine", "Tails Gets Trolled V4":
					tempScore = 'Score: ' + formattedScore + ' | Misses: ' + formattedSongMisses  + ' | Combo: ' + formattedCombo + npsString + ' | Rating: ' + ratingName + (ratingName != '?' ? ' (${accuracy}) - $fcString' : '');

				case "Leather Engine":
					tempScore = '< Score: ' + formattedScore + ' ~ Misses: ' + formattedSongMisses + ' ~ Combo: ' + formattedCombo + npsString + ' ~ Rating: ' + ratingName + (ratingName != '?' ? ' (${accuracy}) - $fcString' : '');

				case 'VS Impostor':
					tempScore = 'Score: ' + formattedScore + ' | Combo Breaks: ' + formattedSongMisses  + ' | Combo: ' + formattedCombo + npsString + ' | Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '% ['  + fcString + ']';
			}
			if (ClientPrefs.healthDisplay && !cpuControlled) tempScore += ' | Health: ' + FlxMath.roundDecimal(health * 50, 2) + '%';

			scoreTxt.text = '${tempScore}\n';

			callOnLuas('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		if (ClientPrefs.songLoading)
		{
			FlxG.sound.music.pause();
			vocals.pause();

			FlxG.sound.music.time = time;
			FlxG.sound.music.pitch = playbackRate;
			FlxG.sound.music.play();
			if (ffmpegMode) FlxG.sound.music.volume = 0;

			if (Conductor.songPosition <= vocals.length)
			{
				vocals.time = time;
				vocals.pitch = playbackRate;
			}
			vocals.play();
			if (ffmpegMode) vocals.volume = 0;
		}
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;
		if (ClientPrefs.songLoading)
		{
			@:privateAccess
			if (!ffmpegMode) {
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
				FlxG.sound.music.onComplete = finishSong.bind();
			} else {
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0, false);
				vocals.volume = 0;
			}
			if (!ffmpegMode && !trollingMode && SONG.song.toLowerCase() != 'anti-cheat-song' && SONG.song.toLowerCase() != 'desert bus')
				FlxG.sound.music.onComplete = finishSong.bind();
			vocals.play();
		}

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			if (ClientPrefs.songLoading)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}
		}
		curTime = Conductor.songPosition - ClientPrefs.noteOffset;
		songPercent = (curTime / songLength);


		// Song duration in a float, useful for the time left feature
		if (ClientPrefs.lengthIntro && ClientPrefs.songLoading) FlxTween.tween(this, {songLength: FlxG.sound.music.length}, 1, {ease: FlxEase.expoOut});
		if (!ClientPrefs.lengthIntro && ClientPrefs.songLoading) songLength = FlxG.sound.music.length; //so that the timer won't just appear as 0
		if (ClientPrefs.timeBarType != 'Disabled') {
		timeBar.scale.x = 0.01;
		timeBarBG.scale.x = 0.01;
		FlxTween.tween(timeBar, {alpha: 1, "scale.x": 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(timeBarBG, {alpha: 1, "scale.x": 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}

		if (!disableCoolHealthTween && !ClientPrefs.hideHud && !ClientPrefs.showcaseMode)
		{
			var renderedTxtY = -70;
			if (ClientPrefs.downScroll) renderedTxtY = 70;
			if (ClientPrefs.hudType == 'VS Impostor') renderedTxtY = (ClientPrefs.downScroll ? 70 : -100);
			var scoreTxtY = 50;
			switch (ClientPrefs.hudType)
			{
				case 'Dave and Bambi': scoreTxtY = 40;
				case 'Psych Engine', 'VS Impostor': scoreTxtY = 36;
				case 'Tails Gets Trolled V4', 'Doki Doki+': scoreTxtY = 48;
			}
			var healthBarElements:Array<Dynamic> = [healthBarBG, healthBar, scoreTxt, iconP1, iconP2, renderedTxt, botplayTxt];
			var yTweens:Array<Dynamic> = [0, 4, scoreTxtY, -75, -75, renderedTxtY];
			if (ClientPrefs.hudType == 'VS Impostor')
			{
				if (ClientPrefs.downScroll) healthBarElements = [healthBarBG, healthBar, scoreTxt, iconP1, iconP2, renderedTxt];
				yTweens = [0, 4, scoreTxtY, -75, -75, renderedTxtY, -55];	
			}
			for (i in 0...healthBarElements.length)
				if (healthBarElements[i] != null && i < yTweens.length) FlxTween.tween(healthBarElements[i], {y: (FlxG.height * (ClientPrefs.downScroll ? 0.11 : 0.89)) + yTweens[i]}, 1, {ease: FlxEase.expoOut});
		}

		switch(curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
		}

		#if DISCORD_ALLOWED
		if (cpuControlled) detailsText = detailsText + ' (using a bot)';
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}
	public function lerpSongSpeed(num:Float, time:Float):Void
	{
		FlxTween.num(playbackRate, num, time, {onUpdate: function(tween:FlxTween){
			var ting = FlxMath.lerp(playbackRate, num, tween.percent);
			if (ting != 0) //divide by 0 is a verry bad
				playbackRate = ting; //why cant i just tween a variable

			if (ClientPrefs.songLoading) FlxG.sound.music.time = Conductor.songPosition;
			if (ClientPrefs.songLoading && !ClientPrefs.noSyncing && !ffmpegMode) resyncVocals();
		}});
	}

	var debugNum:Int = 0;
	var stair:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String, ?startingPoint:Float = 0):Void
	{
	   		final startTime = Sys.time();

		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		Conductor.changeBPM(SONG.bpm);

		curSong = SONG.song;

		if (SONG.windowName != null && SONG.windowName != '')
			MusicBeatState.windowNamePrefix = SONG.windowName;

		if (SONG.needsVoices && ClientPrefs.songLoading)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		if (ClientPrefs.songLoading) vocals.pitch = playbackRate;
		if (ClientPrefs.songLoading) FlxG.sound.list.add(vocals);
		if (ClientPrefs.songLoading) FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		final noteData:Array<SwagSection> = SONG.notes;

		final songName:String = Paths.formatToSongPath(SONG.song);
		final file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					if (event[0] >= startingPoint - 350)
					{
						var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
						var subEvent:EventNote = {
							strumTime: newEventNote[0] + ClientPrefs.noteOffset,
							event: newEventNote[1],
							value1: newEventNote[2],
							value2: newEventNote[3]
						};
						eventNotes.push(subEvent);
						eventPushed(subEvent);
					}
				}
			}
		}
		for (event in SONG.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				if (event[0] >= startingPoint - 350)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}
		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				if (usingEkFile && (songNotes[1] > 3) && !isEkSong) {
					trace("one of the notes' note data exceeded the normal note count and there's a lua ek file, so im assuming this song is an ek song");
					isEkSong = true;
				}
				if (songNotes[0] >= startingPoint - 350) {
					final daStrumTime:Float = songNotes[0];
					var daNoteData:Int = 0;
					if (!randomMode && !flip && !stairs && !waves) {
						daNoteData = Std.int(songNotes[1] % 4);
					}
					if (oneK) {
						daNoteData = 2;
					}
					if (randomMode) {
						daNoteData = FlxG.random.int(0, 3);
					}
					if (flip) {
						daNoteData = Std.int(Math.abs((songNotes[1] % 4) - 3));
					}
					if (stairs && !waves) {
						daNoteData = stair % 4;
						stair++;
					}
					if (waves) {
						switch (stair % 6) {
							case 0 | 1 | 2 | 3:
								daNoteData = stair % 6;
							case 4:
								daNoteData = 2;
							case 5:
								daNoteData = 1;
						}
						stair++;
					}
					final gottaHitNote:Bool = ((songNotes[1] < 4 && !opponentChart && !bothsides)
						|| (songNotes[1] > 3 && opponentChart) ? section.mustHitSection : !section.mustHitSection);

					if (gottaHitNote && !songNotes.hitCausesMiss) {
						totalNotes += 1;
					}
					if (!gottaHitNote) {
						opponentNoteTotal += 1;
					}

					if (daStrumTime >= charChangeTimes[0])
					{
						switch (charChangeTypes[0])
						{
							case 0:
								var boyfriendToGrab:Boyfriend = boyfriendMap.get(charChangeNames[0]);
								if (boyfriendToGrab != null) bfNoteskin = boyfriendToGrab.noteskin;
							case 1:
								var dadToGrab:Character = dadMap.get(charChangeNames[0]);
								if (dadToGrab != null) dadNoteskin = dadToGrab.noteskin;
						}
						charChangeTimes.shift();
						charChangeNames.shift();
						charChangeTypes.shift();
					}
		
					var oldNote:PreloadedChartNote = unspawnNotes[unspawnNotes.length - 1];
		
					final swagNote:PreloadedChartNote = cast {
						strumTime: daStrumTime,
						noteData: daNoteData,
						mustPress: gottaHitNote,
						noteType: songNotes[3],
						noteskin: (gottaHitNote ? bfNoteskin : dadNoteskin),
						gfNote: songNotes[3] == 'GF Sing' || (section.gfSection && songNotes[1] < 4),
						isSustainNote: false,
						isSustainEnd: false,
						sustainLength: songNotes[2],
						parent: null,
						prevNote: oldNote,
						strum: null
					};
		
					if (!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}
		
					unspawnNotes.push(swagNote);
		
					final floorSus:Int = Math.floor(swagNote.sustainLength / Conductor.stepCrochet);
					if (floorSus > 0) {
						for (susNote in 0...floorSus + 1) {
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
		
							final sustainNote:PreloadedChartNote = cast {
								strumTime: daStrumTime + (Conductor.stepCrochet * susNote),
								noteData: daNoteData,
								mustPress: gottaHitNote,
								noteType: songNotes[3],
								noteskin: (gottaHitNote ? bfNoteskin : dadNoteskin),
								gfNote: songNotes[3] == 'GF Sing' || (section.gfSection && songNotes[1] < 4),
								isSustainNote: true,
								isSustainEnd: susNote == floorSus, //idk
								sustainLength: 0,
								parent: swagNote,
								prevNote: oldNote,
								strum: null
							};
							unspawnNotes.push(sustainNote);
							Sys.sleep(0.0001);
						}
					}
		
					if (jackingtime > 0) {
						for (i in 0...Std.int(jackingtime)) {
							final jackNote:PreloadedChartNote = cast {
								strumTime: swagNote.strumTime + (15000 / SONG.bpm) * (i + 1),
								noteData: swagNote.noteData,
								mustPress: swagNote.mustPress,
								noteType: swagNote.noteType,
								noteskin: (gottaHitNote ? bfNoteskin : dadNoteskin),
								gfNote: swagNote.gfNote,
								isSustainNote: false,
								isSustainEnd: false,
								sustainLength: swagNote.sustainLength,
								parent: null,
								prevNote: oldNote,
								strum: null
							};
							unspawnNotes.push(jackNote);
							Sys.sleep(0.0001);
						}
					}
				} else {
					final gottaHitNote:Bool = ((songNotes[1] < 4 && !opponentChart && !bothsides)
						|| (songNotes[1] > 3 && opponentChart && !bothsides) ? section.mustHitSection : !section.mustHitSection);
					if (gottaHitNote && !songNotes.hitCausesMiss) {
						totalNotes += 1;
						combo += 1;
						totalNotesPlayed += 1;
					}
					if (!gottaHitNote) {
						opponentNoteTotal += 1;
						enemyHits += 1;
					}
				}
			}
		}

		bfNoteskin = boyfriend.noteskin;
		dadNoteskin = dad.noteskin;

		if (ClientPrefs.noteColorStyle == 'Char-Based')
		{
			for (note in notes){
				if (note == null)
					continue;
				note.updateRGBColors();
			}
			for (note in sustainNotes){
				if (note == null)
					continue;
				note.updateRGBColors();
			}
		}

		unspawnNotes.sort(sortByTime);
		eventNotes.sort(sortByTime);
		unspawnNotesCopy = unspawnNotes.copy();
		eventNotesCopy = eventNotes.copy();
		generatedMusic = true;

		openfl.system.System.gc();

		trace('Done!');
	}
	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
			if (ClientPrefs.charsAndBG)
			{
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

				charChangeTimes.push(event.strumTime);
				charChangeNames.push(event.value2);
				charChangeTypes.push(charType);
			}

			case 'Dadbattle Spotlight':
				if (curStage != 'stage') return;

				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);


			case 'Philly Glow':
				if (curStage != 'philly') return;

				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);


				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('philly/particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnLuas('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.middleScroll) targetAlpha = ClientPrefs.oppNoteAlpha;
			}

			var noteSkinExists:Bool = FileSystem.exists("assets/shared/images/noteskins/" + (player == 0 ? dadNoteskin : bfNoteskin)) || FileSystem.exists(Paths.modsImages("noteskins/" + (player == 0 ? dadNoteskin : bfNoteskin)));

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll || ClientPrefs.mobileMidScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (noteSkinExists) babyArrow.texture = "noteskins/" + (player == 0 ? dad.noteskin : boyfriend.noteskin);
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				if (!opponentChart || opponentChart && ClientPrefs.middleScroll || opponentChart && ClientPrefs.mobileMidScroll || !opponentChart && ClientPrefs.mobileMidScroll) playerStrums.add(babyArrow);
			else if (ClientPrefs.mobileMidScroll) insert(members.indexOf(playerStrums), babyArrow);
			else opponentStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				if (!opponentChart || opponentChart && ClientPrefs.mobileMidScroll || opponentChart && ClientPrefs.mobileMidScroll || !opponentChart && ClientPrefs.mobileMidScroll) opponentStrums.add(babyArrow);
			else if (ClientPrefs.mobileMidScroll) insert(members.indexOf(playerStrums), babyArrow);
				else playerStrums.add(babyArrow);
			}

			for (swagNote in unspawnNotes)
				if (swagNote.noteData == i) swagNote.strum = (swagNote.mustPress ? playerStrums : opponentStrums).members[swagNote.noteData];


			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				if (ClientPrefs.songLoading) {
				FlxG.sound.music.pause();
				vocals.pause();
				}
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong && !ClientPrefs.noSyncing && !ffmpegMode)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if DISCORD_ALLOWED
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		FlxG.sound.music.pitch = playbackRate;
		vocals.pitch = playbackRate;
		if (ClientPrefs.resyncType == 'Leather')
		{
			if(!(Conductor.songPosition > 20 && FlxG.sound.music.time < 20))
			{
				//trace("SONG POS: " + Conductor.songPosition + " | Musice: " + FlxG.sound.music.time + " / " + FlxG.sound.music.length);

				vocals.pause();
				FlxG.sound.music.pause();

				if(FlxG.sound.music.time >= FlxG.sound.music.length)
					Conductor.songPosition = FlxG.sound.music.length;
				else
					Conductor.songPosition = FlxG.sound.music.time;

				vocals.time = Conductor.songPosition;

				FlxG.sound.music.play();
				vocals.play();
			}
			else
			{
				while(Conductor.songPosition > 20 && FlxG.sound.music.time < 20)
				{

					FlxG.sound.music.time = Conductor.songPosition;
					vocals.time = Conductor.songPosition;

					FlxG.sound.music.play();
					vocals.play();
				}
			}
		}
		else if (ClientPrefs.resyncType == 'Psych')
		{
		vocals.pause();
		FlxG.sound.music.play();

		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
		}
		vocals.play();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;
	var pbRM:Float = 2.0;

	public var preElapsed:Float = 0;
	public var postElapsed:Float = 1 / ClientPrefs.targetFPS;
	public var takenTime:Float = haxe.Timer.stamp();

	var trollModeSongLengthTotal:Float = 0;
	var readyToTriggerTrollMode:Bool = false;

	override public function update(elapsed:Float)
	{
		if (ClientPrefs.ffmpegMode) elapsed = 1 / ClientPrefs.targetFPS;
		if (screenshader.Enabled)
		{
			if(disableTheTripperAt == curStep)
			{
				disableTheTripper = true;
			}
			if(isDead)
			{
				disableTheTripper = true;
			}

			FlxG.camera.filters = [new ShaderFilter(screenshader.shader)];
			screenshader.update(elapsed);
			if(disableTheTripper)
			{
				screenshader.shader.uampmul.value[0] -= (elapsed / 2);
			}
		}
		if (FlxG.sound.music.length - Conductor.songPosition <= 1000 && ClientPrefs.communityGameBot && cpuControlled) {
		ratingName = 'you used the community game bot option LMFAOOO';
		ratingFC = 'skill issue';
		}
		if (ClientPrefs.comboScoreEffect && ClientPrefs.comboMultiType == 'osu!') comboMultiplier = 1 + FlxMath.roundDecimal((combo / 100), 2);
		if (ClientPrefs.comboScoreEffect && comboMultiplier > ClientPrefs.comboMultLimit) comboMultiplier = ClientPrefs.comboMultLimit;
		if (ClientPrefs.pbRControls)
		{
			if (FlxG.keys.pressed.SHIFT) {
				if (pbRM != 4.0) pbRM = 4.0;
			} else {
				if (pbRM != 2.0) pbRM = 2.0;
			}
	   			if (FlxG.keys.justPressed.SLASH) {
						playbackRate /= pbRM;
	   			}
				if (FlxG.keys.justPressed.PERIOD) {
		   			playbackRate *= pbRM;
	   			}
		}
		if (ClientPrefs.showcaseMode && !ClientPrefs.showNotes)
		{
			botplayTxt.text = 'NPS: ${FlxStringUtil.formatMoney(nps, false)}/${FlxStringUtil.formatMoney(maxNPS, false)}\nOpp NPS: ${FlxStringUtil.formatMoney(oppNPS, false)}/${FlxStringUtil.formatMoney(maxOppNPS, false)}';
		}

			if (ClientPrefs.showRendered)
			renderedTxt.text = 'Rendered Notes: ' + FlxStringUtil.formatMoney(notes.length, false);

		callOnLuas('onUpdate', [elapsed]);

		if (sickOnly && (goods > 0 || bads > 0 || shits > 0 || songMisses > 0))
		{
			health = -2;
		}

		if (tankmanAscend && curStep > 895 && curStep < 1151)
		{
			camGame.zoom = 0.8;
		}
		if (healthBar.percent >= 80 && !winning)
		{
			winning = true;
			reloadHealthBarColors(dad.losingColorArray, boyfriend.winningColorArray);
		}
		if (healthBar.percent <= 20 && !losing)
		{
			losing = true;
			reloadHealthBarColors(dad.winningColorArray, boyfriend.losingColorArray);
		}
		if (healthBar.percent >= 20 && losing || healthBar.percent <= 80 && winning)
		{
			losing = false;
			winning = false;
			reloadHealthBarColors(dad.healthColorArray, boyfriend.healthColorArray);
		}

		var NOTE_SPAWN_TIME = (ClientPrefs.dynamicSpawnTime ? 2000 / songSpeed : (1600 / songSpeed) / camHUD.zoom /* Just enough for the notes to barely inch off the screen */);

		if (ClientPrefs.charsAndBG && curStage != 'stage') switch (curStage)
		{
			case 'tank':
				moveTank(elapsed);
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if(phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length-1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if(particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if(!inCutscene && ClientPrefs.charsAndBG) {
			final lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x + moveCamTo[0]/102, camFollow.x + moveCamTo[0]/102, lerpVal), FlxMath.lerp(camFollowPos.y + moveCamTo[1]/102, camFollow.y + moveCamTo[1]/102, lerpVal));
			if (ClientPrefs.charsAndBG) {
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
			}
			final panLerpVal:Float = CoolUtil.clamp(elapsed * 4.4 * cameraSpeed, 0, 1);
			moveCamTo[0] = FlxMath.lerp(moveCamTo[0], 0, panLerpVal);
			moveCamTo[1] = FlxMath.lerp(moveCamTo[1], 0, panLerpVal);
		}
if (ClientPrefs.showNPS && (notesHitDateArray.length > 0 || oppNotesHitDateArray.length > 0) && FlxG.game.ticks % (Std.int(ClientPrefs.framerate / 60) > 0 ? Std.int(ClientPrefs.framerate / 60) : 1) == 0) {

	// Track the count of items to remove for notesHitDateArray
	notesToRemoveCount = 0;

	// Filter notesHitDateArray and notesHitArray in place
	for (i in 0...notesHitDateArray.length) {
		if (!Math.isNaN(notesHitDateArray[i]) && (notesHitDateArray[i] + (ClientPrefs.npsWithSpeed ? 1000 / playbackRate : 1000) * npsSpeedMult * npsSpeedMult < Conductor.songPosition)) {
			notesToRemoveCount++;
		}
	}

	// Remove items from notesHitDateArray and notesHitArray if needed
	if (notesToRemoveCount > 0) {
		notesHitDateArray.splice(0, notesToRemoveCount);
		notesHitArray.splice(0, notesToRemoveCount);
		if (ClientPrefs.ratingCounter && judgeCountUpdateFrame <= 4 && judgementCounter != null) updateRatingCounter();
		if (!ClientPrefs.hideScore && scoreTxtUpdateFrame <= 4 && scoreTxt != null) updateScore();
		   	if (ClientPrefs.compactNumbers && compactUpdateFrame <= 4) updateCompactNumbers();
	}

	nps = 0;
	for (value in notesHitArray) {
		nps += value;
	}

	// Similar tracking and filtering logic for oppNotesHitDateArray
	oppNotesToRemoveCount = 0;

	for (i in 0...oppNotesHitDateArray.length) {
		if (!Math.isNaN(notesHitDateArray[i]) && (oppNotesHitDateArray[i] + (ClientPrefs.npsWithSpeed ? 1000 / playbackRate : 1000) * npsSpeedMult * npsSpeedMult < Conductor.songPosition)) {
			oppNotesToRemoveCount++;
		}
	}

	// Remove items from oppNotesHitDateArray and oppNotesHitArray if needed
	if (oppNotesToRemoveCount > 0) {
		oppNotesHitDateArray.splice(0, oppNotesToRemoveCount);
		oppNotesHitArray.splice(0, oppNotesToRemoveCount);
		if (ClientPrefs.ratingCounter && judgeCountUpdateFrame <= 4 && judgementCounter != null) updateRatingCounter();
		   	if (ClientPrefs.compactNumbers && compactUpdateFrame <= 4) updateCompactNumbers();
	}

	// Calculate sum of NPS values for the opponent
	oppNPS = 0;
	for (value in oppNotesHitArray) {
		oppNPS += value;
	}

	// Update maxNPS and maxOppNPS if needed
	if (oppNPS > maxOppNPS) {
		maxOppNPS = oppNPS;
	}
	if (nps > maxNPS) {
		maxNPS = nps;
	}
	if (nps > oldNPS)
		npsIncreased = true;

	if (nps < oldNPS)
		npsDecreased = true;

	if (oppNPS > oldOppNPS)
		oppNpsIncreased = true;

	if (oppNPS < oldOppNPS)
		oppNpsDecreased = true;

	if (npsIncreased || npsDecreased || oppNpsIncreased || oppNpsDecreased) {
		if (ClientPrefs.ratingCounter && judgeCountUpdateFrame <= 8 && judgementCounter != null) updateRatingCounter();
		if (!ClientPrefs.hideScore && scoreTxtUpdateFrame <= 8 && scoreTxt != null) updateScore();
		   	if (ClientPrefs.compactNumbers && compactUpdateFrame <= 8) updateCompactNumbers();
		if (npsIncreased) npsIncreased = false;
		if (npsDecreased) npsDecreased = false;
		if (oppNpsIncreased) oppNpsIncreased = false;
		if (oppNpsDecreased) oppNpsDecreased = false;
		oldNPS = nps;
		oldOppNPS = oppNPS;
	}
}

		if (ClientPrefs.showcaseMode && !ClientPrefs.charsAndBG) {
		hitTxt.text = 'Notes Hit: ' + FlxStringUtil.formatMoney(totalNotesPlayed, false) + ' / ' + FlxStringUtil.formatMoney(totalNotes, false)
		+ '\nNPS (Max): ' + FlxStringUtil.formatMoney(nps, false) + ' (' + FlxStringUtil.formatMoney(maxNPS, false) + ')'
		+ '\nOpponent Notes Hit: ' + FlxStringUtil.formatMoney(enemyHits, false)
		+ '\nOpponent NPS (Max): ' + FlxStringUtil.formatMoney(oppNPS, false) + ' (' + FlxStringUtil.formatMoney(maxOppNPS, false) + ')'
		+ '\nTotal Note Hits: ' + FlxStringUtil.formatMoney(Math.abs(totalNotesPlayed + enemyHits), false)
		+ '\nVideo Speedup: ' + Math.abs(playbackRate / playbackRate / playbackRate) + 'x';
		}

		super.update(elapsed);
		if (judgeCountUpdateFrame > 0) judgeCountUpdateFrame = 0;
		if (compactUpdateFrame > 0) compactUpdateFrame = 0;
		if (scoreTxtUpdateFrame > 0) scoreTxtUpdateFrame = 0;
		if (iconBopsThisFrame > 0) iconBopsThisFrame = 0;
		if (popUpsFrame > 0) popUpsFrame = 0;
		if (missRecalcsPerFrame > 0) missRecalcsPerFrame = 0;
		if (charAnimsFrame > 0) charAnimsFrame = 0;
		if (oppAnimsFrame > 0) oppAnimsFrame = 0;
		if (strumAnimsPerFrame[0] > 0 || strumAnimsPerFrame[1] > 0) strumAnimsPerFrame = [0, 0];

		if (lerpingScore) updateScore();
		if (shownScore != songScore && ClientPrefs.hudType == 'JS Engine' && Math.abs(shownScore - songScore) >= 10) {
			shownScore = FlxMath.lerp(shownScore, songScore, 0.4 / (ClientPrefs.framerate / 60));
				lerpingScore = true; // Indicate that lerping is in progress
		} else {
			shownScore = songScore;
			lerpingScore = false;
		}

		// Peak code
		if (ClientPrefs.smoothHPBug) displayedHealth = ClientPrefs.smoothHealth ? FlxMath.lerp(displayedHealth, health, 0.078) : health;
		health = FlxMath.bound(health, 0, 2.0015 /* Fix for smooth health bar when it's full */);
		if (!ClientPrefs.smoothHPBug) displayedHealth = ClientPrefs.smoothHealth ? FlxMath.lerp(displayedHealth, health, 0.078) : health;
		
		health = FlxMath.bound(health, 0, 2.0015 /* Fix for smooth health bar when it's full */);

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible && ClientPrefs.hudType != 'Kade Engine' && ClientPrefs.botTxtFade) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180 * playbackRate);
		}
		if((botplayTxt != null && cpuControlled && !ClientPrefs.showcaseMode) && ClientPrefs.randomBotplayText && !ClientPrefs.communityGameBot) {
			if(botplayTxt.text == "this text is gonna kick you out of botplay in 10 seconds" && !botplayUsed || botplayTxt.text == "Your Botplay Free Trial will end in 10 seconds." && !botplayUsed)
				{
					botplayUsed = true;
					new FlxTimer().start(10, function(tmr:FlxTimer)
						{
							cpuControlled = false;
							botplayUsed = false;
							botplayTxt.visible = false;
						});
				}
			if(botplayTxt.text == "You use botplay? In 10 seconds I knock your botplay thing and text so you'll never use it >:)" && !botplayUsed)
				{
					botplayUsed = true;
					new FlxTimer().start(10, function(tmr:FlxTimer)
						{
							cpuControlled = false;
							botplayUsed = false;
							FlxG.sound.play(Paths.sound('pipe'), 10);
							botplayTxt.visible = false;
							PauseSubState.botplayLockout = true;
						});
				}
			if(botplayTxt.text == "you have 10 seconds to run." && !botplayUsed)
				{
					botplayUsed = true;
					new FlxTimer().start(10, function(tmr:FlxTimer)
						{
							var vidSpr:FlxSprite;
							var videoDone:Bool = true;
							var video:MP4Handler = new MP4Handler(); // it plays but it doesn't show???
							vidSpr = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
							add(vidSpr);
							#if (hxCodec < "3.0.0")
							video.playVideo(Paths.video('scary'), false, false);
							video.finishCallback = function()
							{
								videoDone = true;
								vidSpr.visible = false;
								Sys.exit(0);
							};
							#else
							video.play(Paths.video('scary'));
							video.onEndReached.add(function(){
								video.dispose();
								videoDone = true;
								vidSpr.visible = false;
								Sys.exit(0);
							});
							#end
						});
				}
			if(botplayTxt.text == "you're about to die in 30 seconds" && !botplayUsed)
				{
					botplayUsed = true;
					new FlxTimer().start(30, function(tmr:FlxTimer)
						{
							health = 0;
						});
				}
			if(botplayTxt.text == "3 minutes until Boyfriend steals your liver." && !botplayUsed)
				{
				var title:String = 'Incoming Alert from Boyfriend';
				var message:String = '3 minutes until Boyfriend steals your liver!';
				FlxG.sound.music.pause();
				vocals.pause();

				lime.app.Application.current.window.alert(message, title);
				FlxG.sound.music.resume();
				vocals.resume();
					botplayUsed = true;
					new FlxTimer().start(180, function(tmr:FlxTimer)
						{
							Sys.exit(0);
						});
				}
			if(botplayTxt.text == "3 minutes until I steal your liver." && !botplayUsed)
				{
				var title:String = 'Incoming Alert from Jordan';
				var message:String = '3 minutes until I steal your liver.';
				FlxG.sound.music.pause();
				vocals.pause();

				lime.app.Application.current.window.alert(message, title);
				FlxG.sound.music.resume();
				vocals.resume();
					botplayUsed = true;
					new FlxTimer().start(180, function(tmr:FlxTimer)
						{
							Sys.exit(0);
						});
				}
		}

		if (controls.PAUSE && startedCountdown && canPause && !heyStopTrying)
		{
			final ret:Dynamic = callOnLuas('onPause', [], false);
			if(ret != FunkinLua.Function_Stop)
				openPauseMenu();
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			if (SONG.event7 != null && SONG.event7 != "---" && SONG.event7 != 'None')
			switch(SONG.event7)
				{
				case "---", null, 'None':
				if (!ClientPrefs.antiCheatEnable)
				{
				openChartEditor();
				}
				else
				{
				PlayState.SONG = Song.loadFromJson('Anti-cheat-song', 'Anti-cheat-song');
				LoadingState.loadAndSwitchState(PlayState.new);
				}
				case "Game Over":
					health = 0;
				case "Go to Song":
						PlayState.SONG = Song.loadFromJson(SONG.event7Value + (CoolUtil.difficultyString() == 'NORMAL' ? '' : '-' + CoolUtil.difficulties[storyDifficulty]), SONG.event7Value);
				LoadingState.loadAndSwitchState(PlayState.new);
				case "Close Game":
					openfl.system.System.exit(0);
				case "Play Video":
					updateTime = false;
					FlxG.sound.music.volume = 0;
					vocals.volume = 0;
					vocals.stop();
					FlxG.sound.music.stop();
					KillNotes();
					heyStopTrying = true;

					var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					add(bg);
					bg.cameras = [camHUD];
					startVideo(SONG.event7Value);
				}
			else if (!ClientPrefs.antiCheatEnable)
				{
					openChartEditor();
				}
				else
				{
					PlayState.SONG = Song.loadFromJson('Anti-cheat-song', 'Anti-cheat-song');
					LoadingState.loadAndSwitchState(PlayState.new);
				}
		}

		if (ClientPrefs.iconBounceType == 'Old Psych') {
		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))));
		}
		if (ClientPrefs.iconBounceType == 'Strident Crisis') {
		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50 / playbackRate)));
		iconP1.updateHitbox();

		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50 / playbackRate)));
		iconP2.updateHitbox();
		}
		if (ClientPrefs.iconBounceType == 'Dave and Bambi') {
		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.8 / playbackRate)),Std.int(FlxMath.lerp(150, iconP1.height, 0.8 / playbackRate)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.8 / playbackRate)),Std.int(FlxMath.lerp(150, iconP2.height, 0.8 / playbackRate)));
		}
		if (ClientPrefs.iconBounceType == 'Plank Engine') {
		final funnyBeat = (Conductor.songPosition / 1000) * (Conductor.bpm / 60);

		iconP1.offset.y = Math.abs(Math.sin(funnyBeat * Math.PI))  * 16 - 4;
		iconP2.offset.y = Math.abs(Math.sin(funnyBeat * Math.PI))  * 16 - 4;
		}
		if (ClientPrefs.iconBounceType == 'New Psych' || ClientPrefs.iconBounceType == 'SB Engine' || ClientPrefs.iconBounceType == 'VS Steve') {
		final mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		final mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
		}

		if (ClientPrefs.iconBounceType == 'Golden Apple') {
		iconP1.centerOffsets();
		iconP2.centerOffsets();
		}
		//you're welcome Stefan2008 :)
		if (ClientPrefs.iconBounceType == 'SB Engine') {
			if (iconP1.angle >= 0) {
				if (iconP1.angle != 0) {
					iconP1.angle -= 1 * playbackRate;
				}
			} else {
				if (iconP1.angle != 0) {
					iconP1.angle += 1 * playbackRate;
				}
			}
			if (iconP2.angle >= 0) {
				if (iconP2.angle != 0) {
					iconP2.angle -= 1 * playbackRate;
				}
			} else {
				if (iconP2.angle != 0) {
					iconP2.angle += 1 * playbackRate;
				}
			}
		}
		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (ClientPrefs.smoothHealth && ClientPrefs.smoothHealthType != 'Golden Apple 1.5' || !ClientPrefs.smoothHealth) //checks if you're using smooth health. if you are, but are not using the indie cross one then you know what that means
		{
			iconP1.x = 0 + healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
			iconP2.x = 0 + healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		}
		if (ClientPrefs.smoothHealth && ClientPrefs.smoothHealthType == 'Golden Apple 1.5') //really makes it feel like the gapple 1.5 build's health tween
		{
			final percent:Float = 1 - (ClientPrefs.smoothHPBug ? (displayedHealth / maxHealth) : (FlxMath.bound(displayedHealth, 0, maxHealth) / maxHealth));

			iconP1.x = 0 + healthBar.x + (healthBar.width * percent) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
			iconP2.x = 0 + healthBar.x + (healthBar.width * percent) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		}

		if (28820000 - Conductor.songPosition <= 20 && SONG.song.toLowerCase() == 'desert bus') { // WOW, who wants to load an 8 hour long song anyway? LMAO
			endSong();
		}

		if (health > maxHealth)
		{
			health = maxHealth;
		}

		if (iconP1.animation.numFrames == 3) {
			if (healthBar.percent < (ClientPrefs.longHPBar ? 15 : 20))
				iconP1.animation.curAnim.curFrame = 1;
			else if (healthBar.percent > (ClientPrefs.longHPBar ? 85 : 80))
				iconP1.animation.curAnim.curFrame = 2;
			else
				iconP1.animation.curAnim.curFrame = 0;
		}
		else {
			if (healthBar.percent < (ClientPrefs.longHPBar ? 15 : 20))
				iconP1.animation.curAnim.curFrame = 1;
		}
		if (iconP2.animation.numFrames == 3) {
			if (healthBar.percent > (ClientPrefs.longHPBar ? 85 : 80))
				iconP2.animation.curAnim.curFrame = 1;
			else if (healthBar.percent < (ClientPrefs.longHPBar ? 15 : 20))
				iconP2.animation.curAnim.curFrame = 2;
			else
				iconP2.animation.curAnim.curFrame = 0;
		} else {
			if (healthBar.percent > (ClientPrefs.longHPBar ? 85 : 80))
				iconP2.animation.curAnim.curFrame = 1;
			else
				iconP2.animation.curAnim.curFrame = 0;
		}

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			FlxG.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startedCountdown && !paused)
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				if(updateTime && FlxG.game.ticks % (Std.int(ClientPrefs.framerate / 60) > 0 ? Std.int(ClientPrefs.framerate / 60) : 1) == 0) {
					if (timeBar.visible) {
						songPercent = Conductor.songPosition / songLength;
					}
					if (Conductor.songPosition - lastUpdateTime >= 1.0)
					{
						lastUpdateTime = Conductor.songPosition;
						if (ClientPrefs.timeBarType != 'Song Name')
						{
							timeTxt.text = ClientPrefs.timeBarType.contains('Time Left') ? CoolUtil.getSongDuration(Conductor.songPosition, songLength) : CoolUtil.formatTime(Conductor.songPosition)
							+ (ClientPrefs.timeBarType.contains('Modern Time') ? ' / ' + CoolUtil.formatTime(songLength) : '');

							if (ClientPrefs.timeBarType == 'Song Name + Time')
								timeTxt.text = SONG.song + ' (' + CoolUtil.formatTime(Conductor.songPosition) + ' / ' + CoolUtil.formatTime(songLength) + ')';
						}

						if(ClientPrefs.timebarShowSpeed)
						{
							playbackRateDecimal = FlxMath.roundDecimal(playbackRate, 2);
							if (ClientPrefs.timeBarType != 'Song Name')
								timeTxt.text += ' (' + playbackRateDecimal + 'x)';
							else timeTxt.text = SONG.song + ' (' + playbackRateDecimal + 'x)';
						}
						if (cpuControlled && ClientPrefs.timeBarType != 'Song Name' && !ClientPrefs.communityGameBot) timeTxt.text += ' (Bot)';
						if(ClientPrefs.timebarShowSpeed && cpuControlled && ClientPrefs.timeBarType == 'Song Name') timeTxt.text = SONG.song + ' (' + FlxMath.roundDecimal(playbackRate, 2) + 'x) (Bot)';

						if(ffmpegMode) {
							if(!endingSong && Conductor.songPosition >= FlxG.sound.music.length - 20) {
								finishSong();
								endSong();
							}
						}
					}
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong && !heyStopTrying)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

	if (unspawnNotes.length > 0 && (unspawnNotes[0] != null))
	{
		notesAddedCount = 0;

		if (notesAddedCount > unspawnNotes.length)
			notesAddedCount -= (notesAddedCount - unspawnNotes.length);

		while (unspawnNotes.length > 0 && unspawnNotes[notesAddedCount] != null && unspawnNotes[notesAddedCount].strumTime - Conductor.songPosition < NOTE_SPAWN_TIME) {
			var dunceNote:Note = new Note(unspawnNotes[notesAddedCount].strumTime, unspawnNotes[notesAddedCount].noteData, unspawnNotes[notesAddedCount].prevNote, unspawnNotes[notesAddedCount].noteskin, unspawnNotes[notesAddedCount].isSustainNote);
					if (unspawnNotes[notesAddedCount].texture.length > 1 && unspawnNotes[notesAddedCount].noteskin.length < 1) dunceNote.texture = unspawnNotes[notesAddedCount].texture;
					dunceNote.mustPress = unspawnNotes[notesAddedCount].mustPress;
					dunceNote.sustainLength = unspawnNotes[notesAddedCount].sustainLength;
					dunceNote.gfNote = unspawnNotes[notesAddedCount].gfNote;
					dunceNote.noteType = unspawnNotes[notesAddedCount].noteType;
					dunceNote.noAnimation = unspawnNotes[notesAddedCount].noAnimation;
					dunceNote.noMissAnimation = unspawnNotes[notesAddedCount].noMissAnimation;

					if (ClientPrefs.doubleGhost && !dunceNote.isSustainNote)
						{
						dunceNote.row = Conductor.secsToRow(dunceNote.strumTime);
						if(noteRows[dunceNote.mustPress?0:1][dunceNote.row]==null)
							noteRows[dunceNote.mustPress?0:1][dunceNote.row]=[];
						noteRows[dunceNote.mustPress ? 0 : 1][dunceNote.row].push(dunceNote);
						}

			if (dunceNote.isSustainNote) {
				dunceNote.parent = unspawnNotes[notesAddedCount].parent;
				if (unspawnNotes[notesAddedCount].isSustainEnd) { // Generate hold end
					dunceNote.animation.play(Note.colArray[dunceNote.noteData] + 'holdend');
					dunceNote.scale.set(0.7, 1.0);
					dunceNote.updateHitbox();
				}
				dunceNote.correctionOffset = (ClientPrefs.downScroll ? 0 : 55);

				if(!isPixelStage)
				{
					if(dunceNote.prevNote.isSustainNote)
					{
						dunceNote.prevNote.scale.y *= Note.SUSTAIN_SIZE / dunceNote.prevNote.frameHeight;
						dunceNote.prevNote.updateHitbox();
					}
				}
			}

			dunceNote.scrollFactor.set();

				dunceNote.strum = unspawnNotes[notesAddedCount].strum;
			if (!ClientPrefs.useOldNoteSorting) {
				(dunceNote.isSustainNote ? sustainNotes : notes).insert(0, dunceNote);
			} else {
				(dunceNote.isSustainNote ? sustainNotes : notes).add(dunceNote);
			}
			callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);
			notesAddedCount++;
		}
			if (notesAddedCount > 0)
				unspawnNotes.splice(0, notesAddedCount);
	}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled) {
					keyShit();
				}
				else if (ClientPrefs.charsAndBG) {
				if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / playbackRate) * boyfriend.singDuration * singDurMult && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
		  				if (dad.animation.curAnim != null && dad.holdTimer > Conductor.stepCrochet * (0.0011 / playbackRate) * dad.singDuration * singDurMult && dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss')) {
					dad.dance();
				}
				}

				if(startedCountdown)
				{
					for (group in [notes, sustainNotes]) group.forEachAlive(function(daNote:Note)
					{
						if (ClientPrefs.showNotes && daNote.exists)
						{
							daNote.followStrumNote(daNote.strum, (60 / SONG.bpm) * 1000, songSpeed);
							if(daNote.isSustainNote && daNote.strum.sustainReduce) daNote.clipToStrumNote(daNote.strum);
						}

						if (!daNote.mustPress && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.strumTime <= Conductor.songPosition)
						{
							if (!ClientPrefs.showcaseMode || ClientPrefs.charsAndBG) opponentNoteHit(daNote);
								if (ClientPrefs.showcaseMode && !ClientPrefs.charsAndBG)
								{
									if (!daNote.isSustainNote) {
										enemyHits += 1 * polyphony;
										if (ClientPrefs.showNPS) {
											oppNotesHitArray.push(1 * polyphony);
											oppNotesHitDateArray.push(Conductor.songPosition);
										}
									}
									if (!daNote.isSustainNote) {
										notes.remove(daNote, true);
									}
								}
						}

						if(daNote.mustPress) {
							if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
							{
								if (daNote.mustPress && (!cpuControlled || cpuControlled && ClientPrefs.communityGameBot) && !daNote.ignoreNote && !endingSong && !daNote.wasGoodHit) {
									noteMiss(daNote);
									if (ClientPrefs.missSoundShit)
									{
										FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
									}
								}

								daNote.active = false;
								daNote.visible = false;
								group.remove(daNote, true);
							}
							if(cpuControlled && daNote.strumTime + (ClientPrefs.communityGameBot ? FlxG.random.float(ClientPrefs.minCGBMS, ClientPrefs.maxCGBMS) : 0) <= Conductor.songPosition && !daNote.ignoreNote) {
								if (!ClientPrefs.showcaseMode || ClientPrefs.charsAndBG) goodNoteHit(daNote);
								if (ClientPrefs.showcaseMode && !ClientPrefs.charsAndBG)
								{
									if (!daNote.isSustainNote) {
										totalNotesPlayed += 1 * polyphony;
										if (ClientPrefs.showNPS) {
											notesHitArray.push(1 * polyphony);
											notesHitDateArray.push(Conductor.songPosition);
										}
										notes.remove(daNote, true);
									}
								}
							}
						}
					});
				}
				else
				{
					for (group in [notes, sustainNotes]) group.forEachAlive(function(daNote:Note)
					{
						group.remove(daNote, true);
					});
				}
			}

			// This used to be a function
			while(eventNotes.length > 0) {
				var leStrumTime:Float = eventNotes[0].strumTime;
				if(Conductor.songPosition < leStrumTime) {
					break;
				}
	
				//trace(eventNotes[eventNotes.length-1].event); This was probably to check if events actually work, now that I know they work we don't need this
	
				var value1:String = '';
				if(eventNotes[0].value1 != null)
					value1 = eventNotes[0].value1;
	
				var value2:String = '';
				if(eventNotes[0].value2 != null)
					value2 = eventNotes[0].value2;
	
				triggerEventNote(eventNotes[0].event, value1, value2);
				eventNotes.shift();
			}
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				if (ClientPrefs.songLoading) FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
			if(FlxG.keys.justPressed.THREE) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition - 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if (trollingMode && startedCountdown && canPause && !endingSong) {
			if (FlxG.sound.music.length - Conductor.songPosition <= endingTimeLimit) {
				KillNotes(); //kill any existing notes
				FlxG.sound.music.time = 0;
				if (SONG.needsVoices && vocals != null) vocals.time = 0;
				lastUpdateTime = 0.0;
				Conductor.songPosition = 0;

				unspawnNotes = unspawnNotesCopy.copy();
				eventNotes = eventNotesCopy.copy();
				loopSongLol();
			}
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);

		for (i in shaderUpdates){
			i(elapsed);
		}
		if(ffmpegMode && !noCapture)
		{
			var filename = CoolUtil.zeroFill(frameCaptured, 7);
			capture.save(Paths.formatToSongPath(SONG.song) + #if linux '/' #else '\\' #end, filename);
			#if windows //linux and mac should have good pcs iirc
				if (!memoryOver6GB) openfl.system.System.gc();
			#end
		}
		frameCaptured++;

		if(botplayTxt != null && botplayTxt.visible) {
			if (ffmpegInfo)
				botplayTxt.text = CoolUtil.floatToStringPrecision(haxe.Timer.stamp() - takenTime, 3);
		}
		takenTime = haxe.Timer.stamp();
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null && ClientPrefs.songLoading) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
		if (!ClientPrefs.charsAndBG) openSubState(new PauseSubState(0, 0));
		if (ClientPrefs.charsAndBG) openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		//}

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		FlxG.switchState(new ChartingState());
		chartingMode = true;
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
		if (ClientPrefs.instaRestart)
		{
		restartSong(true);
		}
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				if (ClientPrefs.songLoading) vocals.stop();
				if (ClientPrefs.songLoading) FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				if (ClientPrefs.charsAndBG) openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				if (!ClientPrefs.charsAndBG) openSubState(new GameOverSubstate(0, 0, 0, 0));

				// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if DISCORD_ALLOWED
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Dadbattle Spotlight':
				if (curStage != 'stage') return;

				var val:Null<Int> = Std.parseInt(value1);
				if(val == null) val = 0;

				switch(Std.parseInt(value1))
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
						{
							dadbattleSmokes.visible = false;
						}});
				}

			case 'Hey!':
				if (ClientPrefs.charsAndBG) {
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;
				if (Conductor.bpm >= 500) singDurMult = value;

			case 'Philly Glow':
				if (curStage != 'philly') return;

				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				var doFlash:Void->Void = function() {
					var color:FlxColor = FlxColor.WHITE;
					if(!ClientPrefs.flashing) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch(lightId)
				{
					case 0:
						if(phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if(!phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if(ClientPrefs.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.flashing) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2: // spawn particles
						if(!ClientPrefs.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Enable Camera Bop':
				camZooming = true;

			case 'Disable Camera Bop':
				camZooming = false;

			case 'Credits Popup':
			{
				var string1:String = value1;
				if (value1 == '') string1 = SONG.song;
				var string2:String = value2;
				if (value2 == '') string2 = SONG.songCredit;
			var creditsPopup:CreditsPopUp = new CreditsPopUp(FlxG.width, 200, value1, value2);
				creditsPopup.camera = camHUD;
				creditsPopup.scrollFactor.set();
				creditsPopup.x = creditsPopup.width * -1;
				add(creditsPopup);

				FlxTween.tween(creditsPopup, {x: 0}, 0.5, {ease: FlxEase.backOut, onComplete: function(tweeen:FlxTween)
				{
					FlxTween.tween(creditsPopup, {x: creditsPopup.width * -1} , 1, {ease: FlxEase.backIn, onComplete: function(tween:FlxTween)
					{
						creditsPopup.destroy();
							}, startDelay: 3});
						}});
			}
			case 'Camera Bopping':
				var _interval:Int = Std.parseInt(value1);
				if (Math.isNaN(_interval))
					_interval = 4;
				var _intensity:Float = Std.parseFloat(value2);
				if (Math.isNaN(_intensity))
					_intensity = 1;

				camBopIntensity = _intensity;
				camBopInterval = _interval;

			case 'Camera Twist':
				camTwist = true;
				var _intensity:Float = Std.parseFloat(value1);
				if (Math.isNaN(_intensity))
					_intensity = 0;
				var _intensity2:Float = Std.parseFloat(value2);
				if (Math.isNaN(_intensity2))
					_intensity2 = 0;
				camTwistIntensity = _intensity;
				camTwistIntensity2 = _intensity2;
				if (_intensity2 == 0)
				{
					camTwist = false;
					FlxTween.tween(camHUD, {angle: 0}, 1, {ease: FlxEase.sineInOut});
					FlxTween.tween(camGame, {angle: 0}, 1, {ease: FlxEase.sineInOut});
				}
			case 'Change Note Multiplier':
				var noteMultiplier:Float = Std.parseFloat(value1);
				if (Math.isNaN(noteMultiplier))
					noteMultiplier = 1;

				polyphony = noteMultiplier;
			case 'Fake Song Length':
				var fakelength:Float = Std.parseFloat(value1);
				fakelength *= (Math.isNaN(fakelength) ? 1 : 1000); //don't multiply if value1 is null, but do if value1 is not null
				var doTween:Bool = value2 == "true" ? true : false;
				if (Math.isNaN(fakelength))
					if (ClientPrefs.songLoading) fakelength = FlxG.sound.music.length;
				if (doTween = true) FlxTween.tween(this, {songLength: fakelength}, 1, {ease: FlxEase.expoOut});
				if (doTween = true && ClientPrefs.songLoading && (Math.isNaN(fakelength))) FlxTween.tween(this, {songLength: FlxG.sound.music.length}, 1, {ease: FlxEase.expoOut});
				songLength = fakelength;

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}
			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null && ClientPrefs.charsAndBG)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if(Math.isNaN(val1)) val1 = 0;
					if(Math.isNaN(val2)) val2 = 0;

					isCameraOnForcedPos = false;
					if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
						camFollow.x = val1;
						camFollow.y = val2;
						isCameraOnForcedPos = true;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
			if (ClientPrefs.charsAndBG)
			{
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							if (value2 != 'bf' || value2 != 'boyfriend') iconP1.changeIcon(boyfriend.healthIcon);
							else {
								if (ClientPrefs.bfIconStyle == 'VS Nonsense V2') iconP1.changeIcon('bfnonsense');
								if (ClientPrefs.bfIconStyle == 'Doki Doki+') iconP1.changeIcon('bfdoki');
								if (ClientPrefs.bfIconStyle == 'Leather Engine') iconP1.changeIcon('bfleather');
								if (ClientPrefs.bfIconStyle == "Mic'd Up") iconP1.changeIcon('bfmup');
								if (ClientPrefs.bfIconStyle == "FPS Plus") iconP1.changeIcon('bffps');
								if (ClientPrefs.bfIconStyle == "SB Engine") iconP1.changeIcon('bfsb');
								if (ClientPrefs.bfIconStyle == "OS 'Engine'") iconP1.changeIcon('bfos');
							}
							bfNoteskin = boyfriend.noteskin;
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
							if (ClientPrefs.hudType == 'VS Impostor') {
								if (botplayTxt != null) FlxTween.color(botplayTxt, 1, botplayTxt.color, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
								
								if (!ClientPrefs.hideScore && scoreTxt != null && !ClientPrefs.hideHud) FlxTween.color(scoreTxt, 1, scoreTxt.color, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
							}
							if (ClientPrefs.hudType == 'JS Engine' && !ClientPrefs.hideHud) {
								if (!ClientPrefs.hideScore && scoreTxt != null) FlxTween.color(scoreTxt, 1, scoreTxt.color, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
							}
						}
							dadNoteskin = dad.noteskin;
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				shouldDrainHealth = (opponentDrain || (opponentChart ? boyfriend.healthDrain : dad.healthDrain));
				if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainAmount)) healthDrainAmount = opponentChart ? boyfriend.drainAmount : dad.drainAmount;
				if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainFloor)) healthDrainFloor = opponentChart ? boyfriend.drainFloor : dad.drainFloor;
				if (!ClientPrefs.ogHPColor) reloadHealthBarColors(dad.healthColorArray, boyfriend.healthColorArray);
				if (ClientPrefs.showNotes)
				{
					for (i in strumLineNotes.members)
						i.updateNoteSkin(i.player == 0 ? dadNoteskin : bfNoteskin);
				}
				if (ClientPrefs.noteColorStyle == 'Char-Based')
				{
				for (note in notes){
				 	if (note == null)
						continue;
					note.updateRGBColors();
				}
				for (note in sustainNotes){
				 	if (note == null)
						continue;
					note.updateRGBColors();
				}
				for (note in playerStrums.members){
				 	if (note == null)
						continue;
					note.updateRGBColors(true);
				}
				for (note in opponentStrums.members){
				 	if (note == null)
						continue;
					note.updateRGBColors(false);
				}
				}
			}

			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();

			case 'Rainbow Eyesore':
					if(ClientPrefs.flashing) {
						var timeRainbow:Int = Std.parseInt(value1);
						var speedRainbow:Float = Std.parseFloat(value2);
						disableTheTripper = false;
						disableTheTripperAt = timeRainbow;
						FlxG.camera.filters = [new ShaderFilter(screenshader.shader)];
						screenshader.waveAmplitude = 1;
						screenshader.waveFrequency = 2;
						screenshader.waveSpeed = speedRainbow * playbackRate;
						screenshader.shader.uTime.value[0] = new flixel.math.FlxRandom().float(-100000, 100000);
						screenshader.shader.uampmul.value[0] = 1;
						screenshader.Enabled = true;
					}
			case 'Popup':
				var title:String = (value1);
				var message:String = (value2);
				FlxG.sound.music.pause();
				vocals.pause();

				lime.app.Application.current.window.alert(message, title);
				FlxG.sound.music.resume();
				vocals.resume();
			case 'Popup (No Pause)':
				var title:String = (value1);
				var message:String = (value2);

				lime.app.Application.current.window.alert(message, title);

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Change Song Name':
				if(ClientPrefs.timeBarType == 'Song Name' && !ClientPrefs.timebarShowSpeed)
				{
					if (value1.length > 1)
						timeTxt.text = value1;
					else timeTxt.text = curSong;
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1) {
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					FunkinLua.setVarInArray(this, value1, value2);
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		if (!trollingMode) {
			var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.
			updateTime = false;
			if (ClientPrefs.songLoading) {
				FlxG.sound.music.volume = 0;
				vocals.volume = 0;
			}
			vocals.pause();
			if(!ffmpegMode){
				if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
					finishCallback();
				} else {
					finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
						finishCallback();
					});
				}
			} else finishCallback();
		}
	}

	public var loopMult:Int = 1;
	public var loopCount:Int = 0;
	public var rateTroll:Float = 0;
	public function loopSongLol()
	{
		stepsToDo = /* You need stepsToDo to change, otherwise the sections break. */ curStep = curBeat = curSection = 0; // Wow.
		oldStep = lastStepHit = lastBeatHit = -1;
			rateTroll = playbackRate / loopMult;
			loopCount++;
			if (Std.int(rateTroll) % 2 == 0) 
			{
				loopMult *= 2;
				rateTroll = 0;
			}

			// And now it's time for the actual troll mode stuff
			var TROLL_MAX_SPEED:Float = 2048; // Default is medium max speed
			switch(ClientPrefs.trollMaxSpeed) {
				case 'Lowest':
					TROLL_MAX_SPEED = 256;
				case 'Lower':
					TROLL_MAX_SPEED = 512;
				case 'Low':
					TROLL_MAX_SPEED = 1024;
				case 'Medium':
					TROLL_MAX_SPEED = 2048;
				case 'High':
					TROLL_MAX_SPEED = 5120;
				case 'Highest':
					TROLL_MAX_SPEED = 10000;
				default:
					TROLL_MAX_SPEED = 1.79e+308; //no limit (until you eventually suffer the fate of crashing :trollface:)
			}

			if (ClientPrefs.voiidTrollMode) {
				playbackRate *= 1.05;
			} else {
				playbackRate += 0.05 * loopMult;
			}

			if (playbackRate >= TROLL_MAX_SPEED && ClientPrefs.trollMaxSpeed != 'Disabled') { // Limit playback rate to the troll mode max speed
				playbackRate = TROLL_MAX_SPEED;
			}

			readyToTriggerTrollMode = false;

			songWasLooped = true;
	}

	public var transitioning = false;
	public var endedTheSong = false;
	public function endSong():Void
	{
		if (!endedTheSong && ClientPrefs.resultsScreen)
		{
			Conductor.songPosition = 0; //so that it doesnt skip the results screen
			if (!isStoryMode || isStoryMode && storyPlaylist.length <= 0)
			{
				new FlxTimer().start(0.02, function(tmr:FlxTimer) {
					endedTheSong = true;
				});
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;
				openSubState(new ResultsScreenSubState([perfects, sicks, goods, bads, shits], Std.int(songScore), Std.int(songMisses), Highscore.floorDecimal(ratingPercent * 100, 2),
					ratingName + (' [' + ratingFC + '] ')));
			} else {
				endedTheSong = true;
			}
		}
		if (!ClientPrefs.resultsScreen) {
			endedTheSong = true;
		}
		if (endedTheSong || !ClientPrefs.resultsScreen)
		{
			timeBarBG.visible = false;
			timeBar.visible = false;
			timeTxt.visible = false;
			canPause = false;
			endingSong = true;
			camZooming = false;
			inCutscene = false;
			updateTime = false;

			deathCounter = 0;
			seenCutscene = false;

			#if ACHIEVEMENTS_ALLOWED
			if(achievementObj != null) {
				return;
			} else {
				var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
					'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
					'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
				var customAchieves:String = checkForAchievement(achievementWeeks);

				if(achieve != null || customAchieves != null) {
					startAchievement(achieve);
					return;
				}
			}
			#end

			var ret:Dynamic = callOnLuas('onEndSong', [], false);
			if(ret != FunkinLua.Function_Stop && !transitioning) {
				if (!cpuControlled && !playerIsCheating && ClientPrefs.comboMultLimit <= 10 && ClientPrefs.safeFrames <= 10)
				{
					#if !switch
					var percent:Float = ratingPercent;
					if(Math.isNaN(percent)) percent = 0;
					Highscore.saveScore(SONG.song, Std.int(songScore), storyDifficulty, percent);
					#end
				}
				playbackRate = 1;

				if (chartingMode)
				{
					openChartEditor();
					return;
				}

				if (isStoryMode)
				{
					campaignScore += songScore;
					campaignMisses += Std.int(songMisses);

					storyPlaylist.remove(storyPlaylist[0]);

					if (storyPlaylist.length <= 0)
					{
						WeekData.loadTheFirstEnabledMod();
						FlxG.sound.playMusic(Paths.music('freakyMenu-' + ClientPrefs.daMenuMusic));

						cancelMusicFadeTween();
						if(FlxTransitionableState.skipNextTransIn) {
							CustomFadeTransition.nextCamera = null;
						}
						FlxG.switchState(new StoryMenuState()); //removed results screen from story mode because for some reason it opens the screen after the first song even if the story playlist's length is greater than 0??

						// if ()
						if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
							StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

							if (SONG.validScore)
							{
								Highscore.saveWeekScore(WeekData.getWeekFileName(), Std.int(campaignScore), storyDifficulty);
							}

							FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
							FlxG.save.flush();
						}
						changedDifficulty = false;
					}
					else
					{
						var difficulty:String = CoolUtil.getDifficultyFilePath();

						trace('LOADING NEXT SONG');
						trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

						var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
						if (winterHorrorlandNext)
						{
							var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
								-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
							blackShit.scrollFactor.set();
							add(blackShit);
							camHUD.visible = false;

							FlxG.sound.play(Paths.sound('Lights_Shut_off'));
						}

						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						prevCamFollow = camFollow;
						prevCamFollowPos = camFollowPos;


						if (storyDifficulty == 2)
						{
							if (ClientPrefs.JSEngineRecharts && CoolUtil.defaultSongs.contains(PlayState.storyPlaylist[0].toLowerCase())) {
								PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + '-jshard', PlayState.storyPlaylist[0]);
								}
								else if (ClientPrefs.JSEngineRecharts && !CoolUtil.defaultSongs.contains(PlayState.storyPlaylist[0].toLowerCase())) 	{
								PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
								}
							else if (!ClientPrefs.JSEngineRecharts)
								PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
						} else {
							PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
						}
						FlxG.sound.music.stop();

						if(winterHorrorlandNext) {
							new FlxTimer().start(1.5, function(tmr:FlxTimer) {
								cancelMusicFadeTween();
								LoadingState.loadAndSwitchState(new PlayState());
							});
						} else {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						}
					}
				}
				else
				{
					trace('WENT BACK TO FREEPLAY??');
					WeekData.loadTheFirstEnabledMod();
					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					FlxG.switchState(new FreeplayState());
					FlxG.sound.playMusic(Paths.music('freakyMenu-' + ClientPrefs.daMenuMusic));
					changedDifficulty = false;
				}
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			notes.remove(notes.members[0], true);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public static function restartSong(noTrans:Bool = true)
	{
		PlayState.instance.paused = true; // For lua
		if (ClientPrefs.songLoading) FlxG.sound.music.volume = 0;
		if (ClientPrefs.songLoading) PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			FlxG.resetState();
		}
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	public var totalNotes:Float = 0;

	public var showCombo:Bool = true;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore()
	{
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		switch (ClientPrefs.ratingType)
		{
			case 'Doki Doki+': pixelShitPart1 = 'dokistuff/';
			case 'Tails Gets Trolled V4': pixelShitPart1 = 'tgtstuff/';
			case 'Kade Engine': pixelShitPart1 = 'kadethings/';
			case 'VS Impostor': pixelShitPart1 = 'impostorratings/';
			case 'Base FNF': pixelShitPart1 = '';
			default: pixelShitPart1 = ClientPrefs.ratingType.toLowerCase().replace(' ', '').trim() + '/';
		}
		if (allSicks) { //cache gold rating sprites
		Paths.image('goldstuff/' + "perfect" + pixelShitPart2);
		Paths.image('goldstuff/' + "sick" + pixelShitPart2);
		Paths.image('goldstuff/' + "combo" + pixelShitPart2);
		for (i in 0...10) Paths.image('goldstuff/' + 'num' + i + pixelShitPart2);
			trace('cached gold ratings');
		}
		//cache normal/pixel ratings
		Paths.image(pixelShitPart1 + "perfect" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "combo" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "miss" + pixelShitPart2);

		for (i in 0...10) Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
	}

	function doGhostAnim(char:String, animToPlay:String)
	{
	if (ClientPrefs.doubleGhost || ClientPrefs.charsAndBG)
		{
			var ghost:FlxSprite = dadGhost;
			var player:Character = dad;

			switch(char.toLowerCase().trim())
			{
				case 'bf':
					ghost = bfGhost;
					player = boyfriend;
				case 'dad':
					ghost = dadGhost;
					player = dad;
				case 'gf':
					ghost = gfGhost;
					player = gf;
			}

			if (player.animation != null)
			{
				ghost.frames = player.frames;

				// Check for null before copying from player.animation
				if (player.animation != null)
				{
					ghost.animation.copyFrom(player.animation);
				}

				ghost.x = player.x;
				ghost.y = player.y;
				ghost.animation.play(animToPlay, true);

				// Check for null before accessing animOffsets
				if (player.animOffsets != null && player.animOffsets.exists(animToPlay))
				{
					ghost.offset.set(player.animOffsets.get(animToPlay)[0], player.animOffsets.get(animToPlay)[1]);
				}

				ghost.flipX = player.flipX;
				ghost.flipY = player.flipY;
				ghost.blend = HARDLIGHT;
				ghost.alpha = 0.8;
				ghost.visible = true;

				if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && camZooming && ClientPrefs.doubleGhostZoom)
				{
					FlxG.camera.zoom += 0.0075;
					camHUD.zoom += 0.015;
				}

				switch (char.toLowerCase().trim())
				{
					case 'bf':
						if (bfGhostTween != null)
							bfGhostTween.cancel();
						ghost.color = FlxColor.fromRGB(boyfriend.healthColorArray[0] + 50, boyfriend.healthColorArray[1] + 50, boyfriend.healthColorArray[2] + 50);
						bfGhostTween = FlxTween.tween(bfGhost, {alpha: 0}, 0.75, {
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween)
							{
								bfGhostTween = null;
							}
						});

					case 'dad':
						if (dadGhostTween != null)
							dadGhostTween.cancel();
						ghost.color = FlxColor.fromRGB(dad.healthColorArray[0] + 50, dad.healthColorArray[1] + 50, dad.healthColorArray[2] + 50);
						dadGhostTween = FlxTween.tween(dadGhost, {alpha: 0}, 0.75, {
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween)
							{
								dadGhostTween = null;
							}
						});

					case 'gf':
						if (gfGhostTween != null)
							gfGhostTween.cancel();
						if (gf != null) ghost.color = FlxColor.fromRGB(gf.healthColorArray[0] + 50, gf.healthColorArray[1] + 50, gf.healthColorArray[2] + 50);
						gfGhostTween = FlxTween.tween(gfGhost, {alpha: 0}, 0.75, {
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween)
							{
								gfGhostTween = null;
							}
						});
				}
			}
		}
	}

	private function popUpScore(note:Note = null, ?miss:Bool = false):Void
	{
		popUpsFrame += 1;
		final noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset) / playbackRate;
		final wife:Float = EtternaFunctions.wife3(noteDiff, Conductor.timeScale) / playbackRate;

		if (!miss && !ffmpegMode) vocals.volume = 1;

		final offset = FlxG.width * 0.35;
		if(ClientPrefs.scoreZoom && !ClientPrefs.hideScore && !cpuControlled && !miss)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}

		//tryna do MS based judgment due to popular demand
		final daRating:Rating = Conductor.judgeNote(note, noteDiff, cpuControlled, miss);

		if (miss) daRating.image = 'miss';
			else if (ratingsData[0].image == 'miss') ratingsData[0].image = !ClientPrefs.noMarvJudge ? 'perfect' : 'sick';

		if (daRating.name == 'sick' && !ClientPrefs.noMarvJudge) maxScore -= 150 * Std.int(polyphony); //if you enable perfect judges and hit a sick, lower the max score by 150 points. otherwise it won't make sense

		if ((cpuControlled && ClientPrefs.communityGameBot || cpuControlled && !ClientPrefs.lessBotLag || !cpuControlled) && !miss)
		{
			if (!ClientPrefs.complexAccuracy) totalNotesHit += daRating.ratingMod;
			if (ClientPrefs.complexAccuracy) totalNotesHit += wife;
			note.ratingMod = daRating.ratingMod;
			if(!note.ratingDisabled) daRating.increase();
		}
		note.rating = daRating.name;

		if (goods > 0 || bads > 0 || shits > 0 || songMisses > 0 && ClientPrefs.goldSickSFC || !ClientPrefs.goldSickSFC)
		{
			// if it isn't a sick, and you had a sick combo, then it becomes not sick :(
			if (allSicks)
				allSicks = false;

		}
		if (daRating.name == 'shit' && ClientPrefs.shitGivesMiss && ClientPrefs.ratingIntensity == 'Normal')
		{
			noteMiss(note);
		}
		if (noteDiff > ClientPrefs.goodWindow && ClientPrefs.shitGivesMiss && ClientPrefs.ratingIntensity == 'Harsh')
		{
			noteMiss(note);
		}
		if (noteDiff > ClientPrefs.sickWindow && ClientPrefs.shitGivesMiss && ClientPrefs.ratingIntensity == 'Very Harsh')
		{
			noteMiss(note);
		}
			switch (ClientPrefs.healthGainType)
			{
				case 'Leather Engine':
					switch(daRating.name)
					{
						case 'perfect', 'sick': health += 0.012 * healthGain * polyphony;
						case 'good': health += -0.008 * healthGain * polyphony;
						case 'bad': health += -0.018 * healthGain * polyphony;
						case 'shit': health += -0.023 * healthGain * polyphony;
					}
				case 'Kade (1.4.2 to 1.6)', 'Doki Doki+':
					switch(daRating.name)
					{
						case 'perfect', 'sick': health += (ClientPrefs.healthGainType == 'Doki Doki+' ? 0.077 : 0.1) * healthGain * polyphony;
						case 'good': health += 0.04 * healthGain * polyphony;
						case 'bad': health -= 0.06 * healthGain * polyphony;
						case 'shit': health -= (ClientPrefs.healthGainType == 'Doki Doki+' ? 0.1 : 0.2) * healthLoss * polyphony;
					}
				case 'Kade (1.6+)':
					switch(daRating.name)
					{
						case 'perfect', 'sick': health += 0.017 * healthGain * polyphony;
						case 'good': health += 0 * healthGain * polyphony;
						case 'bad': health += -0.03 * healthLoss;
						case 'shit': health += -0.06 * healthLoss;
					}
				case 'Kade (1.2)':
					switch(daRating.name)
					{
						case 'perfect', 'sick': health += 0.023 * healthGain * polyphony;
						case 'good': health += 0.004 * healthGain * polyphony;
						case 'bad': health += 0;
						case 'shit': health += 0;
					}
			}

		if(daRating.noteSplash && !note.noteSplashDisabled && !miss)
		{
			spawnNoteSplashOnNote(false, note, note.gfNote);
		}

		if(!practiceMode && !miss) {
			songScore += daRating.score * comboMultiplier * polyphony;
			if(!note.ratingDisabled || cpuControlled && ClientPrefs.communityGameBot && !note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				if(!cpuControlled || cpuControlled && ClientPrefs.communityGameBot) {
				RecalculateRating(false);
				}
			}
		}

			if (ClientPrefs.ratesAndCombo && ClientPrefs.ratingType != 'Simple' && popUpsFrame <= 3) {
				if (PlayState.isPixelStage)
				{
					pixelShitPart1 = 'pixelUI/';
					pixelShitPart2 = '-pixel';
				}
				switch (ClientPrefs.ratingType)
				{
					case 'Doki Doki+': pixelShitPart1 = 'dokistuff/';
					case 'Tails Gets Trolled V4': pixelShitPart1 = 'tgtstuff/';
					case 'Kade Engine': pixelShitPart1 = 'kadethings/';
					case 'VS Impostor': pixelShitPart1 = 'impostorratings/';
					case 'Base FNF': pixelShitPart1 = '';
					default: pixelShitPart1 = ClientPrefs.ratingType.toLowerCase().replace(' ', '').trim() + '/';
				}
				if (allSicks && ClientPrefs.marvRateColor == 'Golden' && noteDiff < ClientPrefs.sickWindow && ClientPrefs.ratingType != 'Tails Gets Trolled V4' && ClientPrefs.ratingType != 'Doki Doki+' && !ClientPrefs.noMarvJudge)
				{
					pixelShitPart1 = 'goldstuff/';
				}
				if (!allSicks && ClientPrefs.marvRateColor == 'Golden' && noteDiff < ClientPrefs.perfectWindow && ClientPrefs.hudType != 'Tails Gets Trolled V4' && ClientPrefs.hudType != 'Doki Doki+' && !ClientPrefs.noMarvJudge)
				{
					pixelShitPart1 = 'goldstuff/';
				}
				final rating = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
				rating.cameras = (ClientPrefs.wrongCameras ? [camGame] : [camHUD]);
				rating.screenCenter();
				rating.x = offset - 40;
				rating.y -= 60;
				rating.acceleration.y = 550 * playbackRate * playbackRate;
				rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
				rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
				rating.visible = (!ClientPrefs.hideHud && showRating);
				rating.x += ClientPrefs.comboOffset[0];
				rating.y -= ClientPrefs.comboOffset[1];
				if (!miss)
				{
					if (!allSicks && ClientPrefs.colorRatingFC && perfects > 0 && noteDiff > ClientPrefs.perfectWindow && ClientPrefs.hudType != 'Tails Gets Trolled V4' && ClientPrefs.hudType != 'Doki Doki+' && ClientPrefs.noMarvJudge)
							{
							rating.color = judgeColours.get('perfect');
							}
					if (!allSicks && ClientPrefs.colorRatingFC && sicks > 0 && noteDiff > ClientPrefs.perfectWindow && ClientPrefs.hudType != 'Tails Gets Trolled V4' && ClientPrefs.hudType != 'Doki Doki+' && ClientPrefs.marvRateColor != 'Golden' && !ClientPrefs.noMarvJudge)
							{
							rating.color = judgeColours.get('sick');
							}
					if (!allSicks && ClientPrefs.colorRatingFC && goods > 0 && noteDiff > ClientPrefs.perfectWindow && ClientPrefs.hudType != 'Tails Gets Trolled V4' && ClientPrefs.hudType != 'Doki Doki+')
							{
							rating.color = judgeColours.get('good');
							}
					if (!allSicks && ClientPrefs.colorRatingFC && bads > 0 && noteDiff > ClientPrefs.perfectWindow && ClientPrefs.hudType != 'Tails Gets Trolled V4' && ClientPrefs.hudType != 'Doki Doki+')
							{
							rating.color = judgeColours.get('bad');
							}
					if (!allSicks && ClientPrefs.colorRatingFC && shits > 0 && noteDiff > ClientPrefs.perfectWindow && ClientPrefs.hudType != 'Tails Gets Trolled V4' && ClientPrefs.hudType != 'Doki Doki+')
							{
							rating.color = judgeColours.get('shit');
							}
					if (!allSicks && ClientPrefs.colorRatingHit && ClientPrefs.hudType != 'Tails Gets Trolled V4' && ClientPrefs.hudType != 'Doki Doki+' && !miss)
							{
								switch (daRating.name) //This is so stupid, but it works
								{
								case 'sick':  rating.color = FlxColor.CYAN;
								case 'good': rating.color = FlxColor.LIME;
								case 'bad': rating.color = FlxColor.ORANGE;
								case 'shit': rating.color = FlxColor.RED;
								default: rating.color = FlxColor.WHITE;
								}
							}
				}
				insert(members.indexOf(strumLineNotes), rating);

				if (!PlayState.isPixelStage)
				{
					rating.setGraphicSize(Std.int(rating.width * 0.7));
					rating.antialiasing = ClientPrefs.globalAntialiasing;
				}
				else
				{
					rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
				}

				rating.updateHitbox();

				final separatedScore:Array<Dynamic> = [];
				if (combo < 0) {
					separatedScore.push("neg");
				}
				if (combo > 0)
					for (i in 0...Std.string(Std.int(combo)).length) {
						separatedScore.push(Std.parseInt(Std.string(combo).split("")[i]));
					}
				else //a dumb fix if the combo is negative
					for (i in 0...Std.string(Std.int(-combo)).length) {
						separatedScore.push(Std.parseInt(Std.string(-combo).split("")[i]));
					}

				if (!ClientPrefs.comboStacking)
				{
					if (lastRating != null)
					{
						FlxTween.cancelTweensOf(lastRating);
						remove(lastRating, true);
						lastRating.destroy();
					}
						lastRating = rating;
					if (lastScore != null) {
						for (sprite in lastScore) {
							FlxTween.cancelTweensOf(sprite);
							remove(sprite, true);
							sprite.destroy();
						}
						lastScore = []; // Clear the array
					}
				}
				for (daLoop=>i in separatedScore)
				{
					final numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2));
					numScore.cameras = (ClientPrefs.wrongCameras ? [camGame] : [camHUD]);
					numScore.screenCenter();
					numScore.x = offset + (43 * daLoop) - 90;
					numScore.y += 80;
					if (miss) numScore.color = FlxColor.fromRGB(204, 66, 66);

					numScore.x += ClientPrefs.comboOffset[2];
					numScore.y -= ClientPrefs.comboOffset[3];
					if (ClientPrefs.colorRatingHit && ClientPrefs.hudType != 'Tails Gets Trolled V4' && ClientPrefs.hudType != 'Doki Doki+' && noteDiff >= ClientPrefs.perfectWindow) numScore.color = rating.color;

					if (!ClientPrefs.comboStacking)
						lastScore.push(numScore);

					if (!PlayState.isPixelStage)
					{
						numScore.antialiasing = ClientPrefs.globalAntialiasing;
						numScore.setGraphicSize(Std.int(numScore.width * 0.5));
					}
					else
					{
						numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
					}
					numScore.updateHitbox();

					numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
					numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
					numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
					numScore.visible = !ClientPrefs.hideHud;

					if(showComboNum)
						insert(members.indexOf(strumLineNotes), numScore);

					FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
						onComplete: function(tween:FlxTween)
						{
							numScore.destroy();
						},
						startDelay: Conductor.crochet * 0.002 / playbackRate
					});
				}

				if (ClientPrefs.comboPopup && ClientPrefs.ratingType != 'Simple' && popUpsFrame <= 3)
				{
					final comboSpr = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
					comboSpr.cameras = (ClientPrefs.wrongCameras ? [camGame] : [camHUD]);
					comboSpr.screenCenter();
					comboSpr.x = offset;
					comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
					comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
					comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
					comboSpr.x += ClientPrefs.comboOffset[0];
					comboSpr.y -= ClientPrefs.comboOffset[1];
					comboSpr.y += 60;
					comboSpr.color = rating.color;
					comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
					if (ClientPrefs.comboPopup && !cpuControlled)
					{
						insert(members.indexOf(strumLineNotes), comboSpr);
					}
					comboSpr.x = offset + (43 * Std.string(combo).length) - 90 + 50;
					if (!ClientPrefs.comboStacking)
					{
						if (lastCombo != null)
						{
							FlxTween.cancelTweensOf(lastCombo);
							remove(lastCombo, true);
							lastCombo.destroy();
						}
							lastCombo = comboSpr;
					}
					if (!PlayState.isPixelStage)
					{
						comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
						comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
					}
					else
					{
						comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
					}
						comboSpr.updateHitbox();
					FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
						onComplete: function(tween:FlxTween)
						{
							comboSpr.destroy();
						},
						startDelay: Conductor.crochet * 0.002 / playbackRate
					});
				}

					FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
						startDelay: Conductor.crochet * 0.001 / playbackRate,
						onComplete: function(tween:FlxTween)
						{
							rating.destroy();
						}
					});
				}

				if (ClientPrefs.ratesAndCombo && ClientPrefs.showMS && !ClientPrefs.hideHud && popUpsFrame <= 3) {
					FlxTween.cancelTweensOf(msTxt);
					msTxt.cameras = (ClientPrefs.wrongCameras ? [camGame] : [camHUD]);
					msTxt.visible = true;
					msTxt.screenCenter();
					msTxt.x = (ClientPrefs.comboPopup ? offset + 280 : offset + 80);
					msTxt.alpha = 1;
					msTxt.text = FlxMath.roundDecimal(-noteDiff, 3) + " MS";
					if (cpuControlled && !ClientPrefs.communityGameBot) msTxt.text = "0 MS (Bot)";
					msTxt.x += ClientPrefs.comboOffset[0];
					msTxt.y -= ClientPrefs.comboOffset[1];
					if (combo >= 1000000) msTxt.x += 30;
					if (combo >= 100000) msTxt.x += 30;
					if (combo >= 10000) msTxt.x += 30;
					FlxTween.tween(msTxt,
						{y: msTxt.y + 8},
						0.1 / playbackRate,
						{onComplete: function(_){

								FlxTween.tween(msTxt, {alpha: 0}, 0.2 / playbackRate, {
									// ease: FlxEase.circOut,
									onComplete: function(_){msTxt.visible = false;},
									startDelay: Conductor.stepCrochet * 0.005 / playbackRate
								});
							}
						});
					switch (daRating.name) //This is so stupid, but it works
					{
					case 'perfect': msTxt.color = FlxColor.YELLOW;
					case 'sick':  msTxt.color = FlxColor.CYAN;
					case 'good': msTxt.color = FlxColor.LIME;
					case 'bad': msTxt.color = FlxColor.ORANGE;
					case 'shit': msTxt.color = FlxColor.RED;
					default: msTxt.color = FlxColor.WHITE;
					}
					if (miss) msTxt.color = FlxColor.fromRGB(204, 66, 66);
				}

				if (ClientPrefs.ratesAndCombo && ClientPrefs.ratingType == 'Simple' && popUpsFrame <= 3 && !ClientPrefs.hideHud) {
					FlxTween.cancelTweensOf(judgeTxt);
					FlxTween.cancelTweensOf(judgeTxt.scale);
					judgeTxt.cameras = (ClientPrefs.wrongCameras ? [camGame] : [camHUD]);
					judgeTxt.visible = true;
					judgeTxt.screenCenter(X);
					judgeTxt.y = !ClientPrefs.downScroll ? botplayTxt.y + 60 : botplayTxt.y - 60;
					judgeTxt.alpha = 1;
					if (!miss) switch (daRating.name)
					{
					case 'perfect':
						judgeTxt.color = FlxColor.YELLOW;
						judgeTxt.text = hitStrings[0] + '\n' + FlxStringUtil.formatMoney(combo, false);
					case 'sick':
						judgeTxt.color = FlxColor.CYAN;
						judgeTxt.text = hitStrings[1] + '\n' + FlxStringUtil.formatMoney(combo, false);
					case 'good':
						judgeTxt.color = FlxColor.LIME;
						judgeTxt.text = hitStrings[2] + '\n' + FlxStringUtil.formatMoney(combo, false);
					case 'bad':
						judgeTxt.color = FlxColor.ORANGE;
						judgeTxt.text = hitStrings[3] + '\n' + FlxStringUtil.formatMoney(combo, false);
					case 'shit':
						judgeTxt.color = FlxColor.RED;
						judgeTxt.text = hitStrings[4] + '\n' + FlxStringUtil.formatMoney(combo, false);
					default: judgeTxt.color = FlxColor.WHITE;
					}
					else
					{
						judgeTxt.color = FlxColor.fromRGB(204, 66, 66);
						judgeTxt.text = hitStrings[5] + '\n' + FlxStringUtil.formatMoney(combo, false);
					}
					judgeTxt.scale.x = 1.075;
					judgeTxt.scale.y = 1.075;
					FlxTween.tween(judgeTxt.scale,
						{x: 1, y: 1},
						0.1 / playbackRate,
						{onComplete: function(_){
								FlxTween.tween(judgeTxt.scale, {x: 0, y: 0}, 0.1 / playbackRate, {
									onComplete: function(_){judgeTxt.visible = false;},
									startDelay: Conductor.stepCrochet * 0.005 / playbackRate
								});
							}
						});
			}
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				if (ClientPrefs.songLoading) Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var hittableSpam = [];

				var sortedNotesList:Array<Note> = [];
				for (group in [notes, sustainNotes]) group.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								notes.remove(doubleNote, true);
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
						goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					if (sortedNotesList.length > 2 && ClientPrefs.ezSpam) //literally all you need to allow you to spam though impossiblely hard jacks
					{
						var notesThatCanBeHit = sortedNotesList.length;
						for (i in 1...Std.int(notesThatCanBeHit)) //i may consider making this hit half the notes instead
						{
							goodNoteHit(sortedNotesList[i]);
						}

					}
					}
				}
				else {
					callOnLuas('onGhostTap', [key]);
				if (!opponentChart && ClientPrefs.ghostTapAnim && ClientPrefs.charsAndBG)
				{
					boyfriend.playAnim(singAnimations[Std.int(Math.abs(key))], true);
					if (ClientPrefs.cameraPanning) camPanRoutine(singAnimations[Std.int(Math.abs(key))], 'bf');
					boyfriend.holdTimer = 0;
				}
				if (opponentChart && ClientPrefs.ghostTapAnim && ClientPrefs.charsAndBG)
				{
					dad.playAnim(singAnimations[Std.int(Math.abs(key))], true);
					if (ClientPrefs.cameraPanning) camPanRoutine(singAnimations[Std.int(Math.abs(key))], 'dad');
					dad.holdTimer = 0;
				}
					if (canMiss) {
						noteMissPress(key);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		var char:Character = boyfriend;
		if (opponentChart) char = dad;
		if (startedCountdown && !char.stunned && generatedMusic)
		{
			// rewritten inputs???
			for (group in [notes, sustainNotes]) group.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
				goodNoteHit(daNote);
				}
			});

			if(ClientPrefs.charsAndBG && FlxG.keys.anyJustPressed(tauntKey) && !char.animation.curAnim.name.endsWith('miss') && char.specialAnim == false && ClientPrefs.spaceVPose){
				char.playAnim('hey', true);
				char.specialAnim = true;
				char.heyTimer = 0.59;
				FlxG.sound.play(Paths.sound('hey'));
				trace("HEY!!");
				}

			if (parsedHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (ClientPrefs.charsAndBG && boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / playbackRate) * boyfriend.singDuration * singDurMult && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
			else if (ClientPrefs.charsAndBG && dad.holdTimer > Conductor.stepCrochet * (0.0011 / playbackRate) * dad.singDuration * singDurMult && dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss')) {
				dad.dance();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	public function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		if (combo > 0)
			combo = 0;
		else combo -= 1 * polyphony;
			comboMultiplier = 1; // Reset to 1 on a miss
		if (health > 0)
		{
			if (ClientPrefs.healthGainType != 'VS Impostor') {
				health -= daNote.missHealth * healthLoss;
			}
			else {
				missCombo += 1;
				health -= daNote.missHealth * missCombo;
			}
		}


		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses += 1 * polyphony;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10 * Std.int(polyphony);

		totalPlayed++;
		if (missRecalcsPerFrame <= 3) RecalculateRating(true);

		final char:Character = !daNote.gfNote ? !opponentChart ? boyfriend : dad : gf;
		if(daNote.gfNote) {
		}

		if(char != null && !daNote.noMissAnimation && char.hasMissAnimations && ClientPrefs.charsAndBG)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}
		if (!ClientPrefs.hideScore && scoreTxtUpdateFrame <= 4 && scoreTxt != null) updateScore();
		if (ClientPrefs.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();
		   	if (ClientPrefs.compactNumbers && compactUpdateFrame <= 4) updateCompactNumbers();

		daNote.tooLate = true;

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if (ClientPrefs.missRating) popUpScore(daNote, true);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.ghostTapping) return; //fuck it

		if (!boyfriend.stunned)
		{

			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;
		 	comboMultiplier = 1; // Reset to 1 on a miss

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			var char:Character = boyfriend;
			if (opponentChart) char = dad;
			if(char.hasMissAnimations) {
				char.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
		if (!ClientPrefs.hideScore && scoreTxtUpdateFrame <= 4 && scoreTxt != null) updateScore();
		if (ClientPrefs.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();
		   	if (ClientPrefs.compactNumbers && compactUpdateFrame <= 4) updateCompactNumbers();
		callOnLuas('noteMissPress', [direction]);
	}

	function goodNoteHit(note:Note):Void
	{
		if (opponentChart) {
			if (Paths.formatToSongPath(SONG.song) != 'tutorial' && !camZooming)
				camZooming = true;
		}
		if (!note.wasGoodHit)
		{
			if(!ffmpegMode && cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				hitsound.play(true);
				hitsound.pitch = playbackRate;
				if (hitSoundString == 'vine boom')
				{
					SPUNCHBOB = new FlxSprite().loadGraphic(Paths.image('sadsponge'));
				}
				if (hitSoundString == "i'm spongebob!")
				{
					SPUNCHBOB = new FlxSprite().loadGraphic(Paths.image('itspongebob'));
				}
					if (hitSoundString == "i'm spongebob!" || hitSoundString == 'vine boom')
					{
						SPUNCHBOB.antialiasing = ClientPrefs.globalAntialiasing;
						SPUNCHBOB.scrollFactor.set();
						SPUNCHBOB.setGraphicSize(Std.int(SPUNCHBOB.width / FlxG.camera.zoom));
						SPUNCHBOB.updateHitbox();
						SPUNCHBOB.screenCenter();
						SPUNCHBOB.alpha = 1;
						SPUNCHBOB.cameras = [camGame];
						add(SPUNCHBOB);
						FlxTween.tween(SPUNCHBOB, {alpha: 0}, 1 / (SONG.bpm/100) / playbackRate, {
							onComplete: function(tween:FlxTween)
							{
								SPUNCHBOB.destroy();
							}
						});
					}
			}

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(false, note, note.gfNote);
				}

				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					if (ClientPrefs.showNotes) notes.remove(note, true);
				}
				return;
			}
				if (ClientPrefs.comboScoreEffect && ClientPrefs.comboMultiType == 'Voiid Chronicles')
				{
					comboMultiplier = Math.fceil((combo+1)/10);
				}

				if (combo < 0) combo = 0;
				if (polyphony > 1 && !note.isSustainNote) totalNotes += polyphony - 1;
			if (!note.isSustainNote && !cpuControlled && !ClientPrefs.lessBotLag || !note.isSustainNote && cpuControlled && ClientPrefs.communityGameBot)
			{
				combo += 1 * polyphony;
				totalNotesPlayed += 1 * polyphony;
				missCombo = 0;
				if (ClientPrefs.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
				notesHitArray.push(1 * polyphony);
				notesHitDateArray.push(Conductor.songPosition);
				}
				popUpScore(note);
			}
			if (note.isSustainNote && !cpuControlled && ClientPrefs.holdNoteHits)
			{
				combo += 1 * polyphony;
				totalNotesPlayed += 1 * polyphony;
				missCombo = 0;
				popUpScore(note);
				if (polyphony > 1) totalNotes += polyphony - 1;
			}
			if (note.isSustainNote && cpuControlled && ClientPrefs.communityGameBot && ClientPrefs.holdNoteHits && !ClientPrefs.lessBotLag)
			{
				combo += 1 * polyphony;
				totalNotesPlayed += 1 * polyphony;
				missCombo = 0;
				popUpScore(note);
				if (polyphony > 1) totalNotes += polyphony - 1;
			}
			if (note.isSustainNote && cpuControlled && ClientPrefs.holdNoteHits && ClientPrefs.lessBotLag)
			{
				combo += 1 * polyphony;
				totalNotesPlayed += 1 * polyphony;
				if (!ClientPrefs.noMarvJudge)
				{
					songScore += 500 * comboMultiplier * polyphony;
				}
				else if (ClientPrefs.noMarvJudge)
				{
					songScore += 350 * comboMultiplier * polyphony;
				}
				missCombo = 0;
				if (polyphony > 1) totalNotes += polyphony - 1;
			}
			if (!note.isSustainNote && cpuControlled && ClientPrefs.lessBotLag && !ClientPrefs.communityGameBot)
			{
				combo += 1 * polyphony;
				if (!ClientPrefs.noMarvJudge)
				{
					songScore += 500 * comboMultiplier * polyphony;
				}
				else if (ClientPrefs.noMarvJudge)
				{
					songScore += 350 * comboMultiplier * polyphony;
				}
				totalNotesPlayed += 1 * polyphony;
				if (ClientPrefs.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
					notesHitArray.push(1 * polyphony);
					notesHitDateArray.push(Conductor.songPosition);
				}
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(false, note, note.gfNote);
				}
			}
			if (!note.isSustainNote && cpuControlled && !ClientPrefs.lessBotLag && !ClientPrefs.communityGameBot)
			{
				combo += 1 * polyphony;
				totalNotesPlayed += 1 * polyphony;
				missCombo = 0;
				if (ClientPrefs.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
					notesHitArray.push(1 * polyphony);
					notesHitDateArray.push(Conductor.songPosition);
				}
				popUpScore(note);
			}
			if (!note.isSustainNote && !cpuControlled && ClientPrefs.lessBotLag && !ClientPrefs.communityGameBot)
			{
				combo += 1 * polyphony;
				totalNotesPlayed += 1 * polyphony;
				missCombo = 0;
				if (ClientPrefs.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
					notesHitArray.push(1 * polyphony);
					notesHitDateArray.push(Conductor.songPosition);
				}
				final noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset) / playbackRate;
				final daRating:Rating = Conductor.judgeNote(note, noteDiff);

				totalNotesHit += daRating.ratingMod;
				note.ratingMod = daRating.ratingMod;
				if(!note.ratingDisabled) daRating.increase();
				note.rating = daRating.name;
				songScore += daRating.score * comboMultiplier * polyphony;
				totalPlayed++;
				if(daRating.noteSplash && !note.noteSplashDisabled)
				{
					spawnNoteSplashOnNote(false, note, note.gfNote);
				}
				RecalculateRating();
			}
			if (note.isSustainNote && cpuControlled && !ClientPrefs.lessBotLag && !ClientPrefs.communityGameBot && ClientPrefs.holdNoteHits)
			{
				combo += 1 * polyphony;
				totalNotesPlayed += 1 * polyphony;
				missCombo = 0;
				if (ClientPrefs.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
					notesHitArray.push(1 * polyphony);
					notesHitDateArray.push(Conductor.songPosition);
				}
				popUpScore(note);
				if (polyphony > 1) totalNotes += polyphony - 1;
			}

			if (combo > maxCombo)
				maxCombo = combo;

			if (ClientPrefs.healthGainType == 'Psych Engine' || ClientPrefs.healthGainType == 'Leather Engine' || ClientPrefs.healthGainType == 'Kade (1.2)' || ClientPrefs.healthGainType == 'Kade (1.6+)' || ClientPrefs.healthGainType == 'Doki Doki+' || ClientPrefs.healthGainType == 'VS Impostor') {
				health += note.hitHealth * healthGain * polyphony;
			}
			if(!note.noAnimation && ClientPrefs.charsAndBG && charAnimsFrame < 4) {
				charAnimsFrame += 1;
				final animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];
				if(note.gfNote)
				{
					if(gf != null)
					{
					if (!ClientPrefs.doubleGhost) {
						gf.playAnim(animToPlay + note.animSuffix, true);
					}
						gf.holdTimer = 0;
					if (ClientPrefs.doubleGhost)
					{
						if (!note.isSustainNote && noteRows[note.mustPress?0:1][note.row].length > 1)
							{
								// potentially have jump anims?
								final chord = noteRows[note.mustPress?0:1][note.row];
								final animNote = chord[0];
								final realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))];
								if (gf.mostRecentRow != note.row)
								{
									gf.playAnim(realAnim, true);
								}

								gf.mostRecentRow = note.row;
								doGhostAnim('gf', animToPlay);
								gfGhost.color = FlxColor.fromRGB(gf.healthColorArray[0] + 50, gf.healthColorArray[1] + 50, gf.healthColorArray[2] + 50);
								gfGhostTween = FlxTween.tween(gfGhost, {alpha: 0}, 0.75, {
									ease: FlxEase.linear,
									onComplete: function(twn:FlxTween)
									{
										gfGhostTween = null;
									}
								});
							}
							else{
								gf.playAnim(animToPlay + note.animSuffix, true);
								gf.holdTimer = 0;
							}
						}
					}
				}
				if (!opponentChart && !note.gfNote && ClientPrefs.charsAndBG)
				{
					if (!ClientPrefs.doubleGhost) {
						boyfriend.playAnim(animToPlay + note.animSuffix, true);
					}
					if (ClientPrefs.cameraPanning) camPanRoutine(animToPlay, 'bf');
					boyfriend.holdTimer = 0;
					if (ClientPrefs.doubleGhost)
					{
					if (!note.isSustainNote && noteRows[note.mustPress?0:1][note.row].length > 1)
						{
							// potentially have jump anims?
							final chord = noteRows[note.mustPress?0:1][note.row];
							final animNote = chord[0];
							final realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))];
							if (boyfriend.mostRecentRow != note.row)
							{
								boyfriend.playAnim(realAnim, true);
							}

							boyfriend.mostRecentRow = note.row;
							doGhostAnim('bf', animToPlay);
						}
						else{
							boyfriend.playAnim(animToPlay + note.animSuffix, true);
							// dad.angle = 0;
						}
					}
				}
				if (opponentChart && !note.gfNote && ClientPrefs.charsAndBG)
				{
					if (!ClientPrefs.doubleGhost) {
					dad.playAnim(animToPlay, true);
					}
					dad.holdTimer = 0;
					if (ClientPrefs.cameraPanning) camPanRoutine(animToPlay, 'oppt');
					if (ClientPrefs.doubleGhost)
						{
						if (!note.isSustainNote && noteRows[note.mustPress?0:1][note.row].length > 1)
							{
								// potentially have jump anims?
								final chord = noteRows[note.mustPress?0:1][note.row];
								final animNote = chord[0];
								final realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))];
								if (dad.mostRecentRow != note.row)
								{
									dad.playAnim(realAnim, true);
								}

										if (!note.noAnimation && !note.gfNote)
										{
											if(dad.mostRecentRow != note.row)
												doGhostAnim('dad', animToPlay);
												dadGhost.color = FlxColor.fromRGB(dad.healthColorArray[0] + 50, dad.healthColorArray[1] + 50, dad.healthColorArray[2] + 50);
												dadGhostTween = FlxTween.tween(dadGhost, {alpha: 0}, 0.75, {
													ease: FlxEase.linear,
													onComplete: function(twn:FlxTween)
													{
														dadGhostTween = null;
													}
												});
										}
										dad.mostRecentRow = note.row;
							}
							else{
								dad.playAnim(animToPlay + note.animSuffix, true);
								// dad.angle = 0;
							}
						}
				}

				if(note.noteType == 'Hey!') {
					final char:Character = !note.gfNote ? !opponentChart ? boyfriend : dad : gf;
					if(char.animOffsets.exists('hey')) {
						char.playAnim('hey', true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				if (ClientPrefs.botLightStrum && strumAnimsPerFrame[1] < 4)
				{
					strumAnimsPerFrame[1] += 1;
					var time:Float = 0;

					if (ClientPrefs.strumLitStyle == 'Full Anim' && !ClientPrefs.communityGameBot) time = 0.15 / playbackRate;
					if (ClientPrefs.strumLitStyle == 'BPM Based' && !ClientPrefs.communityGameBot) time = (Conductor.stepCrochet * 1.5 / 1000) / playbackRate;
					if (ClientPrefs.communityGameBot) time = (!ClientPrefs.communityGameBot ? 0.15 : FlxG.random.float(0.05, 0.15)) / playbackRate;
					if(note.isSustainNote && (ClientPrefs.showNotes && !note.animation.curAnim.name.endsWith('end'))) {
						if (ClientPrefs.strumLitStyle == 'Full Anim' && !ClientPrefs.communityGameBot) time += 0.15 / playbackRate;
						if (ClientPrefs.strumLitStyle == 'BPM Based' && !ClientPrefs.communityGameBot) time += (Conductor.stepCrochet * 1.5 / 1000) / playbackRate;
						if (ClientPrefs.communityGameBot) time += (!ClientPrefs.communityGameBot ? 0.15 : FlxG.random.float(0.05, 0.15)) / playbackRate;
					}
					final spr:StrumNote = playerStrums.members[note.noteData];

					if(spr != null) {
						if ((ClientPrefs.noteColorStyle == 'Quant-Based' || ClientPrefs.noteColorStyle == 'Rainbow') && ClientPrefs.showNotes && ClientPrefs.enableColorShader) {
							spr.playAnim('confirm', true, note.colorSwap.hue, note.colorSwap.saturation, note.colorSwap.brightness);
						} else {
							spr.playAnim('confirm', true, 0, 0, 0, ClientPrefs.noteColorStyle == 'Char-Based', note.mustPress, note.gfNote);
						}
						spr.resetAnim = time;
					}
				}
			} else if (ClientPrefs.playerLightStrum) {
				final spr = playerStrums.members[note.noteData];
				if(spr != null)
				{
					if ((ClientPrefs.noteColorStyle == 'Quant-Based' || ClientPrefs.noteColorStyle == 'Rainbow') && ClientPrefs.showNotes && ClientPrefs.enableColorShader) {
						spr.playAnim('confirm', true, note.colorSwap.hue, note.colorSwap.saturation, note.colorSwap.brightness);
					} else {
						spr.playAnim('confirm', true, 0, 0, 0, ClientPrefs.noteColorStyle == 'Char-Based', note.mustPress, note.gfNote);
					}
				}
			}
			note.wasGoodHit = true;
			if (ClientPrefs.songLoading && !ffmpegMode) vocals.volume = 1;

			final isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			final leData:Int = Math.round(Math.abs(note.noteData));
			final leType:String = note.noteType;

			callOnLuas('goodNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
			callOnLuas((opponentChart ? 'opponentNoteHitFix' : 'goodNoteHitFix'), [notes.members.indexOf(note), leData, leType, isSus]);

				if (ClientPrefs.showNotes) notes.remove(note, true);
			if (ClientPrefs.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();
			if (!ClientPrefs.hideScore && scoreTxtUpdateFrame <= 4) updateScore();
		   		if (ClientPrefs.compactNumbers && compactUpdateFrame <= 4) updateCompactNumbers();
			if (ClientPrefs.iconBopWhen == 'Every Note Hit' && iconBopsThisFrame <= 2 && !note.isSustainNote && iconP1.visible) bopIcons(!opponentChart);
		}
	}
	function opponentNoteHit(daNote:Note):Void
	{
			if (!opponentChart) {
				if (Paths.formatToSongPath(SONG.song) != 'tutorial' && !camZooming)
					camZooming = true;
			}

			if(daNote.noteType == 'Hey!')
			{
				final char:Character = !daNote.gfNote ? !opponentChart ? dad : boyfriend : gf;
				if (char.animOffsets.exists('hey')) {
					char.playAnim('hey', true);
					char.specialAnim = true;
					char.heyTimer = 0.6;
				}
			} else if(!daNote.noAnimation && oppAnimsFrame < 4) {
				oppAnimsFrame += 1;

				final altAnim:String = (SONG.notes[curSection] != null && SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection && !opponentChart) ? '-alt' : daNote.animSuffix;

				final animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + altAnim;
				if(daNote.gfNote && ClientPrefs.charsAndBG) {
						if (ClientPrefs.doubleGhost && gf != null)
						{
						if (!daNote.isSustainNote && noteRows[daNote.mustPress?0:1][daNote.row].length > 1)
							{
								// potentially have jump anims?
								final chord = noteRows[daNote.mustPress?0:1][daNote.row];
								final animNote = chord[0];
								final realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))];
								if (gf.mostRecentRow != daNote.row)
								{
									gf.playAnim(realAnim, true);
								}

								gf.mostRecentRow = daNote.row;
								doGhostAnim('gf', animToPlay);
								}
							}
							else if (gf != null) {
								gf.playAnim(animToPlay + daNote.animSuffix, true);
								gf.holdTimer = 0;
							}
				}
				if(opponentChart && ClientPrefs.charsAndBG && !daNote.gfNote) {
					boyfriend.playAnim(animToPlay, true);
					boyfriend.holdTimer = 0;
				}
				else if(dad != null && !opponentChart && ClientPrefs.charsAndBG && !daNote.gfNote)
				{
						dad.playAnim(animToPlay, true);
						dad.holdTimer = 0;
						if (ClientPrefs.cameraPanning) camPanRoutine(animToPlay, 'oppt');
						if (ClientPrefs.doubleGhost)
						{
						if (!daNote.isSustainNote && noteRows[daNote.mustPress?0:1][daNote.row].length > 1)
							{
								// potentially have jump anims?
								final chord = noteRows[daNote.mustPress?0:1][daNote.row];
								final animNote = chord[0];
								final realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))];
								if (dad.mostRecentRow != daNote.row)
								{
									dad.playAnim(realAnim, true);
								}

									if (!daNote.noAnimation && !daNote.gfNote)
									{
										if(dad.mostRecentRow != daNote.row)
											doGhostAnim('dad', animToPlay + altAnim);
											dadGhost.color = FlxColor.fromRGB(dad.healthColorArray[0] + 50, dad.healthColorArray[1] + 50, dad.healthColorArray[2] + 50);
											dadGhostTween = FlxTween.tween(dadGhost, {alpha: 0}, 0.75, {
												ease: FlxEase.linear,
												onComplete: function(twn:FlxTween)
												{
													dadGhostTween = null;
												}
											});
									}
									dad.mostRecentRow = daNote.row;
								}
							}
							else{
								dad.playAnim(animToPlay + daNote.animSuffix, true);
								// dad.angle = 0;
							}
				}
					if (opponentChart && ClientPrefs.charsAndBG && !daNote.gfNote)
					{
						boyfriend.playAnim(animToPlay + daNote.animSuffix, true);
						boyfriend.holdTimer = 0;
						if (ClientPrefs.cameraPanning) camPanRoutine(animToPlay, 'bf');
						if (ClientPrefs.doubleGhost)
						{
						if (!daNote.isSustainNote && noteRows[daNote.mustPress?0:1][daNote.row].length > 1)
							{
								// potentially have jump anims?
								final chord = noteRows[daNote.mustPress?0:1][daNote.row];
								final animNote = chord[0];
								final realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))];
								if (boyfriend.mostRecentRow != daNote.row)
								{
									boyfriend.playAnim(realAnim, true);
								}

								boyfriend.mostRecentRow = daNote.row;
								doGhostAnim('bf', animToPlay);
							}
							else{
								boyfriend.playAnim(animToPlay + daNote.animSuffix, true);
							}
						}
					}
		}

			if(ClientPrefs.oppNoteSplashes && !daNote.isSustainNote)
			{
				spawnNoteSplashOnNote(true, daNote, daNote.gfNote);
			}

			if (SONG.needsVoices && !ffmpegMode)
				vocals.volume = 1;

				if (polyphony > 1 && !daNote.isSustainNote) opponentNoteTotal += polyphony - 1;

			if (ClientPrefs.opponentLightStrum && strumAnimsPerFrame[0] < 4)
			{
				strumAnimsPerFrame[0] += 1;
				var time:Float = 0;
				if (ClientPrefs.strumLitStyle == 'Full Anim') time = 0.15 / playbackRate;
				if (ClientPrefs.strumLitStyle == 'BPM Based') time = (Conductor.stepCrochet * 1.5 / 1000) / playbackRate;

				if(daNote.isSustainNote && (ClientPrefs.showNotes && !daNote.animation.curAnim.name.endsWith('end'))) {
					if (ClientPrefs.strumLitStyle == 'Full Anim') time += 0.15 / playbackRate;
					if (ClientPrefs.strumLitStyle == 'BPM Based') time += (Conductor.stepCrochet * 1.5 / 1000) / playbackRate;
				}
					final spr:StrumNote = opponentStrums.members[daNote.noteData];

				if(spr != null) {
					if ((ClientPrefs.noteColorStyle == 'Quant-Based' || ClientPrefs.noteColorStyle == 'Rainbow') && ClientPrefs.showNotes && ClientPrefs.enableColorShader) {
						spr.playAnim('confirm', true, daNote.colorSwap.hue, daNote.colorSwap.saturation, daNote.colorSwap.brightness);
					} else {
						spr.playAnim('confirm', true, 0, 0, 0, ClientPrefs.noteColorStyle == 'Char-Based', false, daNote.gfNote);
					}
					spr.resetAnim = time;
				}
			}
			daNote.hitByOpponent = true;


			callOnLuas('opponentNoteHit', [notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);
			callOnLuas((opponentChart ? 'goodNoteHitFix' : 'opponentNoteHitFix'), [notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);

			if (!daNote.isSustainNote)
			{
				if (ClientPrefs.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
					oppNotesHitArray.push(1 * polyphony);
					oppNotesHitDateArray.push(Conductor.songPosition);
				}
				enemyHits += 1 * polyphony;
				if (ClientPrefs.showNotes) notes.remove(daNote, true);
			}
			if (ClientPrefs.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();
			if (!ClientPrefs.hideScore && scoreTxtUpdateFrame <= 4) updateScore();
		   		if (ClientPrefs.compactNumbers && compactUpdateFrame <= 4) updateCompactNumbers();
			if (shouldDrainHealth && health > healthDrainFloor && !practiceMode || opponentDrain && practiceMode) {
				health -= (opponentDrain ? daNote.hitHealth : healthDrainAmount) * hpDrainLevel * polyphony;
				if (ClientPrefs.healthDisplay && !ClientPrefs.hideScore && scoreTxtUpdateFrame <= 4 && scoreTxt != null) updateScore();
			}

			if (ClientPrefs.denpaDrainBug) displayedHealth -= daNote.hitHealth * hpDrainLevel * polyphony;
			if (ClientPrefs.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();
		   		if (ClientPrefs.compactNumbers && compactUpdateFrame <= 4) updateCompactNumbers();
			if (ClientPrefs.iconBopWhen == 'Every Note Hit' && iconBopsThisFrame <= 2 && !daNote.isSustainNote && iconP2.visible) bopIcons(opponentChart);
		}


	public function spawnNoteSplashOnNote(isDad:Bool, note:Note, ?isGf:Bool = false) {
		if(ClientPrefs.noteSplashes && note != null) {
			final strum:StrumNote = !isDad ? playerStrums.members[note.noteData] : opponentStrums.members[note.noteData];
			if(strum != null) {
				ClientPrefs.showNotes && ClientPrefs.enableColorShader ? spawnNoteSplash(strum.x, strum.y, note.noteData, null, note.colorSwap.hue, note.colorSwap.saturation, note.colorSwap.brightness, isGf, isDad) : spawnNoteSplash(strum.x, strum.y, note.noteData, null, 0, 0, 0, isGf, isDad);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null, ?hue:Float = 0, ?sat:Float = 0, ?brt:Float = 0, ?isGfNote:Bool = false, ?isDadNote:Bool = true) {
		var skin:String = (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) ? PlayState.SONG.splashSkin : 'noteSplashes';

		if (data > -1 && data < ClientPrefs.arrowHSV.length)
		{
			if (ClientPrefs.noteColorStyle == 'Normal')
			{
				hue = ClientPrefs.arrowHSV[data][0] / 360;
				sat = ClientPrefs.arrowHSV[data][1] / 100;
				brt = ClientPrefs.arrowHSV[data][2] / 100;
			}
			if(note != null && ClientPrefs.noteColorStyle == 'Normal') {
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splashColor:FlxColor = !opponentChart ? FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]) : FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);

		if (ClientPrefs.noteColorStyle == 'Char-Based')
		{
			if (!isDadNote) splashColor = !opponentChart ? FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]) : FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			if (isGfNote && gf != null) splashColor = FlxColor.fromRGB(gf.healthColorArray[0], gf.healthColorArray[1], gf.healthColorArray[2]);
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt, splashColor);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if(gf != null)
		{
			gf.danced = false; //Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if(!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	override function destroy() {
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];

		camFollow.put();
		strumLine.put();

		#if hscript
		if(FunkinLua.hscript != null) FunkinLua.hscript = null;
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxG.animationTimeScale = 1;
		FlxG.sound.music.pitch = 1;
		cpp.vm.Gc.enable(true);
		KillNotes();
		MusicBeatState.windowNamePrefix = Assets.getText(Paths.txt("windowTitleBase", "preload"));
		if(ffmpegMode) {

			if (FlxG.fixedTimestep) {
				FlxG.fixedTimestep = false;
				FlxG.animationTimeScale = 1;
			}
		}

		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();

		if (tankmanAscend)
		{
			if (curStep >= 896 && curStep <= 1152) moveCameraSection();
			switch (curStep)
			{
				case 896:
					{
						if (!opponentChart) {
						opponentStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
						FlxTween.tween(EngineWatermark, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(timeBar, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(judgementCounter, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(scoreTxt, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(healthBar, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(healthBarBG, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(iconP1, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(iconP2, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(timeTxt, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						dad.velocity.y = -35;
					}
				case 906:
					{
						if (!opponentChart) {
						playerStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						});
						} else {
						opponentStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
					}
				case 1020:
					{
						if (!opponentChart) {
						playerStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
					}
				case 1024:
						if (opponentChart) {
						playerStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
					dad.velocity.y = 0;
					boyfriend.velocity.y = -33.5;
				case 1148:
					{
						if (opponentChart) {
						playerStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
					}
				case 1151:
					cameraSpeed = 100;
				case 1152:
					{
						FlxG.camera.flash(FlxColor.WHITE, 1);
						opponentStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						});
						FlxTween.tween(EngineWatermark, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(judgementCounter, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(healthBar, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(healthBarBG, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(scoreTxt, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(iconP1, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(iconP2, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						dad.x = 100;
						dad.y = 280;
						boyfriend.x = 810;
						boyfriend.y = 450;
						dad.velocity.y = 0;
						boyfriend.velocity.y = 0;
					}
				case 1153:
					cameraSpeed = 1;
			}
		}
		final gamerValue = 20 * playbackRate;
		if (!ffmpegMode && !ClientPrefs.noSyncing && ClientPrefs.songLoading && playbackRate < 256) //much better resync code, doesn't just resync every step!!
		{
			if (FlxG.sound.music.time > Conductor.songPosition + gamerValue
				|| FlxG.sound.music.time < Conductor.songPosition - gamerValue
				|| FlxG.sound.music.time < 500 && ClientPrefs.startingSync)
			{
				resyncVocals();
			}
		}

		if(curStep == lastStepHit) {
			return;
		}

		if (camTwist)
		{
			if (curStep % (gfSpeed * 4) == 0)
			{
				FlxTween.tween(camHUD, {y: -6 * camTwistIntensity2}, Conductor.stepCrochet * (0.002 * gfSpeed), {ease: FlxEase.circOut});
				FlxTween.tween(camGame.scroll, {y: 12}, Conductor.stepCrochet * (0.002 * gfSpeed), {ease: FlxEase.sineIn});
			}

			if (curStep % (gfSpeed * 4) == 2)
			{
				FlxTween.tween(camHUD, {y: 0}, Conductor.stepCrochet * (0.002 * gfSpeed), {ease: FlxEase.sineIn});
				FlxTween.tween(camGame.scroll, {y: 0}, Conductor.stepCrochet * (0.002 * gfSpeed), {ease: FlxEase.sineIn});
			}
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if(ClientPrefs.timeBounce)
		{
			if(timeTxtTween != null) {
				timeTxtTween.cancel();
			}
			timeTxt.scale.x = 1.075;
			timeTxt.scale.y = 1.075;
			timeTxtTween = FlxTween.tween(timeTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					timeTxtTween = null;
				}
			});
		}

		if (curBeat % 32 == 0 && randomSpeedThing)
		{
			var randomShit = FlxMath.roundDecimal(FlxG.random.float(0.4, 3), 2);
			lerpSongSpeed(randomShit, 1);
		}
		if (camZooming && !endingSong && !startingSong && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % camBopInterval == 0)
		{
			FlxG.camera.zoom += 0.015 * camBopIntensity;
			camHUD.zoom += 0.03 * camBopIntensity;
		} /// WOOO YOU CAN NOW MAKE IT AWESOME

		if (camTwist)
		{
			if (curBeat % (gfSpeed * 2) == 0)
			{
				twistShit = twistAmount;
			}
			if (curBeat % (gfSpeed * 2) == 2)
			{
				twistShit = -twistAmount;
			}
			camHUD.angle = twistShit * camTwistIntensity2;
			camGame.angle = twistShit * camTwistIntensity2;
			FlxTween.tween(camHUD, {angle: twistShit * camTwistIntensity}, Conductor.stepCrochet * (0.002 * gfSpeed), {ease: FlxEase.circOut});
			FlxTween.tween(camHUD, {x: -twistShit * camTwistIntensity}, Conductor.crochet * (0.001 * gfSpeed), {ease: FlxEase.linear});
			FlxTween.tween(camGame, {angle: twistShit * camTwistIntensity}, Conductor.stepCrochet * 0.002, {ease: FlxEase.circOut});
			FlxTween.tween(camGame, {x: -twistShit * camTwistIntensity}, Conductor.crochet * (0.001 * gfSpeed), {ease: FlxEase.linear});
		}

		if (ClientPrefs.iconBopWhen == 'Every Beat' && (iconP1.visible || iconP2.visible)) bopIcons();

		if (ClientPrefs.charsAndBG) {
		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}

		switch (curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});

			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (ClientPrefs.hudType == 'Leather Engine') timeBar.color = SONG.notes[curSection].mustHitSection ? FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]) : FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
				if (Conductor.bpm >= 500) singDurMult = gfSpeed;
				else singDurMult = 1;
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}

		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}

	public function bopIcons(?bopBF:Bool = false)
	{
		iconBopsThisFrame++;
		if (ClientPrefs.iconBopWhen == 'Every Beat')
		{
		if (ClientPrefs.iconBounceType == 'Dave and Bambi') {
		final funny:Float = Math.max(Math.min(healthBar.value,(maxHealth/0.95)),0.1);

		//health icon bounce but epic
		if (!opponentChart)
		{
			iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (funny + 0.1))),Std.int(iconP1.height - (25 * funny)));
			iconP2.setGraphicSize(Std.int(iconP2.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP2.height - (25 * ((2 - funny) + 0.1))));
		} else {
			iconP2.setGraphicSize(Std.int(iconP2.width + (50 * funny)),Std.int(iconP2.height - (25 * funny)));
			iconP1.setGraphicSize(Std.int(iconP1.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP1.height - (25 * ((2 - funny) + 0.1))));
			}
		}
		if (ClientPrefs.iconBounceType == 'Old Psych') {
		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));
		}
		if (ClientPrefs.iconBounceType == 'Strident Crisis') {
		final funny:Float = (healthBar.percent * 0.01) + 0.01;

		//health icon bounce but epic
		iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (2 + funny))),Std.int(iconP2.height - (25 * (2 + funny))));
		iconP2.setGraphicSize(Std.int(iconP2.width + (50 * (2 - funny))),Std.int(iconP2.height - (25 * (2 - funny))));

		iconP1.scale.set(1.1, 0.8);
		iconP2.scale.set(1.1, 0.8);

		FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
		FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});

		FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
		FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});

		iconP1.updateHitbox();
		iconP2.updateHitbox();
		}
		if (ClientPrefs.iconBounceType == 'Plank Engine') {
		iconP1.scale.x = 1.3;
		iconP1.scale.y = 0.75;
		iconP2.scale.x = 1.3;
		iconP2.scale.y = 0.75;
		FlxTween.cancelTweensOf(iconP1);
		FlxTween.cancelTweensOf(iconP2);
		FlxTween.tween(iconP1, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000, {ease: FlxEase.backOut});
		FlxTween.tween(iconP2, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000, {ease: FlxEase.backOut});
		if (curBeat % 4 == 0) {
			iconP1.offset.x = 10;
			iconP2.offset.x = -10;
			iconP1.angle = -15;
			iconP2.angle = 15;
			FlxTween.tween(iconP1, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000, {ease: FlxEase.expoOut});
			FlxTween.tween(iconP2, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000, {ease: FlxEase.expoOut});
		}
		}
		if (ClientPrefs.iconBounceType == 'New Psych') {
		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);
		}
		//you're welcome Stefan2008 :)
		if (ClientPrefs.iconBounceType == 'SB Engine') {
			if (curBeat % gfSpeed == 0) {
				if (curBeat % (gfSpeed * 2) == 0) {
					iconP1.scale.set(0.8, 0.8);
					iconP2.scale.set(1.2, 1.3);

					iconP1.angle = -15;
					iconP2.angle = 15;
				} else {
					iconP2.scale.set(0.8, 0.8);
					iconP1.scale.set(1.2, 1.3);

					iconP2.angle = -15;
					iconP1.angle = 15;
				}
			}
		}

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0 && ClientPrefs.iconBounceType == 'Golden Apple') {
		curBeat % (gfSpeed * 2) == 0 * playbackRate ? {
		iconP1.scale.set(1.1, 0.8);
		iconP2.scale.set(1.1, 1.3);

		FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 / playbackRate, {ease: FlxEase.quadOut});
		FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 / playbackRate, {ease: FlxEase.quadOut});
		} : {
		iconP1.scale.set(1.1, 1.3);
		iconP2.scale.set(1.1, 0.8);

		FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 / playbackRate, {ease: FlxEase.quadOut});
		FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 / playbackRate, {ease: FlxEase.quadOut});
		}

		FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
		FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});

		iconP1.updateHitbox();
		iconP2.updateHitbox();
		}
		if (ClientPrefs.iconBounceType == 'VS Steve') {
		if (curBeat % gfSpeed == 0)
			{
			curBeat % (gfSpeed * 2) == 0 ?
			{
				iconP1.scale.set(1.1, 0.8);
				iconP2.scale.set(1.1, 1.3);
				//FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				//FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
			}
			:
			{
				iconP1.scale.set(1.1, 1.3);
				iconP2.scale.set(1.1, 0.8);
				FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});

			}

			FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
			FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}
		}
		}
		else if (ClientPrefs.iconBopWhen == 'Every Note Hit')
		{
		iconBopsTotal++;
		if (ClientPrefs.iconBounceType == 'Dave and Bambi') {
		final funny:Float = Math.max(Math.min(healthBar.value,(maxHealth/0.95)),0.1);

		//health icon bounce but epic
		if (!opponentChart)
		{
			if (bopBF) iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (funny + 0.1))),Std.int(iconP1.height - (25 * funny)));
			iconP2.setGraphicSize(Std.int(iconP2.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP2.height - (25 * ((2 - funny) + 0.1))));
		} else {
			if (!bopBF) iconP2.setGraphicSize(Std.int(iconP2.width + (50 * funny)),Std.int(iconP2.height - (25 * funny)));
			else iconP1.setGraphicSize(Std.int(iconP1.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP1.height - (25 * ((2 - funny) + 0.1))));
			}
		}
		if (ClientPrefs.iconBounceType == 'Old Psych') {
		if (bopBF) iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		else iconP2.setGraphicSize(Std.int(iconP2.width + 30));
		}
		if (ClientPrefs.iconBounceType == 'Strident Crisis') {
		final funny:Float = (healthBar.percent * 0.01) + 0.01;

		//health icon bounce but epic
		iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (2 + funny))),Std.int(iconP2.height - (25 * (2 + funny))));
		iconP1.scale.set(1.1, 0.8);
		iconP2.setGraphicSize(Std.int(iconP2.width + (50 * (2 - funny))),Std.int(iconP2.height - (25 * (2 - funny))));

		iconP2.scale.set(1.1, 0.8);

		FlxTween.cancelTweensOf(iconP1);
		FlxTween.cancelTweensOf(iconP2);

		FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
		FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});

		FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
		FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});

		iconP1.updateHitbox();
		iconP2.updateHitbox();
		}
		if (ClientPrefs.iconBounceType == 'Plank Engine') {
		iconP1.scale.x = 1.3;
		iconP1.scale.y = 0.75;
		FlxTween.cancelTweensOf(iconP1);
		FlxTween.tween(iconP1, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000, {ease: FlxEase.backOut});
		iconP2.scale.x = 1.3;
		iconP2.scale.y = 0.75;
		FlxTween.cancelTweensOf(iconP2);
		FlxTween.tween(iconP2, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000, {ease: FlxEase.backOut});
		if (iconBopsTotal % 4 == 0) {
			iconP1.offset.x = 10;
			iconP1.angle = -15;
			FlxTween.tween(iconP1, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000, {ease: FlxEase.expoOut});
			iconP2.offset.x = -10;
			iconP2.angle = 15;
			FlxTween.tween(iconP2, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000, {ease: FlxEase.expoOut});
		}
		}
		if (ClientPrefs.iconBounceType == 'New Psych') {
		if (bopBF) iconP1.scale.set(1.2, 1.2);
		else iconP2.scale.set(1.2, 1.2);
		}
		//you're welcome Stefan2008 :)
		if (ClientPrefs.iconBounceType == 'SB Engine') {
			if (iconBopsTotal % 2 == 0) {
				if (iconBopsTotal % 2 == 0) {
					iconP1.scale.set(0.8, 0.8);
					iconP2.scale.set(1.2, 1.3);

					iconP1.angle = -15;
					iconP2.angle = 15;
				} else {
					iconP2.scale.set(0.8, 0.8);
					iconP1.scale.set(1.2, 1.3);

					iconP2.angle = -15;
					iconP1.angle = 15;
				}
			}
		}

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (ClientPrefs.iconBounceType == 'Golden Apple') {
		FlxTween.cancelTweensOf(iconP1);
		FlxTween.cancelTweensOf(iconP2);
		iconBopsTotal % 2 == 0 * playbackRate ? {
		iconP1.scale.set(1.1, 0.8);
		iconP2.scale.set(1.1, 1.3);

		FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 / playbackRate, {ease: FlxEase.quadOut});
		FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 / playbackRate, {ease: FlxEase.quadOut});
		} : {
		iconP1.scale.set(1.1, 1.3);
		iconP2.scale.set(1.1, 0.8);

		FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 / playbackRate, {ease: FlxEase.quadOut});
		FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 / playbackRate, {ease: FlxEase.quadOut});
		}

		FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
		FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});

		iconP1.updateHitbox();
		iconP2.updateHitbox();
		}
		if (ClientPrefs.iconBounceType == 'VS Steve') {
		FlxTween.cancelTweensOf(iconP1);
		FlxTween.cancelTweensOf(iconP2);
		if (iconBopsTotal % 2 == 0)
			{
			iconBopsTotal % 2 == 0 ?
			{
				iconP1.scale.set(1.1, 0.8);
				iconP2.scale.set(1.1, 1.3);
				//FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				//FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
			}
			:
			{
				iconP1.scale.set(1.1, 1.3);
				iconP2.scale.set(1.1, 0.8);
				FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});

			}

			FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
			FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}
		}
		}
	}

	#if LUA_ALLOWED
	public function startLuasOnFolder(luaFile:String)
	{
		for (script in luaArray)
		{
			if(script.scriptName == luaFile) return false;
		}

		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(luaToLoad))
		{
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		else
		{
			luaToLoad = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
				return true;
			}
		}
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		{
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		#end
		return false;
	}
	#end

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var myValue = script.call(event, args);
			if(myValue == FunkinLua.Function_StopLua && !ignoreStops)
				break;

			if(myValue != null && myValue != FunkinLua.Function_Continue) {
				returnVal = myValue;
			}
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = isDad ? opponentStrums.members[id] : playerStrums.members[id];

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public function updateRatingCounter() {
		judgeCountUpdateFrame++;
		if (!judgementCounter.visible) return;

		formattedSongMisses = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(songMisses, false) : compactMisses;
		formattedCombo = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(combo, false) : compactCombo;
		formattedMaxCombo = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(maxCombo, false) : compactMaxCombo;
		formattedNPS = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(nps, false) : compactNPS;
		formattedMaxNPS = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(maxNPS, false) : formatCompactNumber(maxNPS);
		formattedOppNPS = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(oppNPS, false) : formatCompactNumber(oppNPS);
		formattedMaxOppNPS = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(maxOppNPS, false) : formatCompactNumber(maxOppNPS);
		formattedEnemyHits = !ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(enemyHits, false) : formatCompactNumber(enemyHits);

		final hittingStuff = (!ClientPrefs.lessBotLag ? 'Combo (Max): $formattedCombo ($formattedMaxCombo)\n' : '') + 'Hits: ' + (!ClientPrefs.compactNumbers ? FlxStringUtil.formatMoney(totalNotesPlayed, false) : compactTotalPlays) + ' / ' + FlxStringUtil.formatMoney(totalNotes, false) + ' (' + FlxMath.roundDecimal((totalNotesPlayed/totalNotes) * 100, 2) + '%)';
		final ratingCountString = (!cpuControlled || cpuControlled && !ClientPrefs.lessBotLag ? '\n' + (!ClientPrefs.noMarvJudge ? judgeCountStrings[0] + '!!!: $perfects \n' : '') + judgeCountStrings[1] + '!!: $sicks \n' + judgeCountStrings[2] + '!: $goods \n' + judgeCountStrings[3] + ': $bads \n' + judgeCountStrings[4] + ': $shits \n' + judgeCountStrings[5] + ': $formattedSongMisses ' : '');
		final comboMultString = (ClientPrefs.comboScoreEffect ? '\nScore Multiplier: $(comboMultiplier)x' : '');
		judgementCounter.text = hittingStuff + ratingCountString + comboMultString;
		judgementCounter.text += (ClientPrefs.showNPS ? '\nNPS (Max): ' + formattedNPS + ' (' + formattedMaxNPS + ')' : '');
		if (ClientPrefs.opponentRateCount) judgementCounter.text += '\n\nOpponent Hits: ' + formattedEnemyHits + ' / ' + FlxStringUtil.formatMoney(opponentNoteTotal, false) + ' (' + FlxMath.roundDecimal((enemyHits / opponentNoteTotal) * 100, 2) + '%)' + (ClientPrefs.showNPS ? '\nOpponent NPS (Max): ' + formattedOppNPS + ' (' + formattedMaxOppNPS + ')' : '');
	}

	public var ratingName:String = '?';
	public var ratingString:String;
	public var ratingPercent:Float;
	public var ratingFC:String;
	public var ratingCool:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);
		if (badHit) missRecalcsPerFrame += 1;

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

			if (Math.isNaN(ratingPercent))
				ratingString = '?';

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
				if (totalPlayed == 0) ratingFC = fcStrings[0];
				if (perfects > 0) ratingFC = fcStrings[1];
				if (sicks > 0) ratingFC = fcStrings[2];
				if (goods > 0) ratingFC = fcStrings[3];
				if (bads > 0) ratingFC = fcStrings[4];
				if (shits > 0) ratingFC = fcStrings[5];
				if (songMisses > 0 && songMisses < 10) ratingFC = fcStrings[6];
				if (songMisses >= 10) ratingFC = fcStrings[7];
				if (songMisses >= 100) ratingFC = fcStrings[8];
				if (songMisses >= 1000) ratingFC = fcStrings[9];

			ratingCool = "";
			if (ratingPercent*100 <= 60) ratingCool = " F";
			if (ratingPercent*100 >= 60) ratingCool = " D";
			if (ratingPercent*100 >= 60) ratingCool = " C";
			if (ratingPercent*100 >= 70) ratingCool = " B";
			if (ratingPercent*100 >= 80) ratingCool = " A";
			if (ratingPercent*100 >= 85) ratingCool = " A.";
			if (ratingPercent*100 >= 90) ratingCool = " A:";
			if (ratingPercent*100 >= 93) ratingCool = " AA";
			if (ratingPercent*100 >= 96.50) ratingCool = " AA.";
			if (ratingPercent*100 >= 99) ratingCool = " AA:";
			if (ratingPercent*100 >= 99.70) ratingCool = " AAA";
			if (ratingPercent*100 >= 99.80) ratingCool = " AAA.";
			if (ratingPercent*100 >= 99.90) ratingCool = " AAA:";
			if (ratingPercent*100 >= 99.955) ratingCool = " AAAA";
			if (ratingPercent*100 >= 99.970) ratingCool = " AAAA.";
			if (ratingPercent*100 >= 99.980) ratingCool = " AAAA:";
			if (ratingPercent*100 >= 99.9935) ratingCool = " AAAAA";

			// basically same stuff, doesn't update every frame but it also means no memory leaks during botplay
			if (ClientPrefs.ratingCounter && judgementCounter != null)
				updateRatingCounter();
			if (!ClientPrefs.hideScore && scoreTxt != null)
				updateScore(badHit);
			if (ClientPrefs.compactNumbers)
				updateCompactNumbers();
		}

		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
		setOnLuas('ratingCool', ratingCool);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode || trollingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && Achievements.exists(achievementName)) {
				var unlock:Bool = false;

				if (achievementName.contains(WeekData.getWeekFileName()) && achievementName.endsWith('nomiss')) // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss";
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				switch(achievementName)
				{
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(!ClientPrefs.shaders && ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
}