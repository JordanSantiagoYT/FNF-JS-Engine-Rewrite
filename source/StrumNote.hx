package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import NoteShader.ColoredNoteShader;

using StringTools;

class StrumNote extends FlxSprite
{
	public var colorSwap:ColorSwap;
    	public var notes_angle:Null<Float> = null;
	public var noteThing:Note;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	public var noteShit = new Note(0, 0, null, false, false);
	public var rgbShaderEnabled:Bool = false;
	
	public var player:Int;
	public var ogNoteskin:String = null;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = (value != null ? value : "NOTE_assets");
			reloadNote();
		}
		return value;
	}

    	public function getAngle() {
       		return (notes_angle == null ? angle : notes_angle);
    	}

	public function new(x:Float, y:Float, leData:Int, player:Int) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		if (ClientPrefs.noteColorStyle == 'Char-Based' && PlayState.instance != null) shader = new ColoredNoteShader(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2], false, 10);
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		var skin:String = 'NOTE_assets';
		if(PlayState.instance != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
			
			if(ClientPrefs.noteStyleThing == 'VS Nonsense V2') {
				skin = 'Nonsense_NOTE_assets';
			}
			if(ClientPrefs.noteStyleThing == 'DNB 3D') {
				skin = 'NOTE_assets_3D';
			}
			if(ClientPrefs.noteStyleThing == 'VS AGOTI') {
				skin = 'AGOTINOTE_assets';
			}
			if(ClientPrefs.noteStyleThing == 'Doki Doki+') {
				skin = 'NOTE_assets_doki';
			}
			if(ClientPrefs.noteStyleThing == 'TGT V4') {
				skin = 'TGTNOTE_assets';
			}
			if (ClientPrefs.noteStyleThing != 'VS Nonsense V2' && ClientPrefs.noteStyleThing != 'DNB 3D' && ClientPrefs.noteStyleThing != 'VS AGOTI' && ClientPrefs.noteStyleThing != 'Doki Doki+' && ClientPrefs.noteStyleThing != 'TGT V4' && ClientPrefs.noteStyleThing != 'Default') {
				skin = 'NOTE_assets_' + ClientPrefs.noteStyleThing.toLowerCase();
			}
			if(ClientPrefs.noteColorStyle == 'Quant-Based' || ClientPrefs.noteColorStyle == 'Rainbow') {
				skin = ClientPrefs.noteStyleThing == 'TGT V4' ? 'RED_TGTNOTE_assets' : 'RED_NOTE_assets';
			}
			if(ClientPrefs.noteColorStyle == 'Grayscale') {
				skin = 'GRAY_NOTE_assets';
			}
			if(ClientPrefs.noteColorStyle == 'Char-Based') {
				skin = 'NOTE_assets_colored';
			}
		texture = skin; //Load texture and anims
		ogNoteskin = skin;

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float) {
		if (ClientPrefs.ffmpegMode) elapsed = 1 / ClientPrefs.targetFPS;
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');	
				if (ClientPrefs.enableColorShader)
				{
           				if (ClientPrefs.noteColorStyle != 'Char-Based') resetHue(); // Add this line to reset the hue value
						else disableRGB();
				}
				resetAnim = 0;
			}
		}
		//if(animation.curAnim != null){ //my bad i was upset
		if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
			centerOrigin();
		//}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false, hue:Float = 0, sat:Float = 0, brt:Float = 0, ?enableRGBShader:Bool = false, ?bfRGB:Bool = false, ?gfRGB:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if(animation.curAnim == null || animation.curAnim.name == 'static' && ClientPrefs.enableColorShader) {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
			if (ClientPrefs.noteColorStyle == 'Char-Based') disableRGB();
		} else {
		if (enableRGBShader && !bfRGB && !rgbShaderEnabled) enableRGB();
		//stupid workaround but it works
		if (enableRGBShader && bfRGB && !rgbShaderEnabled) enableRGBBF();
		if (enableRGBShader && gfRGB) enableRGBGF();
			if (noteData > -1 && noteData < ClientPrefs.arrowHSV.length && ClientPrefs.enableColorShader)
			{
				if (ClientPrefs.noteColorStyle == 'Normal')
				{
				colorSwap.hue = ClientPrefs.arrowHSV[noteData][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[noteData][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[noteData][2] / 100;
				}
				if (ClientPrefs.noteColorStyle == 'Quant-Based' || ClientPrefs.noteColorStyle == 'Rainbow')
				{
				colorSwap.hue = hue;
				colorSwap.saturation = sat;
				colorSwap.brightness = brt;
				}
			}
			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}
	public function resetHue() {
  	// Reset the hue value to 0 (or any desired value)
    	colorSwap.hue = 0;
    	colorSwap.saturation = 0;
    	colorSwap.brightness = 0;
	}
	public function disableRGB() {
        if (Std.isOfType(this.shader, ColoredNoteShader))
            cast(this.shader, ColoredNoteShader).enabled.value = [false];
			rgbShaderEnabled = false;
	}
	public function enableRGB() {
        if (Std.isOfType(this.shader, ColoredNoteShader))
	    !PlayState.opponentChart ? cast(this.shader, ColoredNoteShader).setColors(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]) : cast(this.shader, ColoredNoteShader).setColors(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]);
            cast(this.shader, ColoredNoteShader).enabled.value = [true];
			rgbShaderEnabled = true;
	}
	public function enableRGBBF() {
        if (Std.isOfType(this.shader, ColoredNoteShader))
	    !PlayState.opponentChart ? cast(this.shader, ColoredNoteShader).setColors(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]) : cast(this.shader, ColoredNoteShader).setColors(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]);
            cast(this.shader, ColoredNoteShader).enabled.value = [true];
			rgbShaderEnabled = true;
	}
	public function enableRGBGF() {
        if (Std.isOfType(this.shader, ColoredNoteShader) && PlayState.instance.gf != null)
	    cast(this.shader, ColoredNoteShader).setColors(PlayState.instance.gf.healthColorArray[0], PlayState.instance.gf.healthColorArray[1], PlayState.instance.gf.healthColorArray[2]);
            cast(this.shader, ColoredNoteShader).enabled.value = [true];
			rgbShaderEnabled = true;
	}
	public function updateNoteSkin(noteskin:String) {
			if (texture == "noteskins/" + noteskin || noteskin == ogNoteskin || texture == noteskin) return; //if the noteskin to change to is the same as before then don't update it
			if (noteskin != null && noteskin != '') texture = "noteskins/" + noteskin;
			if(ClientPrefs.noteStyleThing == 'VS Nonsense V2') {
				texture = 'Nonsense_NOTE_assets';
			}
			if(ClientPrefs.noteStyleThing == 'DNB 3D') {
				texture = 'NOTE_assets_3D';
			}
			if(ClientPrefs.noteStyleThing == 'VS AGOTI') {
				texture = 'AGOTINOTE_assets';
			}
			if(ClientPrefs.noteStyleThing == 'Doki Doki+') {
				texture = 'NOTE_assets_doki';
			}
			if(ClientPrefs.noteStyleThing == 'TGT V4') {
				texture = 'TGTNOTE_assets';
			}
			if (ClientPrefs.noteStyleThing != 'VS Nonsense V2' && ClientPrefs.noteStyleThing != 'DNB 3D' && ClientPrefs.noteStyleThing != 'VS AGOTI' && ClientPrefs.noteStyleThing != 'Doki Doki+' && ClientPrefs.noteStyleThing != 'TGT V4' && ClientPrefs.noteStyleThing != 'Default') {
				texture = 'NOTE_assets_' + ClientPrefs.noteStyleThing.toLowerCase();
			}
			if(ClientPrefs.noteColorStyle == 'Quant-Based' || ClientPrefs.noteColorStyle == 'Rainbow') {
				texture = ClientPrefs.noteStyleThing == 'TGT V4' ? 'RED_TGTNOTE_assets' : 'RED_NOTE_assets';
			}
			if(ClientPrefs.noteColorStyle == 'Char-Based') {
				texture = 'NOTE_assets_colored';
			}
			if(ClientPrefs.noteColorStyle == 'Grayscale') {
				texture = 'GRAY_NOTE_assets';
			}
	}
	public function updateRGBColors(?updateBF:Bool = false) {
        	if (Std.isOfType(this.shader, ColoredNoteShader))
		{
			if (updateBF)
	    			!PlayState.opponentChart ? cast(this.shader, ColoredNoteShader).setColors(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]) : cast(this.shader, ColoredNoteShader).setColors(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]);
	    		else 
			!PlayState.opponentChart ? cast(this.shader, ColoredNoteShader).setColors(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]) : cast(this.shader, ColoredNoteShader).setColors(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]);
		}
	}
}