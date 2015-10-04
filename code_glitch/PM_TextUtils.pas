unit PM_TextUtils;

{$Mode ObjFpc}

interface

uses
	PM_Utils;

type
	FileHeader = array [1..4] of Int64;

const
	PM_TYPEHEADER_PNG	:	array [1..4] of Int64	=	(137, 80, 78, 71); //the trailing 0 is there since we work with arrays from 1
	PM_TYPEHEADER_TGA	:	array [1..4] of Int64	=	(0, 0, 10, 0);

function FindOccurencesInString(Raw: ANSIString; Data: ANSIString): Int64;
function FindOccurencesInFile(Path: String; Data: ANSIString): Int64;
function FindOccurenceLineInFile(Path: ANSIString; Data: ANSIString; Occurence: Int64): Int64;
function GetTagFromFile(Path: ANSIString; TagName: ANSIString; Occurence: Int64): ANSIString;
function GetTagText(Path: ANSIString; Tag: ANSIString; Occurence: Int64): ANSIString;
function IntegerParameterFromTag(Tag: ANSIString; Parameter: ANSIString): Int64;
function StringParameterFromTag(Tag: ANSIString; Parameter: ANSIString): ANSIString;
procedure WriteFileInOrd(Path: ANSIString);
procedure WriteStrInOrd(Str: ANSIString);
function LoadLinesToStr(Path: ANSIString; Start: Int64; Stop: Int64): ANSIString;
function LoadFileToStr(Path: ANSIString): ANSIString;
procedure WriteStrToFile(Data, Path: ANSIString);
function GetFileHeader(Source: ANSIString; Ln: Int64): FileHeader;
function StrArrayToStr(Dt: array of ANSIString): ANSIString;
function FindOccurenceInString(Raw, Data: ANSIString; n: Int64): Int64;
function GetCSVParameterFromString(Id: Int64; CSV: ANSIString): ANSIString;
function GetCharSVParameterFromString(Id: Int64; CSV, Sep: ANSIString): ANSIString;
function GetStringPart(Data: ANSIString; StartPosition, EndPosition: Int64): ANSIString;

implementation

function GetStringPart(Data: ANSIString; StartPosition, EndPosition: Int64): ANSIString;
var
	c: Int64;

begin
	if (StartPosition < 0) or (Length(Data) <= 0) then
		Exit;
	if (EndPosition < 0) or (EndPosition > Length(Data)) then
		EndPosition := Length(Data);
	if EndPosition < StartPosition then
		begin
			c := StartPosition;
			StartPosition := EndPosition;
			EndPosition := c;
		end;

	GetStringPart := '';
	c := StartPosition;
	repeat
		GetStringPart += Data[c];
		c += 1;
		until c > EndPosition;
end;

function FindOccurenceInString(Raw, Data: ANSIString; n: Int64): Int64;
var
	c: Int64;
	LastPos: Int64;
	NextPos: Int64;
	
begin
	FindOccurenceInString := 0;
	//write('OCM ',FindOccurencesInString(Raw,Data),' xR=',Data,' xN=',n);
	if FindOccurencesInString(Raw, Data) < n then
		Exit;
	//writeln(' PASS');
	if n <= 0 then
		Exit;
	//writeln('SearchStr=',Data,' in ',Raw);
	LastPos := 0;
	NextPos := 0;
	c := 0;
	repeat
		c += 1;
		//writeln('Looking for [',Data,'] in [',GetStringPart(Raw, LastPos, -1),']');
		NextPos := Pos(Data, GetStringPart(Raw, LastPos, -1));
		LastPos += NextPos;
		if c >= n then
			begin
				//writeln('Match ',LastPos,' n=',c);
				FindOccurenceInString := LastPos - 1;
				Exit;
			end;
		until c >= Length(Raw);
	//writeln('EOS');
end;

function GetCSVParameterFromString(Id: Int64; CSV: ANSIString): ANSIString;
var
	StartPosition, EndPosition: Int64;

begin
	GetCSVParameterFromString := '';
	if (Length(CSV) <= 0) or (CSV[1] = ',') then //reject garbage
		Exit;
	if Id < 0 then
		Exit;
	if FindOccurencesInString(CSV, ',') < Id - 1 then
		Exit;
	StartPosition := FindOccurenceInString(CSV, ',', Id - 1) + 1;
	//writeln('Pos ',Id - 1,' of (,) in [',CSV,'] is ',StartPosition);
	EndPosition := FindOccurenceInString(CSV, ',', Id) - 1;
	if (EndPosition = 0) and (StartPosition > EndPosition) then
		EndPosition := Length(CSV);
	//writeln('SP/LP ',StartPosition,'/',EndPosition,' [',CSV,']');
	GetCSVParameterFromString := CSV[StartPosition..EndPosition];
end;

function GetCharSVParameterFromString(Id: Int64; CSV, Sep: ANSIString): ANSIString;
var
	StartPosition, EndPosition: Int64;

begin
	GetCharSVParameterFromString := '';
	if Id < 0 then
		Exit;
	if FindOccurencesInString(CSV, Sep) < Id - 1 then
		Exit;
	StartPosition := FindOccurenceInString(CSV, Sep, Id - 1) + 1;
	//writeln('Pos ',Id - 1,' of (,) in [',CSV,'] is ',StartPosition);
	EndPosition := FindOccurenceInString(CSV, Sep, Id) - 1;
	if (EndPosition = 0) and (StartPosition > EndPosition) then
		EndPosition := Length(CSV);
	//writeln('SP/LP ',StartPosition,'/',EndPosition,' [',CSV,']');
	GetCharSVParameterFromString := CSV[StartPosition..EndPosition];
end;

function StrArrayToStr(Dt: array of ANSIString): ANSIString;
var
	c: Int64;

begin
	if length(Dt) < 1 then
		Exit;
	
	StrArrayToStr := '';
	c := 0;
	repeat
		c += 1;
		StrArrayToStr += Dt[c];
		until c >= Length(Dt);
end;

function GetFileHeader(Source: ANSIString; Ln: Int64): FileHeader;
var
	Disk: Text;
	c: Int64;
	cIn: Char;

begin
	assign(Disk, Source);
	reset(Disk);
	//SetLength(GetFileHeader, Ln - 1);
	if Ln < 0 then
		Ln := 0;
	c := 0;
	repeat
		c += 1;
		read(Disk, cIn);
		GetFileHeader[c] := ord(cIn);
		until c >= Ln;
	close(Disk);
end;

function FindOccurencesInString(Raw: ANSIString; Data: ANSIString): Int64;
var
	Occurences: Int64;
	SearchPosition: Int64;

begin
	Occurences := 0;
	SearchPosition := 0;
	repeat
		SearchPosition := SearchPosition + 1;
		if (Raw[SearchPosition..SearchPosition + (Length(Data) - 1)] = Data) then
			Occurences := Occurences + 1;
		until SearchPosition + Length(Data) >= Length(Raw);
	FindOccurencesInString := Occurences;
end;

function FindOccurencesInFile(Path: String; Data: ANSIString): Int64;
var
	f: Text;
	Occurences: Int64;
	LineIn: ANSIString;
	
begin
	assign(f, Path);
	reset(f);
	
	Occurences := 0;
	
	repeat //feed loop
		readln(f, LineIn);
		Occurences := Occurences + FindOccurencesInString(upcase(LineIn), upcase(Data));
		until eof(f);
	FindOccurencesInFile := Occurences;
	close(f);		
end;

function FindOccurenceLineInFile(Path: ANSIString; Data: ANSIString; Occurence: Int64): Int64;
var
	LnIn: ANSIString;
	Ln: Int64;
	Found: Int64;
	disk: text;

begin
	assign(disk, Path);
	reset(disk);
	Ln := 0;
	Found := 0;
	repeat
		Ln := Ln + 1;
		readln(disk, LnIn);
		if FindOccurencesInString(upcase(LnIn), upcase(Data)) > 0 then
			Found := Found + 1;
		if Found = Occurence then
			FindOccurenceLineInFile := Ln;
		until (eof(disk)) or (Found = Occurence);
	if (eof(disk)) and (Found <> Occurence) then
		FindOccurenceLineInFile := 0
	else
		FindOccurenceLineInFile := Ln;
	close(Disk);
end;

function GetTagFromFile(Path: ANSIString; TagName: ANSIString; Occurence: Int64): ANSIString;
var
	f: Text;
	RAM: ANSIString;
	LineIn: ANSIString;
	Line: Int64;
	Target: Int64;
	SearchPosition: Int64;
	
begin
	Target := FindOccurenceLineInFile(Path, TagName, Occurence);
	if Target = 0 then
		begin
			GetTagFromFile := '';
			Exit;
		end;
	
	assign(f, Path);
	reset(f);
	
	Line := 0;
	repeat
		Line := Line + 1;
		readln(f, LineIn);
		until Line = Target;
	
	SearchPosition := 0;
	repeat
		SearchPosition := SearchPosition + 1;
		until LineIn[SearchPosition] = '<';
	
	RAM := '';
	
	SearchPosition := SearchPosition - 1;
	repeat
		SearchPosition := SearchPosition + 1;
		RAM := RAM + LineIn[SearchPosition];
		//writeln('SubS66');
		until LineIn[SearchPosition] = '>';
	
	GetTagFromFile := RAM;
	
	close(f);
end;

function StringParameterFromTag(Tag: ANSIString; Parameter: ANSIString): ANSIString;
var
	SearchPosition: Int64;
	RAM: ANSIString;
	Done: Boolean;
	
begin
	if FindOccurencesInString(upcase(Tag), upcase(Parameter)) = 0 then
		begin
			StringParameterFromTag := 'NULL';
			Exit;
		end;
		
	SearchPosition := 0;
	Done := False;
	RAM := '';
	repeat
		SearchPosition := SearchPosition + 1;
		if upcase(Tag[SearchPosition..SearchPosition + (Length(Parameter) - 1)]) = upcase(Parameter) then
			begin
				SearchPosition := SearchPosition - 1;
				repeat
					SearchPosition := SearchPosition + 1;
					until Tag[SearchPosition] = '"';
				SearchPosition := SearchPosition;
				repeat
					SearchPosition := SearchPosition + 1;
					if Tag[SearchPosition] <> '"' then
						RAM := RAM + Tag[SearchPosition];
				until Tag[SearchPosition] = '"';
				Done := True;
			end;
					
		until (SearchPosition + Length(Parameter) >= Length(Tag)) or (Done = True);
	StringParameterFromTag := RAM;
end;

function IntegerParameterFromTag(Tag: ANSIString; Parameter: ANSIString): Int64;
var
	RAM: ANSIString;
	
begin
	RAM := StringParameterFromTag(Tag, Parameter);
	if RAM <> 'NULL' then
		IntegerParameterFromTag := StrToInt(RAM)
	else
		IntegerParameterFromTag := 0;
end;

function LoadLinesToStr(Path: ANSIString; Start: Int64; Stop: Int64): ANSIString;
var
	f: Text;
	RAM: ANSIString;
	LineIn: ANSIString;
	Line: Int64;

begin
	assign(f, Path);
	reset(f);
	
	RAM := '';
	Line := 0;
	repeat
		Line := Line + 1;
		readln(f, LineIn);
		until Line + 1 = Start;
	
	//writeln('               LDLN2STR S1');
	
	repeat
		Line := Line + 1;
		readln(f, LineIn);
		RAM := RAM + LineIn;
		until Line = Stop;
	
	LoadLinesToStr := RAM;
	
	close(f);
end;

function GetTagText(Path: ANSIString; Tag: ANSIString; Occurence: Int64): ANSIString;
var
	ram: Int64;
	
begin	
	ram := FindOccurenceLineInFile(Path, upcase(Tag), Occurence) + 1;
	//writeln('Start at ',FindOccurenceLineInFile(Path, Tag, Occurence) + 1,' when finding [',tag,']');
	//delay(5000);
	Insert('/', Tag, Pos('<', Tag) + 1);
	//writeln('End at ',FindOccurenceLineInFile(Path, Tag, Occurence) - 1,' when finding [',tag,']');
	//delay(5000);
	GetTagText := LoadLinesToStr(Path, ram, FindOccurenceLineInFile(Path, Tag, Occurence) - 1 {skip the end </data> tag});
end;

procedure WriteStrInOrd(Str: ANSIString);
var
	Position: Int64;

begin
	//writeln('STRODCALL');
	Position := 0;
	write('[');
	repeat
		Position := Position + 1;
		write(Str[Position]);
		if ord(Str[Position]) = 10 then write('LF:');
		until Position >= Length(Str);
	writeln(']');
end;

procedure WriteStrToFile(Data, Path: ANSIString);
var
	Disk: Text;
	
begin
	if Length(Path) <= 0 then
		Exit;
	
	Assign(Disk, Path);
	Rewrite(Disk);
	Writeln(Disk, Data);
	Close(Disk);
end;

function LoadFileToStr(Path: ANSIString): ANSIString;
var
	f: Text;
	RAM: ANSIString;
	LineIn: ANSIString;

begin
	assign(f, Path);
	reset(f);
	RAM := '';
	repeat
		readln(f, LineIn);
		RAM := RAM + LineIn;
		until eof(f);
	close(f);
	LoadFileToStr := RAM;
end;

procedure WriteFileInOrd(Path: ANSIString);
var
	f: Text;
	LineIn: ANSIString;

begin
	assign(f, Path);
	reset(f);
	repeat
		readln(f, LineIn);
		WriteStrInOrd(LineIn);
		until eof(f);
	close(f);
end;

begin
end.
