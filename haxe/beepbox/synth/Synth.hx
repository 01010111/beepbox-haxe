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

// { region IMPORTS **COMPLETE**

import openfl.events.SampleDataEvent;
import openfl.events.TimerEvent;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.utils.Timer;
import openfl.utils.ByteArray;

// } endregion

class Synth
{
	
	// { region VARIABLES **COMPLETE**

	public static var samplesPerSecond:Int = 44100;

	static var effectDuration:Float = 0.14;
	static var effectAngle:Float = Math.PI * 2.0 / (effectDuration * samplesPerSecond);
	static var effectYMult:Float = 2.0 * Math.cos( effectAngle );
	static var limitDecay:Float = 1.0 / (2.0 * samplesPerSecond);
	static var waves: Array<Array<Float>> = [
		[1.0/15.0, 3.0/15.0, 5.0/15.0, 7.0/15.0, 9.0/15.0, 11.0/15.0, 13.0/15.0, 15.0/15.0, 15.0/15.0, 13.0/15.0, 11.0/15.0, 9.0/15.0, 7.0/15.0, 5.0/15.0, 3.0/15.0, 1.0/15.0, -1.0/15.0, -3.0/15.0, -5.0/15.0, -7.0/15.0, -9.0/15.0, -11.0/15.0, -13.0/15.0, -15.0/15.0, -15.0/15.0, -13.0/15.0, -11.0/15.0, -9.0/15.0, -7.0/15.0, -5.0/15.0, -3.0/15.0, -1.0/15.0],
		[1.0, -1.0],
		[1.0, -1.0, -1.0, -1.0],
		[1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0],
		[1.0/31.0, 3.0/31.0, 5.0/31.0, 7.0/31.0, 9.0/31.0, 11.0/31.0, 13.0/31.0, 15.0/31.0, 17.0/31.0, 19.0/31.0, 21.0/31.0, 23.0/31.0, 25.0/31.0, 27.0/31.0, 29.0/31.0, 31.0/31.0, -31.0/31.0, -29.0/31.0, -27.0/31.0, -25.0/31.0, -23.0/31.0, -21.0/31.0, -19.0/31.0, -17.0/31.0, -15.0/31.0, -13.0/31.0, -11.0/31.0, -9.0/31.0, -7.0/31.0, -5.0/31.0, -3.0/31.0, -1.0/31.0],
		[0.0, -0.2, -0.4, -0.6, -0.8, -1.0, 1.0, -0.8, -0.6, -0.4, -0.2, 1.0, 0.8, 0.6, 0.4, 0.2, ],
		[1.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, -1.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, -1.0, -1.0],
		[1.0, -1.0, 1.0, -1.0, 1.0, 0.0],
		[0.0, 0.2, 0.4, 0.5, 0.6, 0.7, 0.8, 0.85, 0.9, 0.95, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.95, 0.9, 0.85, 0.8, 0.7, 0.6, 0.5, 0.4, 0.2, 0.0, -0.2, -0.4, -0.5, -0.6, -0.7, -0.8, -0.85, -0.9, -0.95, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -0.95, -0.9, -0.85, -0.8, -0.7, -0.6, -0.5, -0.4, -0.2, ],
	];
	static var drumWaves: Array<Array<Float>> = [[],[]];
	
	public var song:Song = null;
	public var stutterPressed:Bool = false;
	public var pianoPressed:Bool = false;
	public var pianoPitch:Int = 0;
	public var pianoChannel:Int = 0;
	public var enableIntro:Bool = true;
	public var enableOutro:Bool = false;
	public var loopCount:Int = -1;
	public var volume:Float = 1.0;

	public var playing(get, never):Bool;
	public var playhead(get, set):Float;
	public var totalSamples(get, never):Int;
	public var totalSeconds(get, never):Float;
	public var totalBars(get, never):Int;
	
	var _playhead:Float = 0.0;
	var bar:Int = 0;
	var beat:Int = 0;
	var part:Int = 0;
	var arpeggio:Int = 0;
	var arpeggioSamples:Int = 0;
	var paused:Bool = true;
	var leadPeriodA:Float = 0.0;
	var leadPeriodB:Float = 0.0;
	var leadSample:Float = 0.0;
	var harmonyPeriodA:Float = 0.0;
	var harmonyPeriodB:Float = 0.0;
	var harmonySample:Float = 0.0;
	var bassPeriodA:Float = 0.0;
	var bassPeriodB:Float = 0.0;
	var bassSample:Float = 0.0;
	var drumPeriod:Float = 0.0;
	var drumSample:Float = 0.0;
	var drumSignal:Float = 1.0;
	var stillGoing:Bool = false;
	var sound:Sound = new Sound();
	var soundChannel:SoundChannel = null;
	var timer:Timer = new Timer(200, 0);
	var effectPeriod:Float = 0.0;
	var limit:Float = 0.0;
	
	var delayLine: Array<Float> = [for(i in 0...16384) 0];
	var delayPos:Int = 0;
	var delayFeedback0:Float = 0.0;
	var delayFeedback1:Float = 0.0;
	var delayFeedback2:Float = 0.0;
	var delayFeedback3:Float = 0.0;

	// } endregion

	// { region GETTERS/SETTERS **COMPLETE**

	inline function get_playing():Bool return !paused;
	inline function get_playhead():Float return _playhead;

	function set_playhead(value:Float)
	{
		if (song != null)
		{
			_playhead = Math.max(0, Math.min(song.bars, value));
			var remainder:Float = _playhead;
			bar = Math.floor(remainder);
			remainder = song.beats * (remainder - bar);
			beat = Math.floor(remainder);
			remainder = song.parts * (remainder - beat);
			part = Math.floor(remainder);
			remainder = 4 * (remainder - part);
			arpeggio = Math.floor(remainder);
			var samplesPerArpeggio:Float = getSamplesPerArpeggio();
			remainder = samplesPerArpeggio * (remainder - arpeggio);
			arpeggioSamples = Math.floor(samplesPerArpeggio - remainder);
			if (bar < song.loopStart) enableIntro = true;
			if (bar > song.loopStart + song.loopLength) enableOutro = true;
		}
		return _playhead;
	}

	function get_totalSamples():Int
	{
		if (song == null) return 0;
		var samplesPerBar:Int = getSamplesPerArpeggio() * 4 * song.parts * song.beats;
		var loopMinCount:Int = loopCount;
		if (loopMinCount < 0) loopMinCount = 1;
		var bars:Int = song.loopLength * loopMinCount;
		if (enableIntro) bars += song.loopStart;
		if (enableOutro) bars += song.bars - (song.loopStart + song.loopLength);
		return bars * samplesPerBar;
	}
	
	inline function get_totalSeconds():Float return (totalSamples / samplesPerSecond);
	inline function get_totalBars():Int return song == null ? 0 : song.bars;

	// } endregion

	// { region CONSTRUCTOR **COMPLETE**

	public function new(?song:Song)
	{
		for (wave in waves)
		{
			var sum:Float = 0.0;
			for (i in 0...wave.length) sum += wave[i];
			var average:Float = sum / wave.length;
			for (i in 0...wave.length) wave[i] -= average;
		}
		
		for (wave in drumWaves)
		{
			if (drumWaves.indexOf(wave) == 0)
			{
				var drumBuffer:Int = 1;
				for (i in 0...32767)
				{
					wave.push((drumBuffer & 1) * 2.0 - 1.0);
					var newBuffer:Int = drumBuffer >> 1;
					if ((drumBuffer + newBuffer) & 1 == 1) newBuffer += 1 << 14;
					drumBuffer = newBuffer;
				}
			} 
			else if (drumWaves.indexOf(wave) == 1)
			{
				for (i in 0...32767) wave.push(Math.random() * 2.0 - 1.0);
			}
		}
		
		sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData, false, 0, true);
		timer.addEventListener(TimerEvent.TIMER, checkSound);
		
		if (song != null) this.song = song;
	}
	
	// } endregion

	// { region SONG UTIL **COMPLETE**

	public function play()
	{
		if (!paused) return;
		paused = false;
		soundChannel = sound.play();
		timer.start();
		stillGoing = true;
	}
	
	public function pause()
	{
		if (paused) return;
		paused = true;
		soundChannel.stop();
		soundChannel = null;
		timer.stop();
		stillGoing = false;
	}

	public function snapToStart()
	{
		bar = 0;
		enableIntro = true;
		snapToBar();
	}

	public function snapToBar()
	{
		_playhead = bar;
		beat = 0;
		part = 0;
		arpeggio = 0;
		arpeggioSamples = 0;
		effectPeriod = 0.0;
		
		leadSample = 0.0;
		harmonySample = 0.0;
		bassSample = 0.0;
		drumSample = 0.0;
		delayPos = 0;
		delayFeedback0 = 0.0;
		delayFeedback1 = 0.0;
		delayFeedback2 = 0.0;
		delayFeedback3 = 0.0;
		for (i in 0...delayLine.length) delayLine[i] = 0.0;
	}
	
	public function nextBar()
	{
		var oldBar:Int = bar;
		bar++;
		if (enableOutro)
		{
			if (bar >= song.bars) bar = enableIntro ? 0 : song.loopStart;
		}
		else if (bar >= song.loopStart + song.loopLength || bar >= song.bars) bar = song.loopStart;
		_playhead += bar - oldBar;
	}

	public function prevBar()
	{
		var oldBar:Int = bar;
		bar--;
		if (bar < 0) bar = song.loopStart + song.loopLength - 1;
		if (bar >= song.bars) bar = song.bars - 1;
		if (bar < song.loopStart) enableIntro = true;
		if (!enableOutro && bar >= song.loopStart + song.loopLength) bar = song.loopStart + song.loopLength - 1;
		_playhead += bar - oldBar;
	}
	
	// } endregion

	// { region EVENTS **COMPLETE**
	
	function onSampleData(event:SampleDataEvent)
	{
		if (paused) return;
		synthesize(event.data, 4096);
		stillGoing = true;
	}

	function checkSound(event:TimerEvent)
	{
		if (!stillGoing)
		{
			if (soundChannel != null) soundChannel.stop();
			soundChannel = sound.play();
		}
		else stillGoing = false;
	}

	// } endregion

	// { region SYNTHESIZE **COMPLETE**

	public function synthesize(data:ByteArray, totalSamples:Int)
	{
		if (song == null)
		{
			for (i in 0...totalSamples)
			{
				data.writeFloat(0);
				data.writeFloat(0);
			}
			return;
		}

		var stutterFunction = function() {};

		if (stutterPressed)
		{
			var barOld:Int = bar;
			var beatOld:Int = beat;
			var partOld:Int = part;
			var arpeggioOld:Int = arpeggio;
			var arpeggioSamplesOld:Int = arpeggioSamples;
			var leadPeriodAOld:Float = leadPeriodA;
			var leadPeriodBOld:Float = leadPeriodB;
			var leadSampleOld:Float = leadSample;
			var harmonyPeriodAOld:Float = harmonyPeriodA;
			var harmonyPeriodBOld:Float = harmonyPeriodB;
			var harmonySampleOld:Float = harmonySample;
			var bassPeriodAOld:Float = bassPeriodA;
			var bassPeriodBOld:Float = bassPeriodB;
			var bassSampleOld:Float = bassSample;
			var drumPeriodOld:Float = drumPeriod;
			var drumSampleOld:Float = drumSample;
			var drumSignalOld:Float = drumSignal;
			var effectPeriodOld:Float = effectPeriod;
			var limitOld:Float = limit;
			stutterFunction = function() {
				bar = barOld;
				beat = beatOld;
				part = partOld;
				arpeggio = arpeggioOld;
				arpeggioSamples = arpeggioSamplesOld;
				leadPeriodA = leadPeriodAOld;
				leadPeriodB = leadPeriodBOld;
				leadSample = leadSampleOld;
				harmonyPeriodA = harmonyPeriodAOld;
				harmonyPeriodB = harmonyPeriodBOld;
				harmonySample = harmonySampleOld;
				bassPeriodA = bassPeriodAOld;
				bassPeriodB = bassPeriodBOld;
				bassSample = bassSampleOld;
				drumPeriod = drumPeriodOld;
				drumSample = drumSampleOld;
				drumSignal = drumSignalOld;
				effectPeriod = effectPeriodOld;
				limit = limitOld;
			}
		}

		var sampleTime = 1.0 / samplesPerSecond;
		var samplesPerArpeggio = getSamplesPerArpeggio();

		var reverb = Math.pow(song.reverb / Music.reverbRange, 0.667) * 0.375;

		var ended = false;

		// Check the bounds of the playhead:
		if (arpeggioSamples == 0 || arpeggioSamples > samplesPerArpeggio) arpeggioSamples = samplesPerArpeggio;
		if (part >= song.parts)
		{
			beat++;
			part = 0;
			arpeggio = 0;
			arpeggioSamples = samplesPerArpeggio;
		}
		if (beat >= song.beats)
		{
			bar++;
			beat = 0;
			part = 0;
			arpeggio = 0;
			arpeggioSamples = samplesPerArpeggio;
			
			if (loopCount == -1)
			{
				if (bar < song.loopStart && !enableIntro) bar = song.loopStart;
				if (bar >= song.loopStart + song.loopLength && !enableOutro) bar = song.loopStart;
			}
		}
		if (bar >= song.bars)
		{
			if (enableOutro)
			{
				bar = 0;
				enableIntro = true;
				ended = true;
				pause();
			}
			else bar = song.loopStart;
		}
		if (bar >= song.loopStart) enableIntro = false;

		var maxLeadVolume:			Float;
		var maxHarmonyVolume:		Float;
		var maxBassVolume:			Float;
		var maxDrumVolume:			Float;
		
		var leadWave:				Array<Float>;
		var harmonyWave:			Array<Float>;
		var bassWave:				Array<Float>;
		var drumWave:				Array<Float>;
		
		var leadWaveLength:			Int;
		var harmonyWaveLength:		Int;
		var bassWaveLength:			Int;
		
		var leadFilterBase:			Float;
		var harmonyFilterBase:		Float;
		var bassFilterBase:			Float;
		var drumFilter:				Float;
		
		var leadTremeloScale:		Float;
		var harmonyTremeloScale:	Float;
		var bassTremeloScale:		Float;
		
		var leadChorusA:			Float;
		var harmonyChorusA:			Float;
		var bassChorusA:			Float;
		var leadChorusB:			Float;
		var harmonyChorusB:			Float;
		var bassChorusB:			Float;
		var leadChorusSign:			Float;
		var harmonyChorusSign:		Float;
		var bassChorusSign:			Float;

		var updateInstruments = function() {
			var instrumentLead:Int		= song.getPatternInstrument(0, bar);
			var instrumentHarmony:Int	= song.getPatternInstrument(1, bar);
			var instrumentBass:Int		= song.getPatternInstrument(2, bar);
			var instrumentDrum:Int		= song.getPatternInstrument(3, bar);
			
			maxLeadVolume    = Music.channelVolumes[0] * (song.instrumentVolumes[0][instrumentLead] == 5 ? 0.0 :    Math.pow(2, -Music.volumeValues[song.instrumentVolumes[0][instrumentLead]]))    * Music.waveVolumes[song.instrumentWaves[0][instrumentLead]]    * Music.filterVolumes[song.instrumentFilters[0][instrumentLead]]    * Music.chorusVolumes[song.instrumentChorus[0][instrumentLead]]    * 0.5;
			maxHarmonyVolume = Music.channelVolumes[1] * (song.instrumentVolumes[1][instrumentHarmony] == 5 ? 0.0 : Math.pow(2, -Music.volumeValues[song.instrumentVolumes[1][instrumentHarmony]])) * Music.waveVolumes[song.instrumentWaves[1][instrumentHarmony]] * Music.filterVolumes[song.instrumentFilters[1][instrumentHarmony]] * Music.chorusVolumes[song.instrumentChorus[0][instrumentHarmony]] * 0.5;
			maxBassVolume    = Music.channelVolumes[2] * (song.instrumentVolumes[2][instrumentBass] == 5 ? 0.0 :    Math.pow(2, -Music.volumeValues[song.instrumentVolumes[2][instrumentBass]]))    * Music.waveVolumes[song.instrumentWaves[2][instrumentBass]]    * Music.filterVolumes[song.instrumentFilters[2][instrumentBass]]    * Music.chorusVolumes[song.instrumentChorus[0][instrumentBass]]    * 0.5;
			maxDrumVolume    = Music.channelVolumes[3] * (song.instrumentVolumes[3][instrumentDrum] == 5 ? 0.0 :    Math.pow(2, -Music.volumeValues[song.instrumentVolumes[3][instrumentDrum]]))    * Music.drumVolumes[song.instrumentWaves[3][instrumentDrum]];
			
			leadWave    = waves[song.instrumentWaves[0][instrumentLead]];
			harmonyWave = waves[song.instrumentWaves[1][instrumentHarmony]];
			bassWave    = waves[song.instrumentWaves[2][instrumentBass]];
			drumWave    = drumWaves[song.instrumentWaves[3][instrumentDrum]];
			
			leadWaveLength    = leadWave.length;
			harmonyWaveLength = harmonyWave.length;
			bassWaveLength    = bassWave.length;
			
			leadFilterBase    = Math.pow(2, -Music.filterBases[song.instrumentFilters[0][instrumentLead]]);
			harmonyFilterBase = Math.pow(2, -Music.filterBases[song.instrumentFilters[1][instrumentHarmony]]);
			bassFilterBase    = Math.pow(2, -Music.filterBases[song.instrumentFilters[2][instrumentBass]]);
			drumFilter = 1.0;
			
			leadTremeloScale    = Music.effectTremelos[song.instrumentEffects[0][instrumentLead]];
			harmonyTremeloScale = Music.effectTremelos[song.instrumentEffects[1][instrumentHarmony]];
			bassTremeloScale    = Music.effectTremelos[song.instrumentEffects[2][instrumentBass]];
			
			leadChorusA    = Math.pow( 2.0, (Music.chorusOffsets[song.instrumentChorus[0][instrumentLead]] + Music.chorusValues[song.instrumentChorus[0][instrumentLead]]) / 12.0 );
			harmonyChorusA = Math.pow( 2.0, (Music.chorusOffsets[song.instrumentChorus[1][instrumentHarmony]] + Music.chorusValues[song.instrumentChorus[1][instrumentHarmony]]) / 12.0 );
			bassChorusA    = Math.pow( 2.0, (Music.chorusOffsets[song.instrumentChorus[2][instrumentBass]] + Music.chorusValues[song.instrumentChorus[2][instrumentBass]]) / 12.0 );
			leadChorusB    = Math.pow( 2.0, (Music.chorusOffsets[song.instrumentChorus[0][instrumentLead]] - Music.chorusValues[song.instrumentChorus[0][instrumentLead]]) / 12.0 );
			harmonyChorusB = Math.pow( 2.0, (Music.chorusOffsets[song.instrumentChorus[1][instrumentHarmony]] - Music.chorusValues[song.instrumentChorus[1][instrumentHarmony]]) / 12.0 );
			bassChorusB    = Math.pow( 2.0, (Music.chorusOffsets[song.instrumentChorus[2][instrumentBass]] - Music.chorusValues[song.instrumentChorus[2][instrumentBass]]) / 12.0 );
			leadChorusSign = (song.instrumentChorus[0][instrumentLead] == 7) ? -1.0 : 1.0;
			harmonyChorusSign = (song.instrumentChorus[1][instrumentHarmony] == 7) ? -1.0 : 1.0;
			bassChorusSign = (song.instrumentChorus[2][instrumentBass] == 7) ? -1.0 : 1.0;
			if (song.instrumentChorus[0][instrumentLead] == 0) leadPeriodB = leadPeriodA;
			if (song.instrumentChorus[1][instrumentHarmony] == 0) harmonyPeriodB = harmonyPeriodA;
			if (song.instrumentChorus[2][instrumentBass] == 0) bassPeriodB = bassPeriodA;
		}

		updateInstruments();

		while (totalSamples > 0) 
		{
			if (ended)
			{
				while (totalSamples-- > 0)
				{
					data.writeFloat(0.0);
					data.writeFloat(0.0);
				}
				break;
			}

			var samples:Int;
			if (arpeggioSamples <= totalSamples) samples = arpeggioSamples;
			else samples = totalSamples;
			totalSamples -= samples;
			arpeggioSamples -= samples;

			var leadPeriodDelta:Float = 0;
			var leadPeriodDeltaScale:Float = 0;
			var leadVolume:Float = 0;
			var leadVolumeDelta:Float = 0;
			var leadFilter:Float = 0;
			var leadFilterScale:Float = 0;
			var leadVibratoScale:Float = 0;
			var harmonyPeriodDelta:Float = 0;
			var harmonyPeriodDeltaScale:Float = 0;
			var harmonyVolume:Float = 0;
			var harmonyVolumeDelta:Float = 0;
			var harmonyFilter:Float = 0;
			var harmonyFilterScale:Float = 0;
			var harmonyVibratoScale:Float = 0;
			var bassPeriodDelta:Float = 0;
			var bassPeriodDeltaScale:Float = 0;
			var bassVolume:Float = 0;
			var bassVolumeDelta:Float = 0;
			var bassFilter:Float = 0;
			var bassFilterScale:Float = 0;
			var bassVibratoScale:Float = 0;
			var drumPeriodDelta:Float = 0;
			var drumPeriodDeltaScale:Float = 0;
			var drumVolume:Float = 0;
			var drumVolumeDelta:Float = 0;
			var time:Int = part + beat * song.parts;

			for (channel in 0...4)
			{
				var pattern:BarPattern = song.getPattern(channel, bar);
				var attack:Int = pattern == null ? 0 : song.instrumentAttacks[channel][pattern.instrument];

				var note:Note = null;
				var prevNote:Note = null;
				var nextNote:Note = null;

				if (pattern != null)
				{
					for (i in 0...pattern.notes.length)
					{
						if (pattern.notes[i].end <= time) prevNote = pattern.notes[i];
						else if (pattern.notes[i].start <= time && pattern.notes[i].end > time) note = pattern.notes[i];
						else if (pattern.notes[i].start > time) {
							nextNote = pattern.notes[i];
							break;
						}
					}
				}

				if (note != null && prevNote != null && prevNote.end != note.start) prevNote = null;
				if (note != null && nextNote != null && nextNote.start != note.end) nextNote = null;
				
				var channelRoot:Int = channel == 3 ? 69 : Music.keyTransposes[song.key];
				var intervalScale:Int = channel == 3 ? Music.drumInterval : 1;
				var periodDelta:Float;
				var periodDeltaScale:Float;
				var noteVolume:Float;
				var volumeDelta:Float;
				var filter:Float;
				var filterScale:Float;
				var vibratoScale:Float;
				var resetPeriod:Bool = false;

				if (pianoPressed && channel == pianoChannel)
				{
					var pianoFreq:Float = frequencyFromPitch(channelRoot + pianoPitch * intervalScale);
					var pianoPitchDamping:Float;
					if (channel == 3)
					{
						if (song.instrumentWaves[3][pattern.instrument] > 0) 
						{
							drumFilter = Math.min(1.0, pianoFreq * sampleTime * 8.0);
							pianoPitchDamping = 24.0;
						} 
						else pianoPitchDamping = 60.0;
					} 
					else pianoPitchDamping = 48.0;

					periodDelta = pianoFreq * sampleTime;
					periodDeltaScale = 1.0;
					noteVolume = Math.pow(2.0, -pianoPitch * intervalScale / pianoPitchDamping);
					volumeDelta = 0.0;
					filter = 1.0;
					filterScale = 1.0;
					vibratoScale = Math.pow(2.0, Music.effectVibratos[song.instrumentEffects[channel][pattern.instrument]] / 12.0 ) - 1.0;
				} 
				else if (note == null)
				{
					periodDelta = 0.0;
					periodDeltaScale = 0.0;
					noteVolume = 0.0;
					volumeDelta = 0.0;
					filter = 1.0;
					filterScale = 1.0;
					vibratoScale = 0.0;
					resetPeriod = true;
				} 
				else 
				{
					var pitch:Int;
					if (note.pitches.length == 2) pitch = note.pitches[arpeggio >> 1];
					else if (note.pitches.length == 3) pitch = note.pitches[arpeggio == 3 ? 1 : arpeggio];
					else if (note.pitches.length == 4) pitch = note.pitches[arpeggio];
					else pitch = note.pitches[0];
					
					var startPin:NotePin = null;
					var endPin:NotePin = null;
					for (pin in note.pins)
					{
						if (pin.time + note.start <= time) startPin = pin;
						else
						{
							endPin = pin;
							break;
						}
					}
					
					var noteStart:Int					= note.start * 4;
					var noteEnd:Int						= note.end   * 4;
					var pinStart:Int					= (note.start + startPin.time) * 4;
					var pinEnd:Int						= (note.start + endPin.time  ) * 4;
					var arpeggioStart:Int				= time * 4 + arpeggio;
					var arpeggioEnd:Int					= time * 4 + arpeggio + 1;
					var arpeggioRatioStart:Float		= (arpeggioStart - pinStart) / (pinEnd - pinStart);
					var arpeggioRatioEnd:Float			= (arpeggioEnd   - pinStart) / (pinEnd - pinStart);
					var arpeggioVolumeStart:Float		= startPin.volume * (1.0 - arpeggioRatioStart) + endPin.volume * arpeggioRatioStart;
					var arpeggioVolumeEnd:Float			= startPin.volume * (1.0 - arpeggioRatioEnd)   + endPin.volume * arpeggioRatioEnd;
					var arpeggioIntervalStart:Float		= startPin.interval * (1.0 - arpeggioRatioStart) + endPin.interval * arpeggioRatioStart;
					var arpeggioIntervalEnd:Float		= startPin.interval * (1.0 - arpeggioRatioEnd)   + endPin.interval * arpeggioRatioEnd;
					var arpeggioFilterTimeStart:Float	= startPin.time * (1.0 - arpeggioRatioStart) + endPin.time * arpeggioRatioStart;
					var arpeggioFilterTimeEnd:Float		= startPin.time * (1.0 - arpeggioRatioEnd)   + endPin.time * arpeggioRatioEnd;
					
					var inhibitRestart:Bool = false;
					if (arpeggioStart == noteStart)
					{
						if (attack == 0) inhibitRestart = true;
						else if (attack == 2) arpeggioVolumeStart = 0.0;
						else if (attack == 3)
						{
							if (prevNote == null || prevNote.pitches.length > 1 || note.pitches.length > 1) arpeggioVolumeStart = 0.0;
							else if (prevNote.pins[prevNote.pins.length-1].volume == 0 || note.pins[0].volume == 0) arpeggioVolumeStart = 0.0;
							// else if (prevNote.pitches[0] + prevNote.pins[prevNote.pins.length-1].interval == pitch) arpeggioVolumeStart = 0.0;
							else
							{
								arpeggioIntervalStart = (prevNote.pitches[0] + prevNote.pins[prevNote.pins.length-1].interval - pitch) * 0.5;
								arpeggioFilterTimeStart = prevNote.pins[prevNote.pins.length-1].time * 0.5;
								inhibitRestart = true;
							}
						}
					}
					if (arpeggioEnd == noteEnd)
					{
						if (attack == 1 || attack == 2) arpeggioVolumeEnd = 0.0;
						else if (attack == 3)
						{
							if (nextNote == null || nextNote.pitches.length > 1 || note.pitches.length > 1) arpeggioVolumeEnd = 0.0;
							else if (note.pins[note.pins.length-1].volume == 0 || nextNote.pins[0].volume == 0) arpeggioVolumeStart = 0.0;
							//else if (nextNote.pitches[0] == pitch + note.pins[note.pins.length-1].interval) arpeggioVolumeEnd = 0.0;
							else
							{
								arpeggioIntervalEnd = (nextNote.pitches[0] + note.pins[note.pins.length-1].interval - pitch) * 0.5;
								arpeggioFilterTimeEnd *= 0.5;
							}
						}
					}
					
					var startRatio:Float		= 1.0 - (arpeggioSamples + samples) / samplesPerArpeggio;
					var endRatio:Float			= 1.0 - (arpeggioSamples)           / samplesPerArpeggio;
					var startInterval:Float		= arpeggioIntervalStart * (1.0 - startRatio) + arpeggioIntervalEnd * startRatio;
					var endInterval:Float		= arpeggioIntervalStart * (1.0 - endRatio)   + arpeggioIntervalEnd * endRatio;
					var startFilterTime:Float	= arpeggioFilterTimeStart * (1.0 - startRatio) + arpeggioFilterTimeEnd * startRatio;
					var endFilterTime:Float		= arpeggioFilterTimeStart * (1.0 - endRatio)   + arpeggioFilterTimeEnd * endRatio;
					var startFreq:Float			= frequencyFromPitch(channelRoot + (pitch + startInterval) * intervalScale);
					var endFreq:Float			= frequencyFromPitch(channelRoot + (pitch + endInterval) * intervalScale);
					var pitchDamping:Float;
					if (channel == 3)
					{
						if (song.instrumentWaves[3][pattern.instrument] > 0)
						{
							drumFilter = Math.min(1.0, startFreq * sampleTime * 8.0);
							//trace(drumFilter);
							pitchDamping = 24.0;
						} 
						else pitchDamping = 60.0;
					} 
					else pitchDamping = 48.0;

					var startVol:Float	= Math.pow(2.0, -(pitch + startInterval) * intervalScale / pitchDamping);
					var endVol:Float	= Math.pow(2.0, -(pitch + endInterval) * intervalScale / pitchDamping);
					startVol *= volumeConversion(arpeggioVolumeStart * (1.0 - startRatio) + arpeggioVolumeEnd * startRatio);
					endVol   *= volumeConversion(arpeggioVolumeStart * (1.0 - endRatio)   + arpeggioVolumeEnd * endRatio);
					var freqScale:Float = endFreq / startFreq;
					periodDelta = startFreq * sampleTime;
					periodDeltaScale = Math.pow(freqScale, 1.0 / samples);
					noteVolume = startVol;
					volumeDelta = (endVol - startVol) / samples;
					var timeSinceStart:Float = (arpeggioStart + startRatio - noteStart) * samplesPerArpeggio / samplesPerSecond;
					if (timeSinceStart == 0.0 && !inhibitRestart) resetPeriod = true;
					
					var filterScaleRate:Float = Music.filterDecays[song.instrumentFilters[channel][pattern.instrument]];
					filter = Math.pow(2, -filterScaleRate * startFilterTime * 4.0 * samplesPerArpeggio / samplesPerSecond);
					var endFilter:Float = Math.pow(2, -filterScaleRate * endFilterTime * 4.0 * samplesPerArpeggio / samplesPerSecond);
					filterScale = Math.pow(endFilter / filter, 1.0 / samples);
					vibratoScale = (song.instrumentEffects[channel][pattern.instrument] == 2 && time - note.start < 3) ? 0.0 : Math.pow( 2.0, Music.effectVibratos[song.instrumentEffects[channel][pattern.instrument]] / 12.0 ) - 1.0;
				}

				if (channel == 0)
				{
					leadPeriodDelta = periodDelta;
					leadPeriodDeltaScale = periodDeltaScale;
					leadVolume = noteVolume * maxLeadVolume;
					leadVolumeDelta = volumeDelta * maxLeadVolume;
					leadFilter = filter * leadFilterBase;
					leadFilterScale = filterScale;
					leadVibratoScale = vibratoScale;
					if (resetPeriod)
					{
						leadSample = 0.0;
						leadPeriodA = 0.0;
						leadPeriodB = 0.0;
					}
				} 
				else if (channel == 1)
				{
					harmonyPeriodDelta = periodDelta;
					harmonyPeriodDeltaScale = periodDeltaScale;
					harmonyVolume = noteVolume * maxHarmonyVolume;
					harmonyVolumeDelta = volumeDelta * maxHarmonyVolume;
					harmonyFilter = filter * harmonyFilterBase;
					harmonyFilterScale = filterScale;
					harmonyVibratoScale = vibratoScale;
					if (resetPeriod)
					{
						harmonySample = 0.0;
						harmonyPeriodA = 0.0;
						harmonyPeriodB = 0.0;
					}
				} 
				else if (channel == 2)
				{
					bassPeriodDelta = periodDelta;
					bassPeriodDeltaScale = periodDeltaScale;
					bassVolume = noteVolume * maxBassVolume;
					bassVolumeDelta = volumeDelta * maxBassVolume;
					bassFilter = filter * bassFilterBase;
					bassFilterScale = filterScale;
					bassVibratoScale = vibratoScale;
					if (resetPeriod)
					{
						bassSample = 0.0;
						bassPeriodA = 0.0;
						bassPeriodB = 0.0;
					}
				}
				else if (channel == 3)
				{
					drumPeriodDelta = periodDelta / 32767.0;
					drumPeriodDeltaScale = periodDeltaScale;
					drumVolume = noteVolume * maxDrumVolume;
					drumVolumeDelta = volumeDelta * maxDrumVolume;
				}
			}

			var effectY:Float		= Math.sin(effectPeriod);
			var prevEffectY:Float	= Math.sin(effectPeriod - effectAngle);

			while (samples > 0)
			{
				var leadVibrato:Float		= 1.0 + leadVibratoScale    * effectY;
				var harmonyVibrato:Float	= 1.0 + harmonyVibratoScale * effectY;
				var bassVibrato:Float		= 1.0 + bassVibratoScale    * effectY;
				var leadTremelo:Float		= 1.0 + leadTremeloScale    * (effectY - 1.0);
				var harmonyTremelo:Float	= 1.0 + harmonyTremeloScale * (effectY - 1.0);
				var bassTremelo:Float		= 1.0 + bassTremeloScale    * (effectY - 1.0);

				var temp:Float				= effectY;
				effectY = effectYMult * effectY - prevEffectY;
				prevEffectY = temp;
				
				leadSample += ((leadWave[Std.int(leadPeriodA * leadWaveLength)] + leadWave[Std.int(leadPeriodB * leadWaveLength)] * leadChorusSign) * leadVolume * leadTremelo - leadSample) * leadFilter;
				leadVolume += leadVolumeDelta;
				leadPeriodA += leadPeriodDelta * leadVibrato * leadChorusA;
				leadPeriodB += leadPeriodDelta * leadVibrato * leadChorusB;
				leadPeriodDelta *= leadPeriodDeltaScale;
				leadPeriodA -= Std.int(leadPeriodA);
				leadPeriodB -= Std.int(leadPeriodB);
				leadFilter *= leadFilterScale;
				
				harmonySample += ((harmonyWave[Std.int(harmonyPeriodA * harmonyWaveLength)] + harmonyWave[Std.int(harmonyPeriodB * harmonyWaveLength)] * harmonyChorusSign) * harmonyVolume * harmonyTremelo - harmonySample) * harmonyFilter;
				harmonyVolume += harmonyVolumeDelta;
				harmonyPeriodA += harmonyPeriodDelta * harmonyVibrato * harmonyChorusA;
				harmonyPeriodB += harmonyPeriodDelta * harmonyVibrato * harmonyChorusB;
				harmonyPeriodDelta *= harmonyPeriodDeltaScale;
				harmonyPeriodA -= Std.int(harmonyPeriodA);
				harmonyPeriodB -= Std.int(harmonyPeriodB);
				harmonyFilter *= harmonyFilterScale;
				
				bassSample += ((bassWave[Std.int(bassPeriodA * bassWaveLength)] + bassWave[Std.int(bassPeriodB * bassWaveLength)] * bassChorusSign) * bassVolume * bassTremelo - bassSample) * bassFilter;
				bassVolume += bassVolumeDelta;
				bassPeriodA += bassPeriodDelta * bassVibrato * bassChorusA;
				bassPeriodB += bassPeriodDelta * bassVibrato * bassChorusB;
				bassPeriodDelta *= bassPeriodDeltaScale;
				bassPeriodA -= Std.int(bassPeriodA);
				bassPeriodB -= Std.int(bassPeriodB);
				bassFilter *= bassFilterScale;
				
				drumSample += (drumWave[Std.int(drumPeriod * 32767.0)] * drumVolume - drumSample) * drumFilter;
				drumVolume += drumVolumeDelta;
				drumPeriod += drumPeriodDelta;
				drumPeriodDelta *= drumPeriodDeltaScale;
				drumPeriod -= Std.int(drumPeriod);
				
				var instrumentSample:Float = leadSample + harmonySample + bassSample;
				
				// Reverb, implemented using a feedback delay network with a Hadamard matrix and lowpass filters.
				// good ratios:    0.555235 + 0.618033 + 0.818 +   1.0 = 2.991268
				// Delay lengths:  3041     + 3385     + 4481  +  5477 = 16384 = 2^14
				// Buffer offsets: 3041    -> 6426   -> 10907 -> 16384
				var delaySample0:Float = delayLine[delayPos] + instrumentSample;
				var delaySample1:Float = delayLine[(delayPos +  3041) & 0x3FFF];
				var delaySample2:Float = delayLine[(delayPos +  6426) & 0x3FFF];
				var delaySample3:Float = delayLine[(delayPos + 10907) & 0x3FFF];
				var delayTemp0:Float = -delaySample0 + delaySample1;
				var delayTemp1:Float = -delaySample0 - delaySample1;
				var delayTemp2:Float = -delaySample2 + delaySample3;
				var delayTemp3:Float = -delaySample2 - delaySample3;
				delayFeedback0 += ((delayTemp0 + delayTemp2) * reverb - delayFeedback0) * 0.5;
				delayFeedback1 += ((delayTemp1 + delayTemp3) * reverb - delayFeedback1) * 0.5;
				delayFeedback2 += ((delayTemp0 - delayTemp2) * reverb - delayFeedback2) * 0.5;
				delayFeedback3 += ((delayTemp1 - delayTemp3) * reverb - delayFeedback3) * 0.5;
				delayLine[(delayPos +  3041) & 0x3FFF] = delayFeedback0;
				delayLine[(delayPos +  6426) & 0x3FFF] = delayFeedback1;
				delayLine[(delayPos + 10907) & 0x3FFF] = delayFeedback2;
				delayLine[delayPos] = delayFeedback3;
				delayPos = (delayPos + 1) & 0x3FFF;
				
				var sample:Float = delaySample0 + delaySample1 + delaySample2 + delaySample3 + drumSample;
				
				var abs:Float = sample < 0.0 ? -sample : sample;
				limit -= limitDecay;
				if (limit < abs) limit = abs;
				sample /= limit * 0.75 + 0.25;
				sample *= volume;
				data.writeFloat(sample);
				data.writeFloat(sample);
				samples--;
			}

			if ( effectYMult * effectY - prevEffectY > prevEffectY ) effectPeriod = Math.asin( effectY );
			else effectPeriod = Math.PI - Math.asin( effectY );
			
			if (arpeggioSamples == 0)
			{
				arpeggio++;
				arpeggioSamples = samplesPerArpeggio;
				if (arpeggio == 4)
				{
					arpeggio = 0;
					part++;
					if (part == song.parts)
					{
						part = 0;
						beat++;
						if (beat == song.beats)
						{
							beat = 0;
							effectPeriod = 0.0;
							bar++;
							if (bar < song.loopStart) 
							{
								if (!enableIntro) bar = song.loopStart;
							}
							else enableIntro = false;
							
							if (bar >= song.loopStart + song.loopLength)
							{
								if (loopCount > 0) loopCount--;
								if (loopCount > 0 || !enableOutro) bar = song.loopStart;
							}
							if (bar >= song.bars)
							{
								bar = 0;
								enableIntro = true;
								ended = true;
								pause();
							}
							updateInstruments();
						}
					}
				}
			}
		}

		if (stutterPressed) stutterFunction();
		_playhead = (((arpeggio + 1.0 - arpeggioSamples / samplesPerArpeggio) / 4.0 + part) / song.parts + beat) / song.beats + bar;
	}

	// } endregion

	// { region UTILITIES **COMPLETE**
	
	private function frequencyFromPitch(pitch:Float):Float return 440.0 * Math.pow(2.0, (pitch - 69.0) / 12.0);
	private function volumeConversion(noteVolume:Float):Float return Math.pow(noteVolume / 3.0, 1.5);
	
	private function getSamplesPerArpeggio():Int
	{
		if (song == null) return 0;
		var beatsPerMinute:Float = song.getBeatsPerMinute();
		var beatsPerSecond:Float = beatsPerMinute / 60.0;
		var partsPerSecond:Float = beatsPerSecond * song.parts;
		var arpeggioPerSecond:Float = partsPerSecond * 4.0;
		return Math.floor(samplesPerSecond / arpeggioPerSecond);
	}

	// } endregion

}