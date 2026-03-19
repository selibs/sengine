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

		if (textIsDirty
			|| maxLineCountIsDirty
			|| wrapModeIsDirty
			|| ((left.positionIsDirty || right.positionIsDirty) && wrapMode != None)) {
			switch wrapMode {
				case None:
					var l = new StringBuf();
					lines = [];
					for (i in 0...text.length) {
						var c = text.charCodeAt(i);
						if (c == "\n".code) {
							lines.push({text: l.toString()});
							l = new StringBuf();
							if (lineCount == maxLineCount)
								break;
							else
								continue;
						}
						l.addChar(c);
					}
				case Anywhere:
					var k = fontAsset.asset._get(fontSize);
					var l = new StringBuf();
					var lw = 0.0;
					lines = [];
					for (i in 0...text.length) {
						var c = text.charCodeAt(i);
						var cw = @:privateAccess k.getCharWidth(c);
						if (c == "\n".code || lw + cw >= width.real) {
							lines.push({text: l.toString()});
							l = new StringBuf();
							lw = 0.0;
							if (lineCount == maxLineCount)
								break;
						}
						lw += cw;
						l.addChar(c);
						if (i == text.length - 1)
							lines.push({text: l.toString()});
					}
				case Word:
					var k = fontAsset.asset._get(fontSize);
					var l = new StringBuf();
					var w = new StringBuf();
					var lw = 0.0;
					var ww = 0.0;
					lines = [];
					for (i in 0...text.length) {
						var c = text.charCodeAt(i);
						var cw = @:privateAccess k.getCharWidth(c);

						if (c == " ".code || c == "\n".code) {
							if (lw + ww < width.real)
								l.add(w.toString());
							else {
								lines.push({text: l.toString()});
								if (lineCount == maxLineCount)
									break;
								l = w;
								lw = ww;
							}
							w = new StringBuf();
							w.addChar(c);
							ww = cw;
							continue;
						}

						ww += cw;
						w.addChar(c);

						if (i == text.length - 1)
							if (lw + ww < width.real)
								l.add(w.toString());
							else {
								lines.push({text: l.toString()});
								lines.push({text: w.toString()});
							}
					}
				default: // TODO
			}
		}

		// TODO
		if (linesIsDirty || elideModeIsDirty) {}

		if (linesIsDirty || fontSizeIsDirty) {
			textWidth = Math.NEGATIVE_INFINITY;
			textX = Math.POSITIVE_INFINITY;
			if ((alignment & AlignHCenter) != 0)
				for (l in lines) {
					l.width = fontAsset.asset.width(fontSize, l.text);
					l.x = hCenter.position - l.width * 0.5;
					textWidth = Math.max(textWidth, l.width);
					textX = Math.min(textX, l.x);
				}
			else if ((alignment & AlignRight) != 0)
				for (l in lines) {
					l.width = fontAsset.asset.width(fontSize, l.text);
					l.x = right.position - l.width;
					textWidth = Math.max(textWidth, l.width);
					textX = Math.min(textX, l.x);
				}
			else
				for (l in lines) {
					l.width = fontAsset.asset.width(fontSize, l.text);
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
