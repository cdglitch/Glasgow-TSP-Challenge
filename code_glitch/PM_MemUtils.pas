unit PM_MemUtils;

{$Mode ObjFpc}

interface

uses
	PM_Utils;

type
	ByteArray = Array of Byte;
	CharArray = Array of Char;
	RAMFile = Object
			DataLength: Int64;
			Data: array of Byte;
			ReadPosition: Int64;
			
			procedure LoadFromDisk(Src: ANSIString);
			procedure ResetReadPosition();
			function GetBytes(Start, Number: Int64): ByteArray;
			function GetNextByte(): Byte;
			function GetNextChar(): Char;
			function GetNextBytes(Number: Int64): ByteArray;
			procedure Empty();
		end;
	pByteArray = ^ByteArray;
	PM_CacheControllerParameters = Record
			MemoryBlockSize: array of Int64;
			MemoryBlockSizes: Int64;
			CurrentMemoryAllocation: Int64;
			CurrentBlockSize: Int64;
			BlockSizeInflationFactor: Real;
		end;
	PM_CacheController = Object
			CacheParams: PM_CacheControllerParameters;
			
			procedure AllocateMemoryBlock();
			procedure ShrinkMemoryBlock();
			function GetNextBlockSize(): Int64;
			function GetLastBlockSize(): Int64;
		end;
	Char4 = array [1..4] of Char;
    Char2 = array [1..2] of Char;
	Byte4 = array [1..4] of Byte;
    Byte2 = array [1..2] of Byte;

procedure LoadBytesToArray(Data: array of Byte; Dest: pByteArray; Len: Int64);
procedure AlignByteArray(Data: pByteArray);
procedure ShiftBytesRight(Data: pByteArray; Num: Int64);
//function ByteArrayToInt(Data: ByteArray): Int64;
function GetBytesFromArray(Start: Int64; Data: pByteArray; Stop: Int64): ByteArray;
function ByteArrayIsEqual(Ar1, Ar2: ByteArray): Boolean;
function StrToByteArray(Src: ANSIString): ByteArray;

function GetBlankCacheControllerParameters(BlockSize: Int64; InflationFactor: Real): PM_CacheControllerParameters;

function BytesToSingle32(Str: Char4): Single;
function BytesToInt32(Str: Char4): LongInt;
function BytesToInt16(Str: Char2): SmallInt;
function Int32ToBytes(Int: LongInt): ANSIString;
function Int16ToBytes(Int: SmallInt): ANSIString;
function Single32ToBytes(Sgl: Single): ANSIString;

implementation

uses
	PM_Logs;
	
function StrToByteArray(Src: ANSIString): ByteArray;
var
	c: Int64;
	
begin
	SetLength(StrToByteArray, Length(Src) + 1);
	if Length(Src) <= 0 then
			Exit;
	

	c := 0;
	repeat
		c += 1;
		StrToByteArray[c] := Ord(Src[c]);
		until c >= Length(Src);
end;

function BytesToSingle32(Str: Char4): Single;
var
    Data: Single Absolute Str;
    
begin
    BytesToSingle32 := Data;
end;

function BytesToInt32(Str: Char4): LongInt;
var
    Data: LongInt Absolute Str;
    
begin
    BytesToInt32 := Data;
end;

function BytesToInt16(Str: Char2): SmallInt;
var
    Data: SmallInt Absolute Str;
    
begin
    BytesToInt16 := Data;
end;

function Single32ToBytes(Sgl: Single): ANSIString;
var
    Data: array [1..4] of Byte Absolute Sgl;
    
begin
    Single32ToBytes := Char(Data[1]);
    Single32ToBytes += Char(Data[2]);
    Single32ToBytes += Char(Data[3]);
    Single32ToBytes += Char(Data[4]);
end;

function Int16ToBytes(Int: SmallInt): ANSIString;
var
    Data: array[1..2] of Byte Absolute Int;
begin
    Int16ToBytes := Char(Data[1]);
    Int16ToBytes += Char(Data[2]);
end;

function Int32ToBytes(Int: LongInt): ANSIString;
var
    Data: array[1..4] of Byte Absolute Int;
begin
    Int32ToBytes := Char(Data[1]);
    Int32ToBytes += Char(Data[2]);
    Int32ToBytes += Char(Data[3]);
    Int32ToBytes += Char(Data[4]);
end;

function PM_CacheController.GetNextBlockSize(): Int64;
begin
	GetNextBlockSize := trunc(CacheParams.CurrentBlockSize * (1 + CacheParams.BlockSizeInflationFactor));
end;

function PM_CacheController.GetLastBlockSize(): Int64;
begin
	GetLastBlockSize := trunc(CacheParams.MemoryBlockSize[CacheParams.MemoryBlockSizes]);
end;

procedure PM_CacheController.AllocateMemoryBlock();
begin
	with CacheParams do
		begin
			MemoryBlockSizes += 1;
			SetLength(MemoryBlockSize, MemoryBlockSizes + 1);
			CurrentBlockSize := GetNextBlockSize();
			MemoryBlockSize[MemoryBlockSizes] := CurrentBlockSize;
			CurrentMemoryAllocation += CurrentBlockSize;
		end;
end;

procedure PM_CacheController.ShrinkMemoryBlock();
begin
	with CacheParams do
		begin
			MemoryBlockSizes -= 1;
			SetLength(MemoryBlockSize, MemoryBlockSizes + 1);
			CurrentBlockSize := GetLastBlockSize();
			CurrentMemoryAllocation -= CurrentBlockSize;
		end;
end;

function GetBlankCacheControllerParameters(BlockSize: Int64; InflationFactor: Real): PM_CacheControllerParameters;
begin
	SetLength(GetBlankCacheControllerParameters.MemoryBlockSize, 0);
	GetBlankCacheControllerParameters.MemoryBlockSizes := 0;
	GetBlankCacheControllerParameters.CurrentMemoryAllocation := 0;
	GetBlankCacheControllerParameters.CurrentBlockSize := trunc((BlockSize div 100) * (InflationFactor * 100));
	GetBlankCacheControllerParameters.BlockSizeInflationFactor := InflationFactor;
end;

function ByteArrayIsEqual(Ar1, Ar2: ByteArray): Boolean;
var
	c: Int64;
	
begin
	if (Length(Ar1) <= 0) and (Length(Ar2) <= 0) then
		begin
			ByteArrayIsEqual := True;
			Exit;
		end
	else if (Length(Ar1) <= 0) or (Length(Ar2) <= 0) then
		begin
			ByteArrayIsEqual := False;
			Exit;
		end;
		
	ByteArrayIsEqual := True;
	
	c := 0;
	repeat
		c += 1;
		if Ar1[c] <> Ar2[c] then
			begin
				ByteArrayIsEqual := False;
				Break;
			end;
		until (c >= Length(Ar1)) or (c >= Length(Ar2));
end;

function GetBytesFromArray(Start: Int64; Data: pByteArray; Stop: Int64): ByteArray;
var
	c: Int64;
	d: Int64;

begin
	if Stop > Length(Data^) then
		Stop := Length(Data^);
	if Start < 0 then
		Start := 0;
	c := Start - 1;
	SetLength(GetBytesFromArray, (Stop - Start));
	d := 0;
	repeat
		c += 1;
		d += 1;
		GetBytesFromArray[d] := Data^[c];
		until c >= Stop;
end;

{
function ByteArrayToInt(Data: ByteArray): Int64;
var
	c: Int64;
	r: Int64;
	
begin
	//write(ByteArrayToString(Data));
	c := Length(Data) + 1;
	r := 0;
	repeat
		c -= 1;
		r += Data[c] * IntToPower(2, (c) * 8);
		write(Data[c],'x');
		until c <= 0;
	ByteArrayToInt := r;
	writeln('=',r)
end;
}

procedure AlignByteArray(Data: pByteArray);
var
	c: Int64;

begin
	if Length(Data^) <= 0 then
		Exit;
	if (Data^[0] = 0) and (Data^[1] <> 0) then
		begin
			LogMsg('Info: PM_Memutills.AlignByteArray - No byte alignment necessary!');
			Exit;
		end;
	SetLength(Data^, Length(Data^) + 1);
	c := Length(Data^);
	repeat
		c -= 1;
		Data^[c + 1] := Data^[c];
		until c <= 0;		
end;

procedure ShiftBytesRight(Data: pByteArray; Num: Int64);
var
	c: Int64;

begin
	if Length(Data^) <= 0 then
		Exit;
	Num += 1;
	c := Length(Data^) + 1;
	SetLength(Data^, Length(Data^) + Num - 1);
	repeat
		c -= 1;
		Data^[c + Num] := Data^[c];
		until c <= 0;
end;

procedure LoadBytesToArray(Data: array of Byte; Dest: pByteArray; Len: Int64);
var
	c: Int64;
	
begin
	Len += 1;
	SetLength(Dest^, Len);
	c := 0;
	repeat
		c += 1;
		Dest^[c] := Data[c];
		until c >= Len;
end;

procedure RAMFile.Empty();
begin
	
end;

procedure RAMFile.ResetReadPosition();
begin
	ReadPosition := 1;
end;

function RAMFile.GetNextChar(): Char;
begin
	ReadPosition += 1;	
	if ReadPosition >= DataLength then
		ResetReadPosition();
	GetNextChar := Char(Data[ReadPosition]);
end;

function RAMFile.GetNextByte(): Byte;
begin
	ReadPosition += 1;	
	if ReadPosition >= DataLength then
		ResetReadPosition();
	GetNextByte := Data[ReadPosition];
end;

function RAMFile.GetNextBytes(Number: Int64): ByteArray;
var
	c: Int64;
	
begin
	c := Number;
	if ReadPosition + c > DataLength then
		c := DataLength - Number;
	GetNextBytes := GetBytes(ReadPosition, c);
	if ReadPosition + c >= DataLength then
		ResetReadPosition()
	else
		ReadPosition += c;
end;

function RAMFile.GetBytes(Start, Number: Int64): ByteArray;
var
	c, l: Int64;

begin
	if Number + Start > DataLength then
		Number := DataLength - Start;
	SetLength(GetBytes, Number + 1);
	c := Start - 1;
	l := 0;
	repeat
		l += 1;
		c += 1;
		GetBytes[l] := Data[c];
		until (c >= Start + Number) or (l >= Number);
end;

procedure RAMFile.LoadFromDisk(Src: ANSIString);
var
	Disk: File of Byte;
	c: Int64;
	s: Int64;
	Garbage: Byte;

begin
	Assign(Disk, Src);
	Reset(Disk);
	s := 0;
	repeat
		s += 1;
		read(Disk, Garbage);
		until eof(Disk);
	Reset(Disk);
	//DataLength := SizeOf(Disk);
	DataLength := s;
	SetLength(Data, DataLength + 1);
	c := 0;
	repeat
		c += 1;
		read(Disk, Data[c]);
		until (eof(Disk)) or (c >= DataLength);
	Close(Disk);
	ReadPosition := 1;
end;

begin
end.
