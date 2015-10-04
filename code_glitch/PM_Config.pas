unit PM_Config;

interface

uses
	PM_Utils;

type
	Config = object
			Parameter: array of ANSIString;
			Value: array of ANSIString;
			DataLength: Int64;
			
			procedure LoadFromDisk(Src: ANSIString);
			procedure LoadFromRAWString(Data: ANSIString);
			
			function OccurencesInParameters(Srch: ANSIString): Int64;
			function GetConfigParameter(Param: ANSIString): ANSIString;
			function GetConfigParameterId(Param: ANSIString): Int64;
			function GetConfigAsString(): ANSIString;
			
			procedure AddParameter(Param, Val: ANSIString);
			procedure ModParameter(Param, Val: ANSIString);
			procedure DelParameter(Param: ANSIString);
			procedure MovParameter(Param, NewParam: ANSIString);
			procedure Wipe();
			
			procedure WriteToDisk(Dest: ANSIString);
		end;
	pConfig = ^Config;

function GetConfigParameter(Conf: Config; Param: ANSIString): ANSIString; //Legacy support
function GetConfigFromDisk(Src: ANSIString): Config;
function CONF_ParseLine_Field(Dt: ANSIString): ANSIString;
function CONF_ParseLine_Value(Dt: ANSIString): ANSIString;

implementation

uses
	PM_TextUtils;

function Config.OccurencesInParameters(Srch: ANSIString): Int64;
var
	c: Int64;

begin
	OccurencesInParameters := 0;
	if DataLength <= 0 then
		Exit;
	
	c := 0;
	repeat
		c += 1;
		if Pos(Srch, Parameter[c]) > 0 then
			OccurencesInParameters += 1;
		until c >= DataLength;
end;

function GetConfigFromDisk(Src: ANSIString): Config;
var
	tmp: Config;

begin
	tmp.LoadFromDisk(Src);
	GetConfigFromDisk := tmp;
end;

procedure Config.Wipe();
begin
	DataLength := 0;
	SetLength(Value, DataLength + 1);
	SetLength(Parameter, DataLength + 1);
end;

function Config.GetConfigAsString(): ANSIString;
var
	c: Int64;

begin
	GetConfigAsString := '';
	if DataLength < 1 then
		Exit;
	c := 0;
	repeat
		c += 1;
		GetConfigAsString += Parameter[c] + '=' + Value[c] + #13;
		until c >= DataLength;
end;

procedure Config.WriteToDisk(Dest: ANSIString);
var
	Disk: Text;
	c: Int64;

begin
	Assign(Disk, Dest);
	ReWrite(Disk);
	
	writeln(Disk, '#START#');
	
	c := 0;
	repeat
		c += 1;
		if Length(Parameter[c]) > 0 then
			writeln(Disk, Parameter[c] + '=' + Value[c]);
		until c >= DataLength;
	
	writeln(Disk, '#END#');
	
	Close(Disk);
end;

function Config.GetConfigParameterId(Param: ANSIString): Int64;
var
	c: Int64;
	
begin
	if DataLength <= 0 then
		begin
			GetConfigParameterId := 0;
			Exit;
		end;
		
	c := 0;
	GetConfigParameterId := 0;
	repeat
		c += 1;
		if Parameter[c] = Param then
				GetConfigParameterId := c;
		until (c >= DataLength) or (Param = Parameter[c]);
end;

procedure Config.AddParameter(Param, Val: ANSIString);
begin
	DataLength += 1;
	SetLength(Parameter, DataLength + 1);
	SetLength(Value, DataLength + 1);
	Parameter[DataLength] := Param;
	Value[DataLength] := Val;
end;

procedure Config.MovParameter(Param, NewParam: ANSIString);
var
	Position: Int64;

begin
	Position := GetConfigParameterId(Param);
	if Position <= 0 then
		Exit;
	
	Parameter[Position] := NewParam;
end;

procedure Config.ModParameter(Param, Val: ANSIString);
var
	Position: Int64;
	
begin
	Position := GetConfigParameterId(Param);
	if Position <= 0 then
		Exit;
	
	Value[Position] := Val;
end;


procedure Config.DelParameter(Param: ANSIString);
var
	Position: Int64;
	c: Int64;
	
begin
	Position := GetConfigParameterId(Param);
	if Position <= 0 then
		Exit;
	
	c := Position - 1;
	repeat
		c += 1;
		Value[c] := Value[c + 1];
		Parameter[c] := Parameter[c + 1];
		until c + 1 >= DataLength;
		
	DataLength += -1;
	SetLength(Parameter, DataLength + 1);
	SetLength(Value, DataLength + 1);
end;

function GetConfigParameter(Conf: Config; Param: ANSIString): ANSIString;
begin
	GetConfigParameter := Conf.GetConfigParameter(Param);
end;

function Config.GetConfigParameter(Param: ANSIString): ANSIString;
var
	c: Int64;

begin
	if DataLength <= 0 then
		begin
			GetConfigParameter := '';
			Exit;
		end;
		
	c := 0;
	repeat
		c := c + 1;
		if Parameter[c] = Param then
			break;
		until c = DataLength;

	if Parameter[c] = Param then
		begin
			GetConfigParameter := Value[c];
		end
	else
		GetConfigParameter := '';
end;

function GetParameterName(Src: ANSIString): ANSIString;
var
	c: Int64;
	RamStr: ANSIString;
	
begin
	RamStr := '';
	c := 0;
	if Src[1] = ' ' then
		begin
			repeat
				c := c + 1;
				until Src[c] <> ' ';
		end;
	c := c - 1;
	repeat
		c := c + 1;
		if (Src[c] <> ' ') and (Src[c] <> '') and (Src[c] <> '=') then
			RamStr := RamStr + Src[c];
		until (c >= Length(Src)) or (Src[c] = '=');
	Delete(RamStr, Length(RamStr)-1, 1);
	GetParameterName := RamStr;
end;

function GetParameterValue(Src: ANSIString): ANSIString;
var
	c: Int64;
	RamStr: ANSIString;
	
begin
	RamStr := '';
	c := 0;

	repeat
		c := c + 1;
		until Src[c] = '=';
	
	if (Src[c] = ' ') or (Src[c] = '=') then
		begin
			repeat
				c += 1;
				until (Src[c] <> ' ') and (Src[c] <> '=');
		end;
		
		
	c := c - 1;
	repeat
		c := c + 1;
		if (Src[c] <> ' ') and (Src[c] <> '') and (Src[c] <> '=') then
			RamStr := RamStr + Src[c];
		until (c >= Length(Src));
	Delete(RamStr, Length(RamStr)-1, 1);
	GetParameterValue := RamStr;
end;

{procedure Config.LoadFromDisk(Src: ANSIString);
var
	Disk: Text;
	c : Int64;
	RamStr: ANSIString;

begin
	Assign(Disk, Src);
	Reset(Disk);
	
	RamStr := '';
	
	while upcase(RamStr) <> '#START#' do
		readln(Disk, RamStr);
		
	DataLength := 0;
	c := 0;
	repeat
		c := c + 1;
		readln(Disk, RamStr);
		if Pos('=', RamStr) <> 0 then
			DataLength += 1;
		until (upcase(RamStr) = '#END#') or (eof(Disk));
	Close(Disk);
	
	SetLength(Parameter, DataLength);
	SetLength(Value, DataLength);
	
	Assign(Disk, Src);
	Reset(Disk);
	
	RamStr := '';
	
	while upcase(RamStr) <> '#START#' do
		readln(Disk, RamStr);
		
	c := 0;
	repeat
		c := c + 1;
		readln(Disk, RamStr);
		Parameter[c] := GetParameterName(RamStr);
		Value[c] := GetParameterValue(RamStr);
		until (upcase(RamStr) = '#END#') or (eof(Disk));
	Close(Disk);
end;}

function CONF_ParseLine_Field(Dt: ANSIString): ANSIString;
var
	c: Int64;

begin
	c := 0;
	CONF_ParseLine_Field := '';
	if Length(Dt) < 1 then
		Exit;
	repeat
		c += 1;
		if c > Length(Dt) then
			Exit;
		if Dt[c] = '#' then
			begin
				repeat
					c += 1;
					if c > Length(Dt) then
						Exit;
					until Dt[c] = '#';
				c += 1;
			end;
		if (Dt[c] <> '=') and (Dt[c] <> ' ') then
			CONF_ParseLine_Field +=Dt[c]
		else
			break;
		until (Dt[c] = '=') or (Dt[c] = ' ');
end;

function CONF_ParseLine_Value(Dt: ANSIString): ANSIString;
var
	c2: Int64;

begin
	CONF_ParseLine_Value := '';
	if Length(Dt) < 1 then
		Exit;
		
	if FindOccurencesInString(Dt, '=') < 1 then
		Exit;
		
	c2 := 0;
	repeat
		c2 := c2 + 1;
		until (Dt[c2] = '=');

	c2 += 1;
	if c2 > Length(Dt) then
		Exit;
	if Dt[c2] = ' ' then
		begin
			repeat
				c2 := c2 + 1;
				if c2 > Length(Dt) then
					Exit;
				until (Dt[c2] <> ' ');
		end;
	c2 -= 1;

	repeat
		c2 := c2 + 1;
		CONF_ParseLine_Value += Dt[c2];
		until c2 >= Length(Dt);
end;

procedure Config.LoadFromRAWString(Data: ANSIString);
var
	RamStr: ANSIString;
	c, c2: Int64;

begin
	Wipe();
	if Length(Data) < 1 then
		Exit;
	c := 0;
	c2 := 0;
	repeat
		c += 1;
		SetLength(Parameter, c + 1);
		SetLength(Value, c + 1);
		
		RamStr := '';
		repeat
			c2 += 1;
			if c2 > Length(Data) then
				Break;
			if (Data[c2] <> #13) and (Data[c2] <> #10) then
				RamStr += Data[c2];
			until (Data[c2] = #13) or (Data[c2] = #10);
		
		
		Parameter[c] := CONF_ParseLine_Field(RamStr);
		//write('Param "',CONF_ParseLine_Field(RamStr),'" 	Data "');
		Value[c] := CONF_ParseLine_Value(RamStr);
		//writeln(CONF_ParseLine_Value(RamStr),'"');
		DataLength := c;
		until c2 >= Length(Data);
end;

procedure Config.LoadFromDisk(Src: ANSIString);
var
	Disk: Text;
	RamStr: ANSIString;
	RamStr2: ANSIString;
	c: Int64;
	c2: Int64;

begin
	Wipe();
	if DoesFileExist(Src) = False then
		begin
			Wipe();
			Exit;
		end;
	Assign(Disk, Src);
	Reset(Disk);
	repeat
		readln(Disk, RamStr);
		until (upcase(RamStr) = '#START#') or (eof(Disk));
	if (upcase(RamStr) <> '#START#') and (eof(Disk)) then
		begin
			//writeln('PM_CONFIG: EOF, NO START SIGN!');
			Exit;
		end;
	c := 0;
	repeat
		c += 1;
		readln(Disk, RamStr);
		until eof(Disk) or (upcase(RamStr) = '#END#');
	RamStr := '';
		
	DataLength := c;
	SetLength(Parameter, c + 1);
	SetLength(Value, c + 1);
	
	close(Disk);
	Assign(Disk, Src);
	Reset(Disk);
	
	repeat
		readln(Disk, RamStr);
		until upcase(RamStr) = '#START#';
		
	c := 0;
	repeat
		c := c + 1;
		repeat
			readln(Disk, RamStr);
			until (RamStr <> '') or (RamStr <> ' ') or (RamStr[1] <> '[');
		if upcase(RamStr) = '#END#' then
			break;
		c2 := 0;
		RamStr2 := '';
		repeat
			c2 := c2 + 1;
			if (RamStr[c2] <> '=') and (RamStr[c2] <> ' ') then
				RamStr2 := RamStr2 + RamStr[c2]
			else
				break;
			until (RamStr[c2] = '=') or (RamStr[c2] = ' ');
		Parameter[c] := RamStr2;
		RamStr2 := '';

		repeat
			c2 := c2 + 1;
			until (RamStr[c2] <> '') or (RamStr[c2] <> ' ') or (RamStr[c2] <> '=');

		c2 := c2 - 1;
		repeat
			c2 := c2 + 1;
			until RamStr[c2] <> ' ';

		c2 := c2 - 1;

		repeat
			c2 := c2 + 1;
			RamStr2 := RamStr2 + RamStr[c2];
			until c2 >= Length(RamStr);
		Value[c] := RamStr2;
		until RamStr = '#END#';
	Close(Disk);
end;

begin
end.
