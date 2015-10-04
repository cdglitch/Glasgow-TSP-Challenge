unit PM_Debug;

interface

uses
	SysUtils;

type
	oPM_DBG = object
			WriteToFile: Boolean;
			WriteToConsole: Boolean;
			DebugFile: ANSIString;
		end;

var
	PrometheusDebugData: oPM_DBG;
	
procedure DebugWrite(Dat: ANSIString);
procedure DebugWriteln(Dat: ANSIString);
procedure DebugToTerminal(Val: Boolean);
procedure WriteToDisk(Val: Boolean);
procedure SetDebugLogPath(Dat: ANSIString);


implementation

procedure DebugToTerminal(Val: Boolean);
begin
	PrometheusDebugData.WriteToConsole := Val;
end;

procedure WriteToDisk(Val: Boolean);
begin
	PrometheusDebugData.WriteToFile := Val;
end;

procedure SetDebugLogPath(Dat: ANSIString);
begin
	PrometheusDebugData.DebugFile := Dat;
end;

procedure DebugWrite(Dat: ANSIString);
var
	Disk: Text;
	
begin
	if PrometheusDebugData.WriteToConsole = True then
		Write(Dat);
	if PrometheusDebugData.WriteToFile = True then
		begin
			Assign(Disk, PrometheusDebugData.DebugFile);
			if FileExists(PrometheusDebugData.DebugFile) then
				Append(Disk)
			else
				Rewrite(Disk);
			Write(Disk, Dat);
			Close(Disk);
		end;
end;

procedure DebugWriteln(Dat: ANSIString);
var
	Disk: Text;
	
begin
	if PrometheusDebugData.WriteToConsole = True then
		Writeln(Dat);
	if PrometheusDebugData.WriteToFile = True then
		begin
			Assign(Disk, PrometheusDebugData.DebugFile);
			if FileExists(PrometheusDebugData.DebugFile) then
				Append(Disk)
			else
				Rewrite(Disk);
			Writeln(Disk, Dat);
			Close(Disk);
		end;
end;

begin
	PrometheusDebugData.WriteToFile := False;
	PrometheusDebugData.WriteToConsole := False;
	if PrometheusDebugData.DebugFile = '' then
		PrometheusDebugData.DebugFile := 'PrometheusLog.txt';
	PrometheusDebugData.WriteToConsole := False;
	DebugWriteln('');
	DebugWriteln('X-----DBG SYSTEM STARTUP-----X');
end.
