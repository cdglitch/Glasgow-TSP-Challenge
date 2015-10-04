unit PM_Maps; //PM_MAPS_G2 PSEUDO

{$Mode Delphi}

interface

uses
	PM_Debug,
	PM_TileSets,
	PM_Utils,
	PM_TextUtils,
	PM_Window;

type
	TileDataHandler = Object
			TileData: array of TileSet;
			TileSets: Int64;
			
			TileSetStart: array of Int64;
			GlobalTileWidth, GlobalTileHeight: Int64;
			
			TileDataLoaded: array of Boolean;
			TileSetName: array of ANSIString;
			
			MemoryBlockSize: Int64;
			MemoryAllocated: Int64;
			
			procedure NewMemoryBlockSize(Sze: Int64);
			procedure DrawTile(Id, X, Y: Int64);
			procedure SetTileSetName(Id: Int64; Nme: ANSIString);
			procedure SetTileSize(X, Y: Int64);
			procedure AddTileSet(Ts: TileSet; Start: Int64);
			function GetLastTileSet(): pTileSet;
			
			private
				procedure NormalizeGIDs();
		end;
	pTileDataHandler = ^TileDataHandler;
	PropertyValue = Object
			Name: ANSIString;
			Value: ANSIString;
			
			procedure Empty();
			procedure Define(Nme, Val: ANSIString);
		end;
	PropertyHandler = Object
			PropertyData: array of PropertyValue;
			Properties: Int64;
			
			procedure AddProperty(Nme, Val: ANSIString);
			procedure DelProperty(Nme: ANSIString);
			procedure ModProperty(Nme, Val: ANSIString);
			function GetPropertyIdByName(Nme: ANSIString): Int64;
		end;
			
	MapLayer = Object
			TileCode: array of array of Int64;
			Width, Height: Int64;
			Name: ANSIString;
			Visible: Boolean;
			OffsetX, OffsetY: Int64;
			TileWidth, TileHeight: Int64;
			
			TileHandlerLocation: pTileDataHandler;
			
			LayerProperties: PropertyHandler;
			
			Loaded: Boolean;
			
			procedure SetSize(X,Y: Int64);
			procedure SetOffset(X,Y: Int64);
			procedure SetName(Nme: ANSIString);
			procedure LoadTileCodesFromCsv(Data: ANSIString);
			procedure SetVisibility(Val: Boolean);
			procedure SetTileSize(X, Y: Int64);
			
			procedure Draw(X, Y: Int64);
			
			procedure Empty();
		end;
	Map = Object
			SourceDirectory, SourceFile: ANSIString;
			
			TileHandler: TileDataHandler;
	
			Layer: array of MapLayer;
			Layers: Int64;
			
			MapProperty: array of PropertyValue;
			MapProperties: Int64;
			
			procedure LoadFromTMX(Folder, Src: ANSIString);
			procedure Draw(X, Y: Int64);
			procedure Empty();
		end;

implementation

function TileDataHandler.GetLastTileSet(): pTileSet;
begin
	GetLastTileSet := @TileData[TileSets];
end;

procedure TileDataHandler.NormalizeGIDs();
var
	c: Int64;
	
begin
	if TileSets = 0 then
		Exit;
		
	c := 0;
	repeat
		c += 1;
		until c >= TileSets;
end;

procedure TileDataHandler.NewMemoryBlockSize(Sze: Int64);
begin
	MemoryBlockSize := Sze;
end;

procedure TileDataHandler.AddTileSet(Ts: TileSet; Start: Int64);
var
	c: Int64;
	NewMemSize: Int64;
	
begin
	if TileSets = 0 then
		MemoryAllocated := 0;
	
	if MemoryBlockSize < 1 then
		MemoryBlockSize := 1;
	
	TileSets += 1;
	c := TileSets;
	
	NewMemSize := 0;
	if MemoryAllocated < TileSets + 1 then
		begin
			repeat
				NewMemSize += MemoryBlockSize;
				until NewMemSize > TileSets + 1;
		end;
	
	SetLength(TileSetStart, NewMemSize);
	TileSetStart[c] := Start;
	SetLength(TileDataLoaded, NewMemSize);
	TileDataLoaded[c] := True;
	SetLength(TileData, NewMemSize);
	TileData[c] := Ts;
end;

procedure TileDataHandler.SetTileSize(X, Y: Int64);
begin
	GlobalTileWidth := X;
	GlobalTileHeight := Y;
end;

procedure TileDataHandler.DrawTile(Id, X, Y: Int64);
var
	c: Int64;

begin
	if Id = 0 then
		begin
			Exit;
		end;
		
	if TileSets < 1 then
		begin
			Exit;
		end;
	
	if (TileSets = 1) and (TileSetStart[1] <= 1) and (TileData[1].Tiles >= Id) then
		begin
			TileData[1].DrawTile(X, Y,Id);
			Exit;
		end;
		
	c := 1;
	repeat
		c += 1;
		if (TileSetStart[c] <= Id) and (TileData[c].Tiles + TileSetStart[c] >= Id) then
			begin
				TileData[c].DrawTile(X, Y, (Id + 1) - TileSetStart[c]);
				Break;
			end;
		until (c >= TileSets);
end;

procedure TileDataHandler.SetTileSetName(Id: Int64; Nme: ANSIString);
begin
	TileSetName[Id] := Nme;
end;

procedure MapLayer.SetTileSize(X, Y: Int64);
begin
	TileWidth := X;
	TileHeight := Y;
end;

procedure Map.Draw(X, Y: Int64);
var
	c: Int64;
	
begin
	c := 0;
	repeat
		c += 1;
		Layer[c].Draw(X + Layer[c].OffsetX, Y + Layer[c].OffsetY);
		until c >= Layers;
end;

procedure MapLayer.Empty();
begin
end;

procedure Map.LoadFromTMX(Folder, Src: ANSIString);
var
	Path: ANSIString;
	
	c: Int64;
	t: Int64;
	
	pwts: pTileSet;
	MaxTileWidth, MaxTileHeight: Int64;
	
begin
	if Length(Folder) > 0 then
		begin
			if (Folder[Length(Folder)] <> '/') or (Folder[Length(Folder)] <> '\') then
				Folder += '/';
		end;
	if Src = '' then
		Exit;
	
	//writeln('src');
	
	Path := Folder + Src;
	//writeln('SE');
	SourceDirectory := Folder;
	//writeln('TE');
	SourceFile := Src;
	
	//writeln('lock');
	
	MaxTileHeight := IntegerParameterFromTag(GetTagFromFile(Path, '<map', 1), 'tilewidth');
	MaxTileWidth := IntegerParameterFromTag(GetTagFromFile(Path, '<map', 1), 'tileheight');
	
	//writeln('dim');

	t := FindOccurencesInFile(Path, '<tileset');
	c := 0;
	TileHandler.NewMemoryBlockSize(t);
	repeat
		c += 1;

		TileHandler.AddTileSet(BlankTileSet, IntegerParameterFromTag(GetTagFromFile(Path, '<tileset',c), 'firstgid'));
		pwts := TileHandler.GetLastTileSet();
		
		pwts^.LoadFromImageFile( Folder + StringParameterFromTag(GetTagFromFile(Path, '<image', c), 'source'));
		pwts^.SetTileSize( IntegerParameterFromTag( GetTagFromFile(Path, '<tileset', c), 'tilewidth'), IntegerParameterFromTag( GetTagFromFile(Path, '<tileset', c), 'tileheight'));
		pwts^.SetTileOffset( IntegerParameterFromTag( GetTagFromFile(path, '<tileset', c), 'margin'), IntegerParameterFromTag( GetTagFromFile(path, '<tileset', c), 'spacing') );
		pwts^.SetTileSpacing( IntegerParameterFromTag( GetTagFromFile(path, '<tileset', c), 'spacing'), IntegerParameterFromTag( GetTagFromFile(path, '<tileset', c), 'spacing') );
		pwts^.SetTileGrid( (pwts^.VisualData.GetWidth - pwts^.TileOffsetX) div (pwts^.TileWidth + pwts^.TileSpacingX), 
			(pwts^.VisualData.GetHeight - pwts^.TileOffsetY) div (pwts^.TileHeight + pwts^.TileSpacingY));
		pwts^.Calculate();
		until c >= t;
	
	t := FindOccurencesInFile(Path, '<layer');
	SetLength(Layer, t + 1);
	Layers := t;
	c := 0;
	repeat
		c += 1;
		
		Layer[c].SetSize( IntegerParameterFromTag( GetTagFromFile(Path, '<layer', c), 'width'), IntegerParameterFromTag( GetTagFromFile(Path, '<layer', c), 'height') );
		Layer[c].SetName( StringParameterFromTag( GetTagFromFile(Path, '<layer', c), 'name'));
		Layer[c].TileHandlerLocation := @TileHandler;
		Layer[c].Visible := True;

		Layer[c].TileWidth := MaxTileWidth;
		Layer[c].TileHeight := MaxTileHeight;
		
		Layer[c].LoadTileCodesFromCsv( GetTagText(Path, '<data', c));
		until c >= t;
end;

procedure Map.Empty();
begin
end;

procedure MapLayer.Draw(X, Y: Int64);
var
	Gx, Gy: Int64;
	Tx, Ty: Int64;
	sGx, sGy: Int64;
	sTx, sTy: Int64;
	
begin
	//precompute the X start and end co-ordinates the lazy way :)
	Gx := X - TileWidth;
	Tx := 0;
	if Gx + TileWidth <= 0 then
		begin
			repeat
				Gx += TileWidth;
				Tx += 1;
				until Gx + TileWidth >= 0;
			Gx -= TileWidth;
			Tx -= 1;
		end;
	sGx := Gx;
	sTx := Tx;
	
	Gy := Y - TileHeight;
	Ty := 0;
	if Gy + TileHeight <= 0 then
		begin
			repeat
				Gy += TileHeight;
				Ty += 1;
				until Gy + TileHeight >= 0;
			Gy -= TileHeight;
			Ty -= 1;
		end;
	sGy := Gy;
	sTy := Ty;

	Gy := sGy;
	Ty := sTy;
	repeat
		Gy += TileHeight;
		Ty += 1;
		
		Gx := sGx;
		Tx := sTx;
		repeat
			Gx += TileWidth;
			Tx += 1;
						
			TileHandlerLocation^.DrawTile(TileCode[Tx, Ty], Gx, Gy);
			if Gx > GetWindowWidth then
				Break;
			until (Tx >= Width);
		if Gy > GetWindowHeight() then
			Break;
		until (Ty >= Height);
				
end;

procedure MapLayer.SetVisibility(Val: Boolean);
begin
	Visible := Val;
end;

procedure MapLayer.LoadTileCodesFromCsv(Data: ANSIString);
var
	c: Int64;
	RamStr: ANSIString;
	LX, LY: Int64;
	
begin
	if Length(Data) <= 1 then
		Exit;
		
	LX := 1;
	LY := 1;
	
	c := 0;
	repeat
		RamStr := '';
		repeat
			c += 1;
			if (Data[c] <> ' ') and (Data[c] <> '') and (Data[c] <> ',') and (Data[c] <> '.') then
				begin
					RamStr += Data[c];
				end
			else
				Break;
			until (c >= length(Data));
		TileCode[LX, LY] := StrToInt(RamStr);
				
		LX += 1;
		if LX > Width then
			begin
				LX := 1;
				LY += 1;
			end;
		until (c >= Length(Data)) or (LY >= Height + 1); //we start at 1 so we need + 1 so it all starts at 1 in memory too!
end;

procedure MapLayer.SetOffset(X, Y: Int64);
begin
	OffsetX := X;
	OffsetY := Y;
end;


procedure MapLayer.SetName(Nme: ANSIString);
begin
	Name := Nme;
end;

procedure MapLayer.SetSize(X, Y: Int64);
begin
	Width := X;
	Height := Y;
	SetLength(TileCode, Width + 1, Height + 1);
end;

function PropertyHandler.GetPropertyIdByName(Nme: ANSIString): Int64;
var
	c: Int64;

begin
	c := 0;
	GetPropertyIdByName := 0;
	repeat
		c += 1;
		if Nme = PropertyData[c].Value then
			begin
				GetPropertyIdByName := c;
				Break;
			end;
		until c >= Properties;
end;

procedure PropertyHandler.DelProperty(Nme: ANSIString);
begin
	if GetPropertyIdByName(Nme) <= 0 then
		Exit;
	PropertyData[GetPropertyIdByName(Nme)].Empty();
end;

procedure PropertyHandler.ModProperty(Nme, Val: ANSIString);
begin
	if GetPropertyIdByName(Nme) <= 0 then
		Exit;
	PropertyData[GetPropertyIdByName(Nme)].Define(Nme, Val);
end;

procedure PropertyHandler.AddProperty(Nme, Val: ANSIString);
var
	c: Int64;
	
begin
	c := Properties;
	Properties += 1;
	SetLength(PropertyData, Properties + 1);
	PropertyData[c].Define(Nme, Val);
end;

procedure PropertyValue.Empty();
begin
	Name := '';
	Value := '';
end;

procedure PropertyValue.Define(Nme, Val: ANSIString);
begin
	Name := Nme;
	Value := Val;
end;

begin
end.
