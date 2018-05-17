package beepbox.synth;

/*
Copyright (C) 2012 John Nesky

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
*/

class Music
{

	public static var scaleNames:Array<String> = ["easy :)", "easy :(", "island :)", "island :(", "blues :)", "blues :(", "normal :)", "normal :(", "dbl harmonic :)", "dbl harmonic :(", "enigma", "expert"];
	public static var scaleFlags:Array<Array<Bool>> = [
		[ true, false,  true, false,  true, false, false,  true, false,  true, false, false],
		[ true, false, false,  true, false,  true, false,  true, false, false,  true, false],
		[ true, false, false, false,  true,  true, false,  true, false, false, false,  true],
		[ true,  true, false,  true, false, false, false,  true,  true, false, false, false],
		[ true, false,  true,  true,  true, false, false,  true, false,  true, false, false],
		[ true, false, false,  true, false,  true,  true,  true, false, false,  true, false],
		[ true, false,  true, false,  true,  true, false,  true, false,  true, false,  true],
		[ true, false,  true,  true, false,  true, false,  true,  true, false,  true, false],
		[ true,  true, false, false,  true,  true, false,  true,  true, false, false,  true],
		[ true, false,  true,  true, false, false,  true,  true,  true, false, false,  true],
		[ true, false,  true, false,  true, false,  true, false,  true, false,  true, false],
		[ true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true],
	];
	public static var pianoScaleFlags:Array<Bool> = [ true, false,  true, false,  true,  true, false,  true, false,  true, false,  true];
	// C1 has index 24 on the MIDI scale. C8 is 108, and C9 is 120. C10 is barely in the audible range.
	public static var keyNames:Array<String> = ["B", "A#", "A", "G#", "G", "F#", "F", "E", "D#", "D", "C#", "C"];
	public static var keyTransposes:Array<Int> = [23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12];
	public static var tempoNames:Array<String> = ["molasses", "slow", "leisurely", "moderate", "steady", "brisk", "hasty", "fast", "strenuous", "grueling", "hyper", "ludicrous"];
	public static var reverbRange:Int = 4;
	public static var beatsMin:Int = 3;
	public static var beatsMax:Int = 15;
	public static var barsMin:Int = 1;
	public static var barsMax:Int = 128;
	public static var patternsMin:Int = 1;
	public static var patternsMax:Int = 64;
	public static var instrumentsMin:Int = 1;
	public static var instrumentsMax:Int = 10;
	public static var partNames:Array<String> = ["triples", "standard"];
	public static var partCounts:Array<Int> = [3, 4];
	public static var pitchNames:Array<String> = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
	public static var waveNames:Array<String> = ["triangle", "square", "pulse wide", "pulse narrow", "sawtooth", "double saw", "double pulse", "spiky", "plateau"];
	public static var waveVolumes:Array<Float> = [1.0, 0.5, 0.5, 0.5, 0.65, 0.5, 0.4, 0.4, 0.94];
	public static var drumNames:Array<String> = ["retro", "white"];
	public static var drumVolumes:Array<Float> = [0.25, 1.0];
	public static var filterNames:Array<String> = ["sustain sharp", "sustain medium", "sustain soft", "decay sharp", "decay medium", "decay soft"];
	public static var filterBases:Array<Float> = [2.0, 3.5, 5.0, 1.0, 2.5, 4.0];
	public static var filterDecays:Array<Float> = [0.0, 0.0, 0.0, 10.0, 7.0, 4.0];
	public static var filterVolumes:Array<Float> = [0.4, 0.7, 1.0, 0.5, 0.75, 1.0];
	public static var attackNames:Array<String> = ["binary", "sudden", "smooth", "slide"];
	public static var effectNames:Array<String> = ["none", "vibrato light", "vibrato delayed", "vibrato heavy", "tremelo light", "tremelo heavy"];
	public static var effectVibratos:Array<Float> = [0.0, 0.15, 0.3, 0.45, 0.0, 0.0];
	public static var effectTremelos:Array<Float> = [0.0, 0.0, 0.0, 0.0, 0.25, 0.5];
	public static var chorusNames:Array<String> = ["union", "shimmer", "hum", "honky tonk", "dissonant", "fifths", "octaves", "bowed"];
	public static var chorusValues:Array<Float> = [0.0, 0.02, 0.05, 0.1, 0.25, 3.5, 6, 0.02];
	public static var chorusOffsets:Array<Float> = [0.0, 0.0, 0.0, 0.0, 0.0, 3.5, 6, 0.0];
	public static var chorusVolumes:Array<Float> = [0.7, 0.8, 1.0, 1.0, 0.9, 0.9, 0.8, 1.0];
	public static var volumeNames:Array<String> = ["loudest", "loud", "medium", "quiet", "quietest", "mute"];
	public static var volumeValues:Array<Float> = [0.0, 0.5, 1.0, 1.5, 2.0, -1.0];
	public static var channelVolumes:Array<Float> = [0.27, 0.27, 0.27, 0.19];
	public static var drumInterval:Int = 6;
	public static var numChannels:Int = 4;
	public static var drumCount:Int = 12;
	public static var pitchCount:Int = 37;
	public static var maxPitch:Int = 84;

}