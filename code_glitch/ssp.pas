program fsp;

{$Mode ObjFpc}

uses
	cthreads,
	crt,
	PM_Utils,
	PM_TextUtils,
	PM_Threads;

const
	File_Src				:	ANSIString	=	'data.tsp';
	R_Range					:	Int64		=	180;
	MinChangeFactor			:	Real		=	0.01;
	AvgChangeAlpha			:	Real		=	0.1;
	MinChangeDistance		:	Int64		=	1;
	Jitter					:	Int64		=	50;
	MaxN					=	348;

type
	MemUnit = Packed Record
			X, Y: Int64;
			UUID: Int64;
			Shifts: Int64;
			LastImprovement: Int64;
		end;
	pMemUnit = ^MemUnit;
	DataStack = Array [1 .. MaxN] of MemUnit;
	

var
	Data: DataStack;
	Rq_Quit: Boolean = False;
	Pass: Int64;
	TotalPass: Int64;
	AvgChange: Real;
	FileName: ANSIString;
	
	BestScore: Real;
	BestList: array [1..MaxN] of Int64;

procedure PrintConfig();
begin
	writeln('R-Range             : ',R_Range);
	writeln('Jitter              : ',Jitter);
	writeln('Min Change factor   :',MinChangeFactor);
	writeln('Min Change distance : ',MinChangeDistance);
	writeln('Avg Change alpha    :',AvgChangeAlpha);
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
		Data[c].LastImprovement := 0;
		until eof(Disk);
		
	Close(Disk);
	
	writeln(GetTime(),': Reference list populated with ',c,' elements');
end;

function GetDistance(IDA, IDB: MemUnit): Real;
var
	RAM: Int64;
	
begin
	RAM := ((IDA.X - IDB.X) * (IDA.X - IDB.X)) + ((IDA.Y - IDB.Y) * (IDA.Y - IDB.Y));
	if RAM > 0 then
		GetDistance := sqrt( RAM )
	else
		GetDistance := 999999999999;
end;

var
	c: Int64;
	PassStart: Int64;
	Reporter_Active: Boolean;
	Reporter_Thread: Thread;

procedure Swap(n1, n2: Int64);
var
	MURam: MemUnit;

begin
	MURam := Data[n1];
	Data[n1] := Data[n2];
	Data[n2] := MURam;
end;

procedure MemUnitFromCSV(pDat: pMemUnit; Buffer: ANSIString);
begin
	with pDat^ do
		begin
			UUID := StrToInt(GetCSVParameterFromString(1, Buffer));
			X := StrToInt(GetCSVParameterFromString(2, Buffer));
			Y := StrToInt(GetCSVParameterFromString(3, Buffer));
			Shifts := StrToInt(GetCSVParameterFromString(4, Buffer));
			LastImprovement := StrToInt(GetCSVParameterFromString(5, Buffer));
		end;
end;

function MemUnitToCSV(Dat: MemUnit): ANSIString;
begin
	MemUnitToCSV := IntToStr(Dat.UUID) + ',' +
					IntToStr(Dat.X) + ',' + 
					IntToStr(Dat.Y) + ',' + 
					IntToStr(Dat.Shifts) + ',' + 
					IntToStr(Dat.LastImprovement);
end;

procedure LoadProgress();
var
	Disk: Text;
	c: Int64;
	Buffer: ANSIString;

begin
	Assign(Disk, 'progress');
	Reset(Disk);
	
	Readln(Disk, Pass);
	
	c := 0;
	repeat
		c += 1;
		Readln(Disk, Buffer);
		MemUnitFromCSV(@Data[c], Buffer);
		until c >= MaxN;
	
	Close(Disk);
end;

procedure SaveProgress();
var
	Disk: Text;
	c: Int64;

begin
	Assign(Disk, 'progress');
	Rewrite(Disk);
	
	writeln(Disk, Pass);
	
	c := 0;
	repeat
		c += 1;
		Writeln(Disk, MemUnitToCSV(Data[c]));
		until c >= MaxN;
	
	Close(Disk);
end;

procedure WriteLog(Fn: ANSIString);
var
	Disk: Text;
	c: Int64;

begin
	Assign(Disk, Fn);
	Rewrite(Disk);
	
	c := 0;
	repeat
		c += 1;
		Writeln(Disk, Data[c].UUID - 1);
		until c >= MaxN;
	
	Close(Disk);
	SaveProgress();
end;

procedure ReporterWorkload();
var
	Sum: Real;
	Position: Int64;

begin
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
			writeln(GetTime(),': new solution ',Sum,' pass=',TotalPass);
			WriteLog(FileName);
			//Pause(1000);
		end;
end;

var
	b, x, n: Int64;
	Delta: Real;

function GetOpPoint(Refine, nth: Int64): Int64;
var
	l: Int64;
	BestDelta: Real;
	BestID: Int64;
	CDelta: Real;
	Ran: Int64;
	
begin
	Ran := Random(Jitter) - (jitter div 2);
	Refine += Ran;
	
	if Refine <= 0 then
		Refine := 1;
	
	if Refine >= MaxN then
		Refine := MaxN - 2;
		
	BestDelta := 0;
	BestID := Refine;
	l := Refine - R_Range;
	
	if l <= 0 then
		l := 1;
		
	repeat
		l += 1;
		
		CDelta :=  GetDistance(Data[Refine], Data[nth]) - GetDistance(Data[Refine], Data[l]);
		if (CDelta > BestDelta) and (abs(Refine - nth) > MinChangeDistance) then
			begin
				BestDelta := CDelta;
				BestID := l;
			end;
		
		until (l >= Refine + R_Range) or (l >= MaxN);
	GetOpPoint := BestID;
end;

procedure NewFileName();
var
	fnn: Int64;
	
begin
	fnn := 0;
	repeat
		fnn += 1;
		FileName:= 'output-' + IntToStr(fnn) + '.txt';
		until DoesFileExist(FileName) = False;
end;

begin
	NewFileName();
	PrintConfig();
{
	CreateThread(@Reporter_Thread, 'rt', 'rt');
	Reporter_Thread.SetTargetProcedure(@ReporterWorkload);
	Reporter_Active := False;
	Reporter_Thread.Run();
}

	AvgChange := 0;
	if DoesFileExist('progress') then
		LoadProgress()
	else
		LoadStack(File_Src);
	
	BestScore := 999999999999;
	ReporterWorkload();
	
	TotalPass := 0;
	Pass := 0;
	repeat
		TotalPass += 1;
		Pass += 1;
		PassStart := GetTime();
		//writeln(GetTime(),': Starting pass ',Pass);
		
		b := 0;
		repeat
			b += 1;
			
			c := 1; //loop mus start at 2
			repeat
				c += 1;
				x := GetOpPoint(b, c);
				Delta := GetDistance(Data[c - 1], Data[c]) + GetDistance(Data[c], Data[c + 1]);
				Delta -= (GetDistance(Data[c - 1], Data[x]) + GetDistance(Data[x], Data[c + 1]));
				
				//if (Delta > AvgChange * MinChangeFactor) then
				if (Delta > 0) and (Data[x].Shifts < 1000)  then
					begin
						Data[x].LastImprovement := round(Data[x].LastImprovement * 0.9);
						Data[x].Shifts += 1;
						//AvgChange := (AvgChangeAlpha * AvgChange) + ((1 - AvgChangeAlpha) * Delta);
						Swap(c, x);
					end
				else
					Data[x].Shifts -= 1;
					
				until c >= MaxN - 1;
			until b >= MaxN;
			
			
		//writeln(GetTime(),': Pass ',Pass,' complete after ',GetTime() - PassStart,'ms');
		ReporterWorkload();
		
		if KeyPressed() = True then
			if ReadKey() = #27 then
				RQ_Quit := True;
		
		if Pass >= MaxN - 1 then
			Pass := 0;
		until (Rq_Quit = True) or (Pass >= MaxN - 1);
end.
