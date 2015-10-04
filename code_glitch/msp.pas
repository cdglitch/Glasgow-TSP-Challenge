program msp;

{$Mode ObjFpc}

uses
	cthreads,
	crt,
	PM_Utils,
	PM_TextUtils,
	PM_Threads;

const
	MemBlock_Size			:	Int64		=	20;
	File_Src				:	ANSIString	=	'data.tsp';
	Folder_Output			:	ANSIString	=	'out/';
	nThreads				=	4;
	MaxN					=	348;

type
	MemUnit = Packed Record
			X, Y: Int64;
			UUID: Int64;
		end;
	DataStack = Array [1 .. MaxN] of MemUnit;
	oContainer = Object
			WorkerThread: Thread;
			ThreadNo: Int64;
			
			procedure ContWLoad();
			procedure Initialize();
		end;
	

var
	Data: DataStack;
	Rq_Quit: Boolean = False;

	BestScore: Real;
	BestList: array [1..MaxN] of Int64;
	Container: array [1..nThreads] of oContainer;

procedure oContainer.Initialize();
begin
	CreateThread(@WorkerThread, 'cont', 'worker');
	WorkerThread.SetTargetProcedure(@ContWLoad);
	WorkerThread.Run();
end;

procedure LoadStack(Src: ANSIString);
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
	//Tgt^.Malloc(c);
	writeln(GetTime(),': Generated reference list for ',c,' points');
	
	c := 0;
	repeat
		c += 1;
		Readln(Disk, Buffer);
		Data[c].X := StrToInt(GetCharSVParameterFromString(1, Buffer, ' '));
		Data[c].Y := StrToInt(GetCharSVParameterFromString(2, Buffer, ' '));
		Data[c].UUID := c;
		until eof(Disk);
		
	Close(Disk);
	
	writeln(GetTime(),': Reference list populated with ',c,' elements');
end;

function GetDistance(IDA, IDB: MemUnit): Real;
begin
	GetDistance := sqrt( ((IDA.X - IDB.X) * (IDA.X - IDB.X)) + ((IDA.Y - IDB.Y) * (IDA.Y - IDB.Y)) );
end;

var
	Reporter_Thread: Thread;

procedure Swap(n1, n2: Int64);
var
	MURam: MemUnit;

begin
	MURam.X := Data[n1].X;
	MURam.Y := Data[n1].Y;
	MURam.UUID := Data[n1].UUID;
	
	Data[n1].X := Data[n2].X;
	Data[n1].Y := Data[n2].Y;
	Data[n1].UUID := Data[n2].UUID;
	
	Data[n2].X := MURam.X;
	Data[n2].Y := MURam.Y;
	Data[n2].UUID := MURam.UUID;
end;

procedure WriteLog(n: Int64);
var
	Disk: Text;
	c: Int64;

begin
	Assign(Disk, 'output.txt');
	Rewrite(Disk);
	
	c := 0;
	repeat
		c += 1;
		Writeln(Disk, Data[c].UUID - 1);
		until c >= MaxN;
	
	Close(Disk);
end;

procedure oContainer.ContWLoad();
var
	Pass: Int64;
	c: Int64;
	PassStart: Int64;
	Reporter_Active: Boolean;
	b, x: Int64;
	Sum: Real;
	Position: Int64;
	
begin	
	Pass := 0;
	repeat
		Pass += 1;
		PassStart := GetTime();
		//writeln(GetTime(),': Starting pass ',Pass);
		
		b := 0;
		repeat
			b += 1;
			
			repeat
				x := Random(MaxN * 2) - 5;
				until (x <= 348) and (x > 0);
				
			c := 0;
			repeat
				c += 1;
				if GetDistance(Data[b], Data[c]) < GetDistance(Data[b], Data[x]) then
					Swap(c, b);
				until c >= MaxN;
			until b >= MaxN;
			
			
		//writeln(GetTime(),': Pass ',Pass,' complete after ',GetTime() - PassStart,'ms');
		//ReporterWorkload();
		Sum := 0;
		Position := 0;
		repeat
			Position += 1;
			Sum += GetDistance(Data[Position], Data[Position + 1]);
			until Position >= MaxN - 1;
		
		//writeln(GetTime(),'; Reported calculated length of ',Sum);
		if Sum < BestScore then
			begin
				Position := 0;
				repeat
					Position += 1;
					BestList[Position] := Data[Position].UUID;
					until Position >= MaxN;
				BestScore := Sum;
				writeln(GetTime(),': new solution from thread ',ThreadNo,' = ',Sum);
				WriteLog(Pass);
				//Pause(1000);
			end;
			
		if KeyPressed() = True then
			if ReadKey() = #27 then
				RQ_Quit := True;
		
		if Pass >= MaxN - 1 then
			Pass := 0;
		until (Rq_Quit = True);
end;

var
	ct: Int64;

begin
	LoadStack(File_Src);
	
	BestScore := 999999999999;

	ct := 0;
	repeat
		ct += 1;
		Container[ct].ThreadNo := ct;
		Container[ct].Initialize();
		until ct >= nThreads;
	
	repeat
		Pause(10);
		Until RQ_Quit = True;
end.
