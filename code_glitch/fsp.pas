program fsp;

{$Mode ObjFpc}

uses
	cthreads,
	
	PM_Utils,
	PM_TextUtils,
	PM_Threads;

const
	MemBlock_Size			:	Int64		=	20;
	File_Src				:	ANSIString	=	'data.tsp';
	nThreads				:	Int64		=	4;

type
	Point = Packed Record
			X, Y: Int64;
			InSolution: Boolean;
		end;
	PointList = Object
			Data: array of Point;
			Points: Int64;
			
			procedure Malloc(Sz: Int64);
		end;
	pPointList = ^PointList;
	OrderList = Object
			Data: array of Int64;
			Points: Int64;
			AllocSize: Int64;
			
			procedure Malloc(Sz: Int64);
		end;
	MemoryCore = Object
			List: array of OrderList;
			Lists: Int64;
			
			procedure Malloc(Sz: Int64);
		end;
	pMemoryCore = ^MemoryCore;
	MemoryComplex = Object
			Core: array of MemoryCore;
			Cores: Int64;
			AllocSize: Int64;
			
			function GetNewCore(Lists, SubSize: Int64): Int64;
		end;
	Worker = Object
			Data: MemoryComplex;
			Source: PointList;
			Seed: OrderList;
			CurrentCore: pMemoryCore;
			UUID: ANSIString;
			ComplexityLevel: Int64;
			
			procedure Main();
		end;

var
	ReferenceList: PointList;
	//T: array [1..nThreads] of ThreadContainer;

function MemoryComplex.GetNewCore(Lists, SubSize: Int64): Int64;
var
	c: Int64;
	
begin
	Cores += 1;
	if Cores >= AllocSize then
		begin
			repeat
				AllocSize += MemBlock_Size;
				until AllocSize >= Cores;
			SetLength(Core, AllocSize + 1);
		end;
	
	Core[Cores].Malloc(Lists);
	c := 0;
	repeat
		c += 1;
		Core[Cores].List[c].Malloc(SubSize);
		until c >= SubSize;
		
	GetNewCore := Cores;
end;

procedure MemoryCore.Malloc(Sz: Int64);
begin
	Lists := Sz;
	SetLength(List, Sz + 1);
end;

procedure OrderList.Malloc(Sz: Int64);
begin
	Points := Sz;
	SetLength(Data, Sz + 1);
end;

procedure PointList.Malloc(Sz: Int64);
begin
	Points := Sz;
	SetLength(Data, Sz + 1);
end;

procedure GenerateReferenceList(Src: ANSIString; Tgt: pPointList);
var
	Disk: Text;
	Buffer: ANSIString;
	c: Int64;
	
begin
	if DoesFileExist(Src) = false then
		begin
			writeln('File not found!');
			Exit;
		end;
	
	Assign(Disk, Src);
	Reset(Disk);
	
	c := 0;
	repeat
		c += 1;
		Readln(Disk, Buffer);
		until eof(Disk);
	
	Reset(Disk);
	Tgt^.Malloc(c);
	writeln('Generated reference list for ',c,' points');
	
	c := 0;
	repeat
		c += 1;
		Readln(Disk, Buffer);
		Tgt^.Data[c].X := StrToInt(GetCharSVParameterFromString(1, Buffer, ' '));
		Tgt^.Data[c].Y := StrToInt(GetCharSVParameterFromString(2, Buffer, ' '));
		Tgt^.Data[c].InSolution := False;
		until eof(Disk);
		
	Close(Disk);
	
	writeln('Reference list populated!');
end;

procedure Worker.Main();
var
	c: Int64;
	
begin
	GenerateReferenceList(File_Src, @Source);
	c := Data.GetNewCore(Seed.Points, Source.Points);
	CurrentCore := @Data.Core[c];
	
	//Seed stage
	c := 0;
	repeat
		c += 1;
		CurrentCore^.List[c].Data[0] := Seed.Data[c];
		until c >= Seed.Points;
	
	ComplexityLevel := 1;
	repeat
		ComplexityLevel += 1;
		Data.Core[ComplexityLevel].List
end;

begin
end.
