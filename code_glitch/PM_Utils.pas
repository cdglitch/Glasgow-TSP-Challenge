unit PM_Utils;

{$Mode ObjFpc}

interface

uses
	Sysutils,
	crt,
	Time,
	
	PM_Debug;
	

type
	BooleanArray = array of Boolean;
	pBooleanArray = ^BooleanArray;
	StrArray = array of ANSIString;
	pStrArray = ^StrArray;
	IntArray = array of Int64;
	pIntArray = ^IntArray;
	oPMUtilData = Object
			AppInitTime: Int64;
		end;
	
	{String64 = Record
			Length: Int64;
			Data: array of Byte;
		end;}

var
	PrometheusUtilitySystem: oPMUtilData;

function ByteToStr(Bt: Byte): ANSIString;
function IntToStr(Int: Int64): String;
function StrToInt(Str: String): Int64;
function StrToReal(Str: String): Real;
function RealToStr(Val: Real): String;
//function StrToStr64(Str: ANSIString): String64;function Str64ToStr(Str64: String64): ANSIString;
function BoolToStr(Val: Boolean): ANSIString;

function LargestFromIntArray(Dat: array of Int64): Int64;

procedure EmptyIntArray(Dat: pIntArray);
procedure EmptyStringArray(Dat: pStrArray);
procedure EmptyBooleanArray(Dat: pBooleanArray);

function IntArrayMatch(Ar1, Ar2: array of Int64; Len: Int64): Boolean;

procedure Pause(ms: Int64);
function GetTime(): Int64;
function GetSystemTime(): Int64;

function GetRandomRealInRange(Low, High: Int64): Real;
function DoesFileExist(Path: ANSIString): Boolean;

function RealToStrAccuracy(Data: Real; Digits: Int64): ANSIString;

function IsBetween(X, Low, High: Real): Boolean;

implementation

uses
	PM_Logs;

function IsBetween(X, Low, High: Real): Boolean;
begin
	IsBetween := False;
	
	if High > Low then
		if (X >= Low) and (X <= High) then
			IsBetween := True
	else if Low = High then
		if X = Low then
			IsBetween := True
	else if High < Low then
		IsBetween := IsBetween(X, High, Low);
end;

function RealToStrAccuracy(Data: Real; Digits: Int64): ANSIString;
var
	Tmp: ANSIString;
	
begin
	Str(Data:1:trunc(Digits * 0.75), Tmp);
	RealToStrAccuracy := Tmp;
end;

function ByteToStr(Bt: Byte): ANSIString;
var
	Ram: String;

begin
	Str(Bt, Ram);
	ByteToStr := Ram;
end;

function BoolToStr(Val: Boolean): ANSIString;
begin
	if Val = True then
		BoolToStr := 'true'
	else
		BoolToStr := 'false';
end;

function DoesFileExist(Path: ANSIString): Boolean;
begin
	DoesFileExist := FileExists(Path);
end;

function GetRandomRealInRange(Low, High: Int64): Real;
var
	X: Real;
	
begin
	repeat
		X := random(High + Low + 2);
		X := X - Low + Random();
		until (X >= Low) and (X <= High);
	GetRandomRealInRange := X;
end;


{function StrToStr64(Str: ANSIString): String64;
var
	c: Int64;

begin
	c := 0;
	repeat
		c += 1;
		StrToStr64.Data[c] := ord(Str[c]);
		until c >= Length(Str);
	StrToStr64.Length := Length(Str);
end;

function Str64ToStr(Str64: String64): ANSIString;
var
	c: Int64;

begin
	c := 0;
	repeat
		c += 1;
		Str64ToStr[c] := char(Str64.Data[c]);
		until c >= Str64.Length;
end;}

function IntArrayMatch(Ar1, Ar2: array of Int64; Len: Int64): Boolean;
var
	c: Int64;
	Match: Boolean;

begin
	Match := True;
	c := -1;
	repeat
		c += 1;
		//writeln(c,' chk ',Ar1[c],' VS ',Ar2[c]);
		if Ar1[c] <> Ar2[c] then
			begin
				//writeln('ERROR');
				Match := False;
				Break;
			end;
		until (c >= Length(Ar1)) or (c >= Length(Ar2)) or (Match = False) or (c >= Len - 1);
	IntArrayMatch := Match;
end;

procedure EmptyIntArray(Dat: pIntArray);
var
	c: Int64;
	
begin
	if Length(Dat^) > 0 then
		begin
			c := 0;
			repeat
				c := c + 1;
				Dat^[c] := 0;
				until c >= Length(Dat^);
		end;
	SetLength(Dat^, 0);
end;

procedure EmptyStringArray(Dat: pStrArray);
var
	c: Int64;
	
begin
	if Length(Dat^) > 0 then
		begin
			c := 0;
			repeat
				c := c + 1;
				Dat^[c] := '';
				until c >= Length(Dat^);
		end;
	SetLength(Dat^, 0);
end;

procedure EmptyBooleanArray(Dat: pBooleanArray);
var
	c: Int64;
	
begin
	if Length(Dat^) > 0 then
		begin
			c := 0;
			repeat
				c := c + 1;
				Dat^[c] := False;
				until c >= Length(Dat^);
		end;
	SetLength(Dat^, 0);
end;


function LargestFromIntArray(Dat: array of Int64): Int64;
var
	c: Int64;
	v: Int64;

begin
	c := 0;
	v := 0;
	repeat
		c := c + 1;
		if Dat[c] > v then
			v := Dat[c];
		until c >= Length(Dat);
	LargestFromIntArray := v;
end;

procedure Pause(ms: Int64);
begin
	Delay(ms);
end;

function GetTime(): Int64;
begin
	GetTime := DateTimeToTimeStamp(Now).Time - PrometheusUtilitySystem.AppInitTime;
end;

function GetSystemTime(): Int64;
begin
	GetSystemTime := DateTimeToTimeStamp(Now).Time;
end;

function IntToStr(Int: Int64): String;
var
	Ram: String;

begin
	Str(Int,Ram);
	IntToStr := Ram;
end;

function StrToInt(Str: String): Int64;
begin
	if Length(Str) <= 0 then
		Str := '0';
		
	try
		StrToInt := StrToInt64Def(Str, 0);
	except
		LogMsg('PM_Utils: Invalid StrToInt conversion');
	end;
end;

function StrToReal(Str: String): Real;
begin
	if Length(Str) > 0 then
		begin
			try
				StrToReal := StrToFloatDef(Str, 0.0)
			except
				StrToReal := 0;
			end
		end
	else
		StrToReal := 0.0;
end;

function RealToStr(Val: Real): String;
var
	Ram: String;

begin
	Str(Val,Ram);
	RealToStr := Ram;
end;


begin
	PrometheusUtilitySystem.AppInitTime := DateTimeToTimeStamp(Now).Time;
end.
