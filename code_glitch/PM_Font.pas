{
	* NOTE: As the PM Library always stores its data starting at 1 and ZenGL does not, there is some offset-fu in this code...
	* This was is not intended as *THE* font system for Prometheus, however it is the most convenient to work with due to its utilities...
}

unit PM_Font;

{$Mode ObjFpc}

interface

uses
	PM_Colour,
	PM_Image,
	Gl;

type
	ZFIFontCharacter = Packed Record
			XOffset, YOffSet: Int64;
			Width, Height: Int64;
			PageLocation: Int64;
			CShift: Int64;
			GWidth, GHeight: Int64;
			SourcePageStartX, SourcePageStartY, SourcePageEndX, SourcePageEndY: Int64;
			CharCode: Int64;
		end;
	ZFIFont = Object
	Public
			//private
				PageData: array of Image;
				Pages: Int64;
				
				CharacterData: array of ZFIFontCharacter;
				Characters: Int64;
				
				MaxCharacterHeight, MaxCharacterOffsetY, MaxFontPadding: Int64;
			
				procedure LoadZFI(Src: ANSIString);
				procedure LoadImages(Src: ANSIString);
				function ResolveCharCode(n: Int64): Int64;
				
			//public
				procedure Load(Src: ANSIString);
				procedure Empty();
				procedure DrawText(Txt: ANSIString; X,Y: Int64; Col: Colour);
				function GetRenderedWidth(Txt: ANSIString): Int64;
				function GetRenderedHeight(Txt: ANSIString): Int64;
		end;
	pZFIFont = ^ZFIFont;

implementation

uses
	PM_MemUtils,
	PM_Utils,
	PM_textUtils;

function ZFIFont.ResolveCharCode(n: Int64): Int64;
var
	c: Int64;

begin
	ResolveCharCode := 0;
	if Characters <=0 then
		Exit;
	
	c := 0;
	repeat
		c += 1;
		if CharacterData[c].CharCode = n then
			begin
				ResolveCharCode := c;
				Exit;
			end;
		until c >= Characters;
end;

procedure ZFIFont.LoadImages(Src: ANSIString);
var
	c: Int64;
	
begin
	if Pages <= 0 then
		Exit;
	
	SetLength(PageData, Pages + 1);
	
	c := 0;
	repeat
		c += 1;
		//writeln('Loading ',Src + '-page' + IntToStr(c - 1) + '.tga...');
		PageData[c].Load(Src + '-page' + IntToStr(c - 1) + '.tga');
		until c >= Pages;
end;

procedure ZFIFont.Empty();
begin
end;

procedure ZFIFont.DrawText(Txt: ANSIString; X,Y: Int64; Col: Colour);
var
	c, index: Int64;
	DrawX: Int64;
	
begin
	glEnable(GL_TEXTURE_2D);
	if (Length(Txt) <= 0) or (Characters <= 0) then
		Exit;

	index := ResolveCharCode(Ord(Txt[1]));
	Y := Y - (CharacterData[index].SourcePageEndY - CharacterData[index].SourcePageStartY);
	//DrawX := X + (CharacterData[index].SourcePageEndX - CharacterData[index].SourcePageStartX);
	DrawX := X;
	c := 0;
	repeat
		c += 1;
		if Txt[c] = #10 then
			begin
				DrawX := X;
				Y := Y + MaxCharacterHeight;
			end;
		index := ResolveCharCode(Ord(Txt[c]));
		PageData[CharacterData[index].PageLocation].Colourization := Col;
		PageData[CharacterData[index].PageLocation].DrawSelection(CharacterData[index].SourcePageStartX, CharacterData[index].SourcePageStartY,
			CharacterData[index].SourcePageEndX - CharacterData[index].SourcePageStartX, (CharacterData[index].SourcePageEndY - CharacterData[index].SourcePageStartY),
			//CharacterData[index].Width, CharacterData[index].Height,
			//CharacterData[index].GWidth, CharacterData[index].GHeight,
		
			DrawX + CharacterData[index].XOffset, Y + CharacterData[index].YOffSet);
		
		//writeln('Draw char [',Txt[c],'] from:[',CharacterData[index].SourcePageStartX,',',CharacterData[index].SourcePageStartY,'] width:[',CharacterData[index].SourcePageEndX - CharacterData[index].SourcePageStartX,',', CharacterData[index].SourcePageEndY - CharacterData[index].SourcePageStartY,'] to [',DrawX + CharacterData[index].XOffset,',', Y + CharacterData[index].YOffSet,']');
		//DrawX += CharacterData[c].CShift;
		//writeln('XO ',CharacterData[index].XOffset);
		DrawX += CharacterData[index].CShift;
		until c >= Length(Txt);
end;

function ZFIFont.GetRenderedHeight(Txt: ANSIString): Int64;
var
	c, index: Int64;
	YHeight: Int64;
	
begin
	if Characters > 0 then
		GetRenderedHeight := abs(CharacterData[ResolveCharCode(ord('Z'))].SourcePageEndY - CharacterData[ResolveCharCode(ord('Z'))].SourcePageStartY)
	else
		GetRenderedHeight := 25; //an arbitrary value...
		
	if (Length(Txt) <= 0) or (Characters <= 0) then
		Exit;
	
	YHeight := 0;
	c := 0;
	repeat
		c += 1;
		index := ResolveCharCode(Ord(Txt[c]));
		
		if (index <= Characters) then
			begin
				if (abs(CharacterData[index].SourcePageEndY - CharacterData[index].SourcePageStartY) > YHeight) then
					YHeight := abs(CharacterData[index].SourcePageEndY - CharacterData[index].SourcePageStartY);
			end;
		until c >= Length(Txt);
	GetRenderedHeight := YHeight;
end;

function ZFIFont.GetRenderedWidth(Txt: ANSIString): Int64;
var
	c, index: Int64;
	DrawX: Int64;
	
begin
	if Characters > 0 then
		GetRenderedWidth := abs(CharacterData[ResolveCharCode(ord('Z'))].CShift)
	else
		GetRenderedWidth := 20; //an arbitrary value

	if (Length(Txt) <= 0) or (Characters <= 0) then
		Exit;

	DrawX := 0;
	c := 0;
	repeat
		c += 1;
		index := ResolveCharCode(Ord(Txt[c]));
		DrawX += CharacterData[index].CShift;
		until c >= Length(Txt);
	DrawX += CharacterData[index].CShift; //This produces nicer results most of the time...
	GetRenderedWidth := DrawX;
	//writeln('GRW ',DrawX);
end;

procedure ZFIFont.Load(Src: ANSIString);
begin
	LoadZFI(Src);
end;

procedure ZFIFont.LoadZFI(Src: ANSIString);
var
	SrcData: RAMFile;
	c16: Char2;
	c32: Char4;
	c: Int64;
	NameSrc: ANSIString;
	Delta: Int64;
	
begin
	NameSrc := Src;
	Src += '.zfi';
	if DoesFileExist(Src) = False then
		Exit;
	
	Empty();
	
	SrcData.LoadFromDisk(Src);
	if ByteArrayIsEqual(SrcData.GetNextBytes(13), StrToByteArray('ZGL_FONT_INFO')) = False then
		Exit;
		//writeln('ZGL header is valid!');
	
	SrcData.ReadPosition -= 1;
	
	c16[1] := SrcData.GetNextChar();
	c16[2] := SrcData.GetNextChar();
	Pages := BytesToInt16(c16);
	SetLength(PageData, Pages + 1);
	//writeln('BYTES [',Ord(c16[1]),Ord(c16[2]),']');
	//writeln('Stream size: ',SrcData.DataLength);
	//writeln('Read ',Pages,' pages');
	
	//writeln('Beginning IMG load...');
	LoadImages(NameSrc);
	//writeln('Complete!');
	
	c16[1] := SrcData.GetNextChar();
	c16[2] := SrcData.GetNextChar();
	Characters := {SwapEndian}(BytesToInt16(c16));
	SetLength(CharacterData, Characters + 1);
	//writeln('Read ',Characters,' chars');
	
	c32[1] := SrcData.GetNextChar();
	c32[2] := SrcData.GetNextChar();
	c32[3] := SrcData.GetNextChar();
	c32[4] := SrcData.GetNextChar();
	MaxCharacterHeight := {SwapEndian}(BytesToInt32(c32));
	//writeln('Read ',MaxCharacterHeight,' MaxHeight');
	
	c32[1] := SrcData.GetNextChar();
	c32[2] := SrcData.GetNextChar();
	c32[3] := SrcData.GetNextChar();
	c32[4] := SrcData.GetNextChar();
	MaxCharacterOffsetY := {SwapEndian}(BytesToInt32(c32));
	//writeln('Read ',MaxCharacterOffsetY,' MaxYOffset');
	
	c32[1] := SrcData.GetNextChar();
	c32[2] := SrcData.GetNextChar();
	c32[3] := SrcData.GetNextChar();
	c32[4] := SrcData.GetNextChar();
	MaxFontPadding := {SwapEndian}(BytesToInt32(c32));
	//writeln('Read ',MaxFontPadding,' MaxPadding');
	
	c := 0;
	repeat
		c += 1;
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		CharacterData[c].CharCode := {SwapEndian}(BytesToInt32(c32));
		//writeln('Read char[',c,'].code=', CharacterData[c].CharCode);
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		
		//I really dont like this BUT ZenGL stores the page number as a 16 bit word but read 32 bits of data...
		//Having analyzed the data it looks like the first two are what we actually need... I think.
		c16[1] := c32[1];
		c16[2] := c32[2];
		CharacterData[c].PageLocation := {SwapEndian}(BytesToInt16(c16)) + 1; //the data here starts at page 0 but PM starts at 1...
		//writeln('Read char[',c,'].page=', CharacterData[c].PageLocation,'  Bytes[',Ord(c32[1]),' ',Ord(c32[2]),' ',Ord(c32[3]),' ',Ord(c32[4]),'] code=',CharacterData[c].CharCode);
		//CharacterData[c].PageLocation := 1;
		
		CharacterData[c].Width := Ord(SrcData.GetNextChar());
		//writeln('Read char[',c,'].width=', CharacterData[c].Width);
		CharacterData[c].Height := Ord(SrcData.GetNextChar());
		//writeln('Read char[',c,'].height=', CharacterData[c].Height);
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		CharacterData[c].XOffset := {SwapEndian}(BytesToInt32(c32));
		//writeln('Read char[',c,'].XOffset=', CharacterData[c].XOffset);
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		CharacterData[c].YOffSet := {SwapEndian}(BytesToInt32(c32));
		//writeln('Read char[',c,'].YOffset=', CharacterData[c].YOffSet);
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		//This the 'P' offset. I have no idea what it does...
		CharacterData[c].CShift := BytesToInt32(c32);
		//writeln('Read char[',c,'].CShift=', CharacterData[c].CShift);
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		//Coord 0 (x)
		CharacterData[c].SourcePageStartX := round(BytesToSingle32(c32) * PageData[CharacterData[c].PageLocation].Width);
		//writeln('Read char[',c,'].c0x=', {SwapEndian}trunc(BytesToSingle32(c32) * 512));
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		//Coord 0 (y)
		//writeln('Read char[',c,'].c0y=', {SwapEndian}trunc(BytesToSingle32(c32) * 512));
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		//Coord 1 (x)
		//writeln('Read char[',c,'].c1x=', {SwapEndian}trunc(BytesToSingle32(c32) * 512));
		//writeln('Character Page location: ',CharacterData[c].PageLocation);
		CharacterData[c].SourcePageEndX := round(BytesToSingle32(c32) * PageData[CharacterData[c].PageLocation].Width);
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		//Coord 1 (y)
		//writeln('Read char[',c,'].c1y=', {SwapEndian}trunc(BytesToSingle32(c32) * 512));
		CharacterData[c].SourcePageEndY := PageData[CharacterData[c].PageLocation].Height - round(BytesToSingle32(c32) * PageData[CharacterData[c].PageLocation].Height);
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		//Coord 2 (x)
		//writeln('Read char[',c,'].c2x=', {SwapEndian}trunc(BytesToSingle32(c32) * 512));
		
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		//Coord 2 (y)
		CharacterData[c].SourcePageStartY := PageData[CharacterData[c].PageLocation].Height - round(BytesToSingle32(c32) * PageData[CharacterData[c].PageLocation].Height);
		//writeln('Read char[',c,'].c2y=', {SwapEndian}trunc(BytesToSingle32(c32) * 512));
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		//Coord 3 (x)
		//writeln('Read char[',c,'].c3x=', {SwapEndian}trunc(BytesToSingle32(c32) * 512));
		
		c32[1] := SrcData.GetNextChar();
		c32[2] := SrcData.GetNextChar();
		c32[3] := SrcData.GetNextChar();
		c32[4] := SrcData.GetNextChar();
		//Coord 3 (y)
		//writeln('Read char[',c,'].c3y=', {SwapEndian}trunc(BytesToSingle32(c32) * 512));
		
		//Now we need to correct for the fact that ZenGL uses the lower right vertex as the origin...
		
		with CharacterData[c] do
			begin
				Delta := abs(SourcePageEndX - SourcePageStartX);
				//SourcePageStartX := SourcePageStartX - Delta;
				//SourcePageEndX := SourcePageEndX + Delta;
				GWidth := Delta;
				
				Delta := abs(SourcePageEndY - SourcePageStartY);
				//SourcePageStartY := SourcePageStartY - Delta;
				//SourcePageEndY := SourcePageEndY + Delta;
				GHeight := Delta;
				
				//writeln('Char c start [',SourcePageStartX,',',SourcePageStartY,'] end [',SourcePageEndX,',',SourcePageEndY,']');
			end;
		
		until c >= Characters;
end;

begin
end.
