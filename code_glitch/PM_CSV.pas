unit PM_CSV;

{$Mode ObjFpc}

interface

type
	CSVEntry = Object
			Field: array of ANSIString;
			Fields: Int64;
			
			procedure ParseString(Data: ANSIString);
			function GetString(): ANSIString;
		end;
	CSVFile = Object
			FieldNames, FieldTypes: CSVEntry;
			CSVData: array of CSVEntry;
			CSVEntries: Int64;
			
			private
				function Malloc(): Int64;
				
			public
				procedure LoadFromDisk(Src: ANSIString);
				procedure WriteToDisk(Dest: ANSIString);
				procedure DefineFieldName(Field: Int64; Name: ANSIString);
				procedure DefineFieldType(Field: Int64; Name: ANSIString);
				function GetFieldId(Name: ANSIString): Int64;
				function GetFieldName(Id: Int64): ANSIString;
				function GetFieldType(Id: Int64): ANSIString;	Overload;
				function GetFieldType(Name: ANSIString): ANSIString;	Overload;
				//function NextEmptyEntry(): Int64;
		end;

implementation

uses
	PM_TextUtils,
	PM_Utils;

function CSVEntry.GetString(): ANSIString;
var
	c: Int64;
	
begin
	GetString := '';
	if Fields > 0 then
		begin
			c := 0;
			repeat
				c += 1;
				GetString += Field[c];
				until c >= Fields;
		end;
	GetString := '';
end;

procedure CSVFile.DefineFieldName(Field: Int64; Name: ANSIString);
begin
	if FieldNames.Fields <= 0 then
		Exit;
	SetLength(FieldNames.Field, Field + 1);
end;

function CSVFile.Malloc(): Int64;
begin
	if CSVEntries <= 0 then
		begin
			CSVEntries := 0;
		end;
	CSVEntries += 1;
	SetLength(CSVData, CSVEntries + 1);
	Malloc := CSVEntries;
end;

procedure CSVEntry.ParseString(Data: ANSIString);
var
	c: Int64;
	
begin
	c := FindOccurencesInString(Data, ',');
	
	Fields := c;
	SetLength(Field, c + 1);
end;

procedure CSVFile.LoadFromDisk(Src: ANSIString);
var
	c: Int64;
	Disk: Text;
	Buffer: ANSIString;
	
begin
	If DoesFileExist(Src) = False then
		Exit;
	
	Assign(Disk, Src);
	Reset(Disk);
	
	c := 0;
	repeat
		c += 1;
		Readln(Disk, Buffer);
		if (c = 1) and (FindOccurencesInString(Upcase(Buffer), Upcase('PM_CSVF:NTV1')) > 0) then
			begin
				readln(Disk, Buffer);
				FieldNames.ParseString(Buffer);
				
				readln(Disk, Buffer);
				FieldTypes.ParseString(Buffer);
			end;
			
		if Length(Buffer) >= 1 then
			begin
				CSVData[Malloc].ParseString(Buffer);
			end;
		
		until Eof(Disk);
end;

procedure CSVFile.WriteToDisk(Dest: ANSIString);
begin
end;

begin
end.
