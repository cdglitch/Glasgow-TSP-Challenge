unit PM_TileSets;

interface

{$Mode ObjFpc}

uses
	PM_Image,
	PM_Utils,
	PM_Colour,
	PM_Debug;

type
	TilePositionDescriptor = object
			PositionX, PositionY: Int64;
			
			procedure Empty();
		end;
	TileSet = Object
			VisualData: Image;
			ImagePath: ANSIString;
			Tiles: Int64;
			TileWidth, TileHeight: Int64;
			TilesX, TilesY: Int64;
			TileOffsetX, TileOffsetY: Int64;
			TileSpacingX, TileSpacingY: Int64;
			TileColourization: array of Colour;
			TilePosition: array of TilePositionDescriptor;
			TilePropertyName: array of array of ANSIString;
			TilePropertyValue: array of array of ANSIString;
			TileProperties: array of Int64;
			
			procedure SetTileSize(X, Y: Int64);
			procedure SetTileOffset(X, Y: Int64);
			procedure SetTileSpacing(X, Y: Int64);
			procedure SetTileGrid(X, Y: Int64);
			
			procedure ColourizeTile(c, R, G, B, A: Int64);
			procedure ColourizeTileSet(R, G, B, A: Int64);
			
			procedure LoadFromImageFile(Src: ANSIString);
			
			procedure AddTileProperty(ID: Int64; Name, Value: ANSIString);
			
			procedure Calculate();
			procedure Empty();
			
			procedure DrawTile(X, Y, TileID: Int64);
		end;
	pTileSet = ^TileSet;

function BlankTileSet(): TileSet;

implementation

function BlankTileSet(): TileSet;
begin
	BlankTileSet.ImagePath := '';
	BlankTileSet.Tiles := 0;
	BlankTileSet.TileWidth := 0;
	BlankTileSet.TileHeight := 0;
	BlankTileSet.TilesX := 0;
	BlankTileSet.TilesY := 0;
	BlankTileSet.TileOffSetX := 0;
	BlankTileSet.TileOffSetY := 0;
	BlankTileSet.TileSpacingX := 0;
	BlankTileSet.TileSpacingY := 0;
end;

procedure TileSet.ColourizeTileSet(R, G, B, A: Int64);
var
	c: Int64;

begin
	if Length(TileColourization) < 1 then
		Exit;
	c := 0;
	repeat
		c += 1;
		ColourizeTile(c, R, G, B, A);
		until c >= Length(TileColourization);
end;

procedure TileSet.ColourizeTile(c, R, G, B, A: Int64);
begin
	if c > Length(TileColourization) then
		exit;
	TileColourization[c].SetRGBA(R, G, B, A);
end;

procedure TilePositionDescriptor.Empty();
begin
	PositionX := 0;
	PositionY := 0;
end;

procedure TileSet.Empty();
var
	c: Int64;
	
begin
	VisualData.Empty();
	if Length(TileColourization) > 0 then
		begin
			c := 0;
			repeat
				c := c + 1;
				TileColourization[c].Empty();
				until c >= Length(TileColourization);
		end;
	SetLength(TileColourization, 0);
	
	if Length(TilePosition) > 0 then
		begin
			c := 0;
			repeat
				c := c + 1;
				TilePosition[c].Empty();
				until c >= Length(TilePosition);
		end;
	SetLength(TilePosition, 0);
	
	EmptyIntArray(@TileProperties);
	if Length(TilePropertyName) > 0 then
		begin
			c := 0;
			repeat
				c := c + 1;
				EmptyStringArray(@TilePropertyName[c]);
				until c >= Length(TilePropertyName[c]);
		end;
	SetLength(TilePropertyName, 0, 0);
	
	if Length(TilePropertyValue) > 0 then
		begin
			c := 0;
			repeat
				c := c + 1;
				EmptyStringArray(@TilePropertyValue[c]);
				until c >= Length(TilePropertyValue[c]);
		end;
	SetLength(TilePropertyValue, 0, 0);
	
	TileOffSetX := 0;
	TileOffSetY := 0;
	TileSpacingX := 0;
	TileSpacingY := 0;
	TilesX := 0;
	TilesY := 0;
	TileWidth := 0;
	TileHeight := 0;
	Tiles := 0;
end;

procedure TileSet.SetTileSize(X, Y: Int64);
begin
	TileWidth := X;
	TileHeight := Y;
end;

procedure TileSet.SetTileOffset(X, Y: Int64);
begin
	TileOffSetX := X;
	TileOffSetY := Y;
end;

procedure TileSet.SetTileSpacing(X, Y: Int64);
begin
	TileSpacingX := X;
	TileSpacingY := Y;
end;

procedure TileSet.LoadFromImageFile(Src: ANSIString);
begin
	VisualData.Load(Src);
	ImagePath := Src;
end;

procedure TileSet.SetTileGrid(X, Y: Int64);
begin
	TilesX := X;
	TilesY := Y;
end;

procedure TileSet.AddTileProperty(ID: Int64; Name, Value: ANSIString);
begin
end;

procedure TileSet.Calculate();
var
	i: Int64;
	LoadX, LoadY: Int64;
	XCycle, YCycle: Int64;

begin
	Tiles := round(((VisualData.GetWidth - TileOffSetX) / (TileSpacingX + TileWidth)) * ((VisualData.GetHeight - TileOffSetY) / (TileSpacingY + TileHeight)) );
	writeln('Arperture: ', Tiles);
	SetLength(TileColourization, Tiles + 2);
	SetLength(TileProperties, Tiles + 2);
	SetLength(TilePosition, Tiles + 2);

	LoadY := TileOffSetY - (TileSpacingY + TileHeight);
	i := 0;
	YCycle := 0;
	repeat
		YCycle += 1;
		XCycle := 0;
		LoadY := LoadY + TileSpacingY + TileHeight;
		LoadX := TileOffSetX - (TileSpacingX + TileWidth);
		repeat
			XCycle += 1;
			i := i + 1;

			LoadX := LoadX + TileSpacingX + TileWidth;
			
			TileColourization[i].SetRGBA(255, 255, 255, 255);
			
			TilePosition[i].PositionX := LoadX;
			TilePosition[i].PositionY := LoadY;
			until (LoadX >= VisualData.GetWidth - (TileWidth + TileSpacingX)) or (XCycle >= TilesX);
		until (LoadY >= VisualData.GetHeight - (TileHeight + TileSpacingY)) or (YCycle >= TilesY);
end;

procedure TileSet.DrawTile(X, Y, TileID: Int64);
var
	DefCol: Colour;
	
begin
	DefCol := VisualData.Colourization;
	VisualData.Colourization := TileColourization[TileID];
	if (TileID > 0) then
			VisualData.DrawSelection(TilePosition[TileID].PositionX, TilePosition[TileID].PositionY, TileWidth, TileHeight, X, Y);
	VisualData.Colourization := DefCol;
end;

begin
end.
