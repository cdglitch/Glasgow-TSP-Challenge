unit PM_Logs;

{$Mode ObjFpc}

interface

uses
PM_Defaults;

type
	PM_LogInfoController = Object
			LogLevel: Int64;
			LogToTerminal: Boolean;
			LogToDisk: Boolean;
			LogPath: ANSIString;
		end;
	pPM_LogInfoController = ^PM_LogInfoController;
	LogConfig = PM_LogInfoController;
	pLogConfig = ^LogConfig;

var
	PM_VanillaLogConfig: LogConfig;
	PM_CurrentLogConfig: pLogConfig;

const
	PMLog_DefaultConfig_DefaultLogConfigPtr	:	pLogConfig	=	@PM_VanillaLogConfig;

procedure LogMsg(Msg: ANSIString);
procedure UseLogConfig(pLogCfg: pLogConfig);
procedure UseDefaultLogConfig();
procedure LogToTerminal(Val: Boolean);
procedure LogToDisk(Val: Boolean);
procedure SetLogLevel(LvlStr: ANSIString);
function GetDefaultLogConfig(): LogConfig;
procedure WriteLogHeader();
procedure WriteLogFooter();
function IsLogMessage(Raw: ANSIString): Boolean;
function GetLoglevelFromString(Raw: ANSIString): Int64;

implementation

uses
	SysUtils,
	PM_Utils;

procedure SetLogLevel(LvlStr: ANSIString);
begin
	PM_CurrentLogConfig^.LogLevel := GetLoglevelFromString(LvlStr);
end;

procedure LogToDisk(Val: Boolean);
begin
	PM_CurrentLogConfig^.LogToDisk := Val;
end;

procedure LogToTerminal(Val: Boolean);
begin
	PM_CurrentLogConfig^.LogToTerminal := Val;
end;

function GetLoglevelFromString(Raw: ANSIString): Int64;
var
	c: Int64;
	
begin
	GetLoglevelFromString := 0;
	if PM_CurrentLogConfig^.LogLevel = 0 then
		Exit;
	c := 0;
	repeat
		c += 1;
		if (upcase(Raw[1..4]) = upcase(PMLogs_LevelInfo[c])) then
			begin
				GetLoglevelFromString := c;
				Exit;
			end;
		until c >= Length(PMLogs_LevelInfo);
end;

function IsLogMessage(Raw: ANSIString): Boolean;
var
	c: Int64;
	
begin
	if PM_CurrentLogConfig^.LogLevel = 0 then
		Exit;
	c := 0;
	repeat
		c += 1;
		if (upcase(Raw[1..4]) = PMLogs_LevelInfo[c]) then
			begin
				IsLogMessage := True;
				Break;
			end;
		until c >= Length(PMLogs_LevelInfo);
end;

procedure LogOutput(Op: ANSIString);
var
	DiskLog: Text;

begin
	if IsLogMessage(Op) then
		Op := '+' + IntToStr(GetTime()) + '::' + Op;
	with PM_CurrentLogConfig^ do
		begin
			if LogToTerminal = True then
				writeln(Op);
			if LogToDisk = True then
				begin
					if Length(LogPath) <= 0 then
						Exit;
					Assign(DiskLog, LogPath);
					if FileExists(LogPath) then
						Append(DiskLog)
					else
						ReWrite(DiskLog);
					writeln(DiskLog, Op);
					Flush(DiskLog);
					Close(DiskLog);
				end;
		end;
end;

procedure LogMsg(Msg: ANSIString);
begin
	if PM_CurrentLogConfig^.LogLevel = 0 then
		Exit;
	if GetLoglevelFromString(Msg) <= PM_CurrentLogConfig^.LogLevel then
		LogOutput(Msg);
end;

function GetDefaultLogConfig(): LogConfig;
begin
	GetDefaultLogConfig.LogPath := PMLog_DefaultConfig_LogPath;
	GetDefaultLogConfig.LogLevel := PMLog_DefaultConfig_LogLevel;
	GetDefaultLogConfig.LogToDisk := PMLog_DefaultConfig_LogToDisk;
	GetDefaultLogConfig.LogToTerminal := PMLog_DefaultConfig_LogToTerminal;
end;

procedure UseLogConfig(pLogCfg: pLogConfig);
begin
	PM_CurrentLogConfig := pLogCfg;
end;

procedure UseDefaultLogConfig();
begin
	PM_CurrentLogConfig := PMLog_DefaultConfig_DefaultLogConfigPtr;
end;

procedure WriteLogHeader();
begin
	LogOutput('*---------------------------PROMETHEUS LOG START-------------------------------*');
	LogOutput('Prometheus log system started... Runtime +' + IntToStr(GetTime()) + 'ms');
	//LogOutput('*------------------------------------------------------------------------------*');
end;

procedure WriteLogFooter();
begin
	//LogOutput('*------------------------------------------------------------------------------*');
	LogOutput('Prometheus log system halted... Runtime +' + IntToStr(GetTime()) + 'ms');
	LogOutput('*---------------------------PROMETHEUS LOG END---------------------------------*');
end;

begin
	PM_VanillaLogConfig := GetDefaultLogConfig();
	UseDefaultLogConfig();
	WriteLogHeader();
	PM_VanillaLogConfig.LogLevel := 0;
end.
