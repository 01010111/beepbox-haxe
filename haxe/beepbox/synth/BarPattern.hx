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

class BarPattern
{

	public var notes:Array<Note>;
	public var instrument:Int;

	public function new()
	{
		notes = [];
		instrument = 0;
	}

	public function cloneNotes():Array<Note>
	{
		var result = [];
		for (oldNote in notes)
		{
			var newNote = new Note(-1, oldNote.start, oldNote.end, 3);
			newNote.pitches = oldNote.pitches.concat([]);
			newNote.pins = [];
			for (oldPin in oldNote.pins) newNote.pins.push(new NotePin(oldPin.interval, oldPin.time, oldPin.volume));
			result.push(newNote);
		}
		return result;
	}

}