package s.markup.elements;

import s.system.Texture;
import s.markup.Alignment;

enum ElideMode {
	/**(default)**/
	None;

	Left;
	Middle;
	Right;
}

enum WrapMode {
	/**(default)**/
	None;

	Word;
	Anywhere;
	Wrap;
}

enum LineHeightMode {
	/**(default)**/
	Proportional;

	Fixed;
}

class Text extends Label {
	@:attr var lines:Array<TextLine> = [];

	@:attr public var wrapMode:WrapMode = None;
	@:attr public var elideMode:ElideMode = None;

	@:attr public var lineHeight:Float = 1.0;
	@:attr public var lineHeightMode:LineHeightMode = Proportional;
	@:attr public var maxLineCount:Int = -1;

	@:readonly @:alias var lineCount:Int = lines.length;

	public function new(text:String = "") {
		super(text);
	}

	override function draw(target:Texture) {
		if (text.length == 0 || !fontAsset.isLoaded || fontSize == 0)
			return;
		final ctx = target.context2D;
		ctx.style.font = fontAsset;
		ctx.style.fontSize = fontSize;
		ctx.style.color = color;
		for (line in lines)
			ctx.drawString(line.text, line.x, line.y);
	}

	override function syncText() {
		if (!fontAsset.isLoaded)
			return;

		final elideRelayoutIsDirty = elideMode != None
			&& (elideModeIsDirty || height.realIsDirty || width.realIsDirty || fontSizeIsDirty || lineHeightIsDirty || lineHeightModeIsDirty);

		if (textIsDirty || fontSizeIsDirty || maxLineCountIsDirty || wrapModeIsDirty || (width.realIsDirty && wrapMode != None) || elideRelayoutIsDirty)
			wrapText();

		if (elideMode != None && (linesIsDirty || elideRelayoutIsDirty))
			elideText();

		if (linesIsDirty || fontSizeIsDirty) {
			textWidth = Math.NEGATIVE_INFINITY;
			textX = Math.POSITIVE_INFINITY;
			if ((alignment & AlignHCenter) != 0)
				for (l in lines) {
					l.x = hCenter.position - l.width * 0.5;
					textWidth = Math.max(textWidth, l.width);
					textX = Math.min(textX, l.x);
				}
			else if ((alignment & AlignRight) != 0)
				for (l in lines) {
					l.x = right.position - l.width;
					textWidth = Math.max(textWidth, l.width);
					textX = Math.min(textX, l.x);
				}
			else
				for (l in lines) {
					l.x = left.position;
					textWidth = Math.max(textWidth, l.width);
					textX = Math.min(textX, l.x);
				}
		} else {
			if ((alignmentIsDirty || hCenter.positionIsDirty) && (alignment & AlignHCenter) != 0)
				for (l in lines)
					l.x = hCenter.position - l.width * 0.5;
			else if ((alignmentIsDirty || right.positionIsDirty) && (alignment & AlignRight) != 0)
				for (l in lines)
					l.x = right.position - l.width;
			else if (alignmentIsDirty || left.positionIsDirty)
				for (l in lines)
					l.x = left.position;
		}

		if (linesIsDirty || fontSizeIsDirty || lineHeightIsDirty || lineHeightModeIsDirty) {
			var realLineHeight = switch lineHeightMode {
				case Proportional: fontSize * lineHeight;
				case Fixed: lineHeight;
			}
			for (l in lines)
				l.height = realLineHeight;
			textHeight = lineCount * realLineHeight;
		}

		var vDirty = alignmentIsDirty || textHeightIsDirty;

		if ((vDirty || vCenter.positionIsDirty) && (alignment & AlignVCenter) != 0)
			textY = vCenter.position - textHeight * 0.5;
		else if ((vDirty || bottom.positionIsDirty) && (alignment & AlignBottom) != 0)
			textY = bottom.position - textHeight;
		else if (vDirty || top.positionIsDirty)
			textY = top.position;

		if (linesIsDirty || textYIsDirty)
			for (i in 0...lineCount)
				lines[i].y = textY + lines[i].height * i;
	}

	function wrapText() {
		var k = fontAsset.asset._get(fontSize);
		var maxWidth = Math.abs(width.real);
		lines = [];

		inline function isNewline(c:Int):Bool
			return c == "\n".code || c == "\r".code || c == 0x85 || c == 0x2028 || c == 0x2029;

		inline function isSpace(c:Int):Bool
			return switch c {
				case "\t".code, 0x0B, 0x0C, " ".code, 0xA0, 0x1680, 0x202F, 0x205F, 0x3000: true;
				case _ if (0x2000 <= c && c <= 0x200A): true;
				case _: false;
			}

		inline function charWidth(c:Int):Float
			return @:privateAccess k.getCharWidth(c);

		inline function maxReached():Bool
			return maxLineCount >= 0 && lineCount >= maxLineCount;

		inline function nextCharIndex(i:Int, c:Int):Int {
			if (c == "\r".code && i + 1 < text.length && text.charCodeAt(i + 1) == "\n".code)
				return i + 2;
			return i + 1;
		}

		function pushLine(line:String, lineWidth:Float):Bool {
			lines.push({text: line, width: lineWidth});
			return maxReached();
		}

		function wrapWord(word:String, line:StringBuf, lineWidth:Float):{line:StringBuf, lineWidth:Float, stop:Bool} {
			if (word.length == 0)
				return {line: line, lineWidth: lineWidth, stop: false};

			if (maxWidth <= 0) {
				if (lineWidth > 0 && pushLine(line.toString(), lineWidth))
					return {line: new StringBuf(), lineWidth: 0.0, stop: true};
				if (pushLine(word, k.stringWidth(word)))
					return {line: new StringBuf(), lineWidth: 0.0, stop: true};
				return {line: new StringBuf(), lineWidth: 0.0, stop: false};
			}

			var current = line;
			var currentWidth = lineWidth;
			var i = 0;
			while (i < word.length) {
				if (currentWidth > 0) {
					var c = word.charCodeAt(i);
					var cw = charWidth(c);
					if (currentWidth + cw > maxWidth) {
						if (pushLine(current.toString(), currentWidth))
							return {line: new StringBuf(), lineWidth: 0.0, stop: true};
						current = new StringBuf();
						currentWidth = 0.0;
						continue;
					}
					current.addChar(c);
					currentWidth += cw;
					i++;
					continue;
				}

				var part = new StringBuf();
				var partWidth = 0.0;
				while (i < word.length) {
					var c = word.charCodeAt(i);
					var cw = charWidth(c);
					if (partWidth > 0 && partWidth + cw > maxWidth)
						break;
					part.addChar(c);
					partWidth += cw;
					i++;
				}

				if (partWidth == 0.0) {
					var c = word.charCodeAt(i);
					part.addChar(c);
					partWidth = charWidth(c);
					i++;
				}

				current.add(part.toString());
				currentWidth = partWidth;
				if (i < word.length) {
					if (pushLine(current.toString(), currentWidth))
						return {line: new StringBuf(), lineWidth: 0.0, stop: true};
					current = new StringBuf();
					currentWidth = 0.0;
				}
			}

			return {line: current, lineWidth: currentWidth, stop: false};
		}

		switch wrapMode {
			case None:
				var line = new StringBuf();
				var i = 0;
				while (i < text.length) {
					var c = text.charCodeAt(i);
					if (isNewline(c)) {
						var str = line.toString();
						if (pushLine(str, k.stringWidth(str)))
							return;
						line = new StringBuf();
						i = nextCharIndex(i, c);
						continue;
					}
					line.addChar(c);
					i++;
				}
				if (!maxReached()) {
					var str = line.toString();
					pushLine(str, k.stringWidth(str));
				}
			case Anywhere:
				var line = new StringBuf();
				var lineWidth = 0.0;
				var i = 0;
				while (i < text.length) {
					var c = text.charCodeAt(i);
					if (isNewline(c)) {
						if (pushLine(line.toString(), lineWidth))
							return;
						line = new StringBuf();
						lineWidth = 0.0;
						i = nextCharIndex(i, c);
						continue;
					}

					var cw = charWidth(c);
					if (lineWidth > 0 && maxWidth > 0 && lineWidth + cw > maxWidth) {
						if (pushLine(line.toString(), lineWidth))
							return;
						line = new StringBuf();
						lineWidth = 0.0;
					}

					line.addChar(c);
					lineWidth += cw;
					i++;
				}
				if (!maxReached())
					pushLine(line.toString(), lineWidth);
			case Word, Wrap:
				var line = new StringBuf();
				var lineWidth = 0.0;
				var word = new StringBuf();
				var wordWidth = 0.0;

				function flushWord():Bool {
					if (word.length == 0)
						return false;

					var value = word.toString();
					if (wrapMode == Word || wordWidth <= maxWidth || maxWidth <= 0) {
						if (lineWidth > 0 && maxWidth > 0 && lineWidth + wordWidth > maxWidth) {
							if (pushLine(line.toString(), lineWidth))
								return true;
							line = new StringBuf();
							lineWidth = 0.0;
						}
						line.add(value);
						lineWidth += wordWidth;
					} else {
						var wrapped = wrapWord(value, line, lineWidth);
						line = wrapped.line;
						lineWidth = wrapped.lineWidth;
						if (wrapped.stop)
							return true;
					}

					word = new StringBuf();
					wordWidth = 0.0;
					return false;
				}

				var i = 0;
				while (i < text.length) {
					var c = text.charCodeAt(i);

					if (isNewline(c)) {
						if (flushWord())
							return;
						if (pushLine(line.toString(), lineWidth))
							return;
						line = new StringBuf();
						lineWidth = 0.0;
						i = nextCharIndex(i, c);
						continue;
					}

					if (isSpace(c)) {
						if (flushWord())
							return;
						var cw = charWidth(c);
						if (lineWidth > 0) {
							if (maxWidth > 0 && lineWidth + cw > maxWidth) {
								if (pushLine(line.toString(), lineWidth))
									return;
								line = new StringBuf();
								lineWidth = 0.0;
							} else {
								line.addChar(c);
								lineWidth += cw;
							}
						}
						i++;
						continue;
					}

					word.addChar(c);
					wordWidth += charWidth(c);
					i++;
				}

				if (flushWord())
					return;
				if (!maxReached())
					pushLine(line.toString(), lineWidth);
		}
	}

	function elideText() {
		if (lineCount == 0)
			return;

		final maxHeight = Math.abs(height.real);
		final realLineHeight = switch lineHeightMode {
			case Proportional: fontSize * lineHeight;
			case Fixed: lineHeight;
		}
		var visibleHeight = lineCount * realLineHeight;
		var removedLines = false;
		var changed = false;

		if (elideMode == Left) {
			while (lineCount > 1 && visibleHeight > maxHeight) {
				lines.shift();
				visibleHeight -= realLineHeight;
				removedLines = true;
				changed = true;
			}
			changed = elideLine(lines[0], removedLines) || changed;
		} else if (elideMode == Middle) {
			while (lineCount > 1 && visibleHeight > maxHeight) {
				lines.shift();
				visibleHeight -= realLineHeight;
				removedLines = true;
				changed = true;
				if (lineCount > 1 && visibleHeight > maxHeight) {
					lines.pop();
					visibleHeight -= realLineHeight;
					changed = true;
				}
			}
			changed = elideLine(lines[Std.int(lineCount * 0.5)], removedLines) || changed;
		} else if (elideMode == Right) {
			while (lineCount > 1 && visibleHeight > maxHeight) {
				lines.pop();
				visibleHeight -= realLineHeight;
				removedLines = true;
				changed = true;
			}
			changed = elideLine(lines[lineCount - 1], removedLines) || changed;
		}

		if (changed) {
			linesIsDirty = true;
			textHeight = visibleHeight;
		}
	}

	function elideLine(line:TextLine, forceEllipsis:Bool = false):Bool {
		static final ellipsis = "...";

		final k = fontAsset.asset._get(fontSize);
		final ellipsisWidth = k.stringWidth(ellipsis);
		final totalWidth = Math.abs(width.real);

		inline function charWidth(c:Int):Float
			return @:privateAccess k.getCharWidth(c);

		if (!forceEllipsis && line.width <= totalWidth)
			return false;

		if (totalWidth <= ellipsisWidth || line.text.length == 0) {
			line.text = ellipsis;
			line.width = ellipsisWidth;
			return true;
		}

		final maxWidth = totalWidth - ellipsisWidth;

		if (elideMode == Left) {
			var body = "";
			var bodyWidth = 0.0;
			var i = line.text.length - 1;
			while (i >= 0) {
				var c = line.text.charCodeAt(i);
				var cw = charWidth(c);
				if (bodyWidth + cw > maxWidth)
					break;
				body = line.text.charAt(i) + body;
				bodyWidth += cw;
				i--;
			}
			line.text = ellipsis + body;
			line.width = ellipsisWidth + bodyWidth;
		} else if (elideMode == Middle) {
			var left = new StringBuf();
			var right = "";
			var leftWidth = 0.0;
			var rightWidth = 0.0;
			var leftIndex = 0;
			var rightIndex = line.text.length - 1;
			var takeLeft = true;

			while (leftIndex <= rightIndex) {
				var index = takeLeft ? leftIndex : rightIndex;
				var c = line.text.charCodeAt(index);
				var cw = charWidth(c);
				if (leftWidth + rightWidth + cw > maxWidth)
					break;
				if (takeLeft) {
					left.addChar(c);
					leftWidth += cw;
					leftIndex++;
				} else {
					right = line.text.charAt(index) + right;
					rightWidth += cw;
					rightIndex--;
				}
				takeLeft = !takeLeft;
			}

			line.text = left.toString() + ellipsis + right;
			line.width = leftWidth + ellipsisWidth + rightWidth;
		} else if (elideMode == Right) {
			var body = new StringBuf();
			var bodyWidth = 0.0;
			var i = 0;
			while (i < line.text.length) {
				var c = line.text.charCodeAt(i);
				var cw = charWidth(c);
				if (bodyWidth + cw > maxWidth)
					break;
				body.addChar(c);
				bodyWidth += cw;
				i++;
			}
			line.text = body.toString() + ellipsis;
			line.width = bodyWidth + ellipsisWidth;
		}

		return true;
	}
}

@:structInit
@:allow(s.markup.elements.Text)
private class TextLine {
	var text:String;
	var width:Float = 0.0;
	var height:Float = 0.0;
	var x:Float = 0.0;
	var y:Float = 0.0;
}
