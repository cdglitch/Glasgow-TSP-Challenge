unit PM_Threads;

{$Mode ObjFpc}{$H+}

interface

uses
	{$IfDef Linux}
		cthreads,
		cmem,
	{$EndIf}
	classes,
	
	PM_Defaults,
	PM_Logs,
	PM_Utils;

type
	Proc = Procedure();
	ObjProc = Procedure of Object;
	pProc = ^Proc;
	pThread = ^Thread;
	PM_ThreadComponent = Class(TThread)
			Parent: pThread;
			procedure Execute(); Override;
		end;
	Thread = Object
			Initialized: Boolean;
			ExecutionTarget: Proc;
			ExecutionTarget_Object: ObjProc;
			ObjectMode: Boolean;
			ThreadCore: PM_ThreadComponent;
			StartedStamp, StoppedStamp: Int64;
			Busy: Boolean;
			ThreadIdentifier: ANSIString;
			
			procedure SetTargetProcedure(Tgt: Proc); Overload;
			procedure SetTargetProcedure(Tgt: ObjProc); Overload;
			procedure Run();
			procedure Empty();
			procedure Halt();
		end;
	ThreadArray = array of Thread;
	pThreadArray = ^ThreadArray;

function GetOptimalThreadCount(): Int64;
function GetAverageOptimalThreadCount(Runs: Int64): Int64;
procedure CreateThread(pTh: pThread; CallerEntity, RegisteredName: ANSIString);
function GenerateThreadIdentifier(CallerID, Child: ANSIString): ANSIString;
	
implementation

function GenerateThreadIdentifier(CallerID, Child: ANSIString): ANSIString;
var
	Ram: ANSIString;
	
begin
	if CallerID = '' then
		CallerID := PMThread_RootThreadIDPrefix;
	Ram := CallerID + PMThread_ThreadIDPrefix + PMThread_IDSparator + Child + PMThread_IDSparator + IntToStr(GetTime);
	GenerateThreadIdentifier := Ram;
	LogMsg('Info: PMThread.GenerateThreadIdentifier leased [' + Ram + ']');
end;

procedure Thread.Empty();
begin
	try
		Halt();
		ThreadCore.Destroy();
	except
		LogMsg('Error: PM_Thread.Empty() ['+ThreadIdentifier+'] could not be destroyed!');
	end;
	Initialized := False;
	ExecutionTarget := Nil;
	StartedStamp := 0;
	StoppedStamp := 0;
	Busy := False;
end;

procedure Thread.Halt();
begin
	if (Busy = True) then
		ThreadCore.Terminate();
	Busy := False;
end;

procedure Thread.Run();
begin
	Busy := True;
	if Initialized = False then
		begin
			LogMsg('Warn: PMThread.Initialize not called on current thread. Initializing for you >.>');
		end;
	StartedStamp := GetTime();
	StoppedStamp := 0;
	ThreadCore.Start();
end;

procedure Thread.SetTargetProcedure(Tgt: Proc);
begin	
	ObjectMode := False;
	if Initialized = False then
		LogMsg('Warn: PMThread.Initialize not called on current thread');
	ExecutionTarget := Tgt;
end;

procedure Thread.SetTargetProcedure(Tgt: ObjProc);
begin	
	ObjectMode := True;
	if Initialized = False then
		LogMsg('Warn: PMThread.Initialize not called on current thread');
	ExecutionTarget_Object := Tgt;
end;

procedure CreateThread(pTh: pThread; CallerEntity, RegisteredName: ANSIString);
begin
	with pTh^ do
		begin
			if Initialized = True then
				Empty();
				
			ThreadCore := PM_ThreadComponent.Create(True);
			ThreadCore.FreeOnTerminate := False;
			ThreadCore.Parent := pTh;
			ThreadIdentifier := GenerateThreadIdentifier(CallerEntity, RegisteredName);
			
			Initialized := True;
			LogMsg('Info: PMThread.Initialize call finalized');
		end;
end;

procedure PM_ThreadComponent.Execute();
begin
	if Parent^.ObjectMode = False then
		begin
			if Parent^.ExecutionTarget <> Nil then
				begin
					Parent^.ExecutionTarget();
					Parent^.StoppedStamp := GetTime();
				end;
			if Parent^.StoppedStamp - Parent^.StartedStamp < 0 then
				LogMsg('Error: PM_ThreadComponent.Execute - general execution failure');
		end
	else
		begin
			if Parent^.ExecutionTarget_Object <> Nil then
				begin
					Parent^.ExecutionTarget_Object();
					Parent^.StoppedStamp := GetTime();
				end;
			if Parent^.StoppedStamp - Parent^.StartedStamp < 0 then
				LogMsg('Error: PM_ThreadComponent.Execute - general execution failure [OBJMode]');
		end;
end;

procedure BenchProc();
var
	c: Int64;

begin
	c := 0;
	repeat
		c += 1;
		until c >= PMThread_DefaultBenchCycles * PMThread_DefaultBenchChunk;
end;

procedure AllocateBenchThreads(ThreadMem: pThreadArray; t: Int64);
var
	c: Int64;
	
begin
	SetLength(ThreadMem^, t + 1);
	c := 0;
	repeat
		c += 1;
		
		CreateThread(@ThreadMem^[c], '', 'PMBenchThread_Worker');
		ThreadMem^[c].SetTargetProcedure(@BenchProc);
		until c >= t;
end;

procedure AllocateIntegers(IntMem: pIntArray; t: Int64);
begin
	SetLength(IntMem^, t + 1);
end;

function GetThreadExecutionTimes(TA: pThreadArray; t: Int64): IntArray;
var
	c: Int64;
	LocalSet: IntArray;
	SetValues: Int64;
	
begin
	AllocateIntegers(@LocalSet, t);
	c := 0;
	repeat
		c += 1;
		LocalSet[c] := 0;
		until c >= t;
	c := 0;
	SetValues := 0;
	repeat
		c += 1;
		if c > t then
			c := 1;
		if (TA^[c].Busy = False) and (LocalSet[c] <= 0) then
			begin
				LocalSet[c] := TA^[c].StartedStamp - TA^[c].StoppedStamp;
				SetValues += 1;
				//writeln('Thread ',c,' took ',LocalSet[c],'ms');
			end;
		{if (TA^[c].StoppedStamp - TA^[c].StartedStamp > PMThread_ShortBenchTimeout) and (TA^[c].Busy = True) then
			begin
				LocalSet[c] := PMThread_ShortBenchTimeout * 2;
				SetValues += 1;
				writeln('timeout');
				TA^[c].Halt
			end;}
		until SetValues >= t;
	GetThreadExecutionTimes := LocalSet;
end;

function GetIntegerArraySum(Dt: pIntArray; t: Int64): Int64;
var
	c: Int64;
	rt: Int64;

begin
	c := 0;
	rt := 0;
	repeat
		c += 1;
		rt := rt + (Dt^[c]);
		until c >= t;
	GetIntegerArraySum := rt;
end;

procedure EmptyThreadArray(Th: pThreadArray; t: Int64);
var
	c: Int64;

begin
	c := 0;
	repeat
		c += 1;
		Th^[c].Halt();
		until c >= t;
	SetLength(Th^, 0);
end;

procedure ExecThreadArray(TA: pThreadArray; t: Int64);
var
	c: Int64;
	
begin
	c := 0;
	repeat
		c += 1;
		TA^[c].Run();
		until c >= t;
end;

function GetOptimalThreadCount(): Int64;
var
	TestThreads: array of Thread;
	TestTimes: array of Int64;
	LastAverage, CurrentAverage: Int64;
	c: Int64;
	
begin
	c := 0;
	CurrentAverage := 0;
	AllocateBenchThreads(@TestThreads, PMThread_MaxBenchThreads + 1);
	AllocateIntegers(@TestTimes, PMThread_MaxBenchThreads + 1);
	repeat
		c += 1;
		//writeln('alloc pass');
		ExecThreadArray(@TestThreads, c);
		//writeln('exec pass');
		TestTimes := GetThreadExecutionTimes(@TestThreads, c);
		//writeln('times pass');
		LastAverage := CurrentAverage;
		CurrentAverage := (GetIntegerArraySum(@TestTimes, c) * PMThread_DefaultBenchCycles) div c;
		//writeln('avg pass');
		if c = 1 then
			LastAverage := CurrentAverage;
		//writeln(c,' threads took ',CurrentAverage,'ms per chunk. Last was ',LastAverage,'ms');
		//writeln('empty pass');
		//writeln('reset pass');
		until ((c > 1) and (CurrentAverage > LastAverage)) or (c >= PMThread_MaxBenchThreads);
	GetOptimalThreadCount := c - 1;
	EmptyThreadArray(@TestThreads, PMThread_MaxBenchThreads + 1);
	SetLength(TestTimes, 0);
	writeln('Returned ',c - 1,' as optimal thread count');
end;

function GetAverageOptimalThreadCount(Runs: Int64): Int64;
var
	c: Int64;
	Rt: Real;

begin
	//AveragebenchStart := GetTime();
	c := 0;
	Rt := 0;
	repeat
		c += 1;
		Rt += GetOptimalThreadCount() / Runs;
		until c >= Runs;
	GetAverageOptimalThreadCount := round(Rt);
end;

begin
end.
