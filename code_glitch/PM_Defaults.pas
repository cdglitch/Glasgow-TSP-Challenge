unit PM_Defaults;

interface

const
	//Defaults from PM_Logs
	PMLogs_LevelInfo							:array [1..4] of String[4]		=	('STOP', 'ERRO', 'WARN', 'INFO'); //The first 4 chars of the message to look for
	
	PMLog_DefaultConfig_LogLevel				:Int64							=	5;
	PMLog_DefaultConfig_LogToTerminal			:Boolean						=	False;
	PMLog_DefaultConfig_LogToDisk				:Boolean						=	True;
	PMLog_DefaultConfig_LogPath					:ANSIString						=	'PMDefaultLog.log';
	
	//Defaults from PM_Threads
	PMThread_DefaultBenchChunk					:Int64							=	95000000;
	PMThread_DefaultBenchCycles					:Int64							=	3000000;
	PMThread_MaxBenchThreads					:Int64							=	60;
	PMThread_MinBenchmarkDepth					:Int64							=	2;
	PMThread_ShortBenchTimeOut					:Int64							=	160;
	PMThread_LongBenchTimeOut					:Int64							=	4000;
	PMThread_ThreadIDPrefix						:ANSIString						=	'PMThread';
	PMThread_RootThreadIDPrefix					:ANSIString						=	'PMSYS.NoID//';
	PMThread_IDSparator							:ANSIString						=	'::';
	
	PMThread_Status_Normal						:Int64							=	0;
	PMThread_Status_Error_UnexpectedTermination	:Int64							=	-1;
	PMThread_Status_Info_Ready					:Int64							=	1;
	
	//Defaults from PM_Event
	Event_Window								:QWord							=	$1000100;
		Window_Resize							:QWord							=	$1000101;
		Window_Close							:QWord							=	$1000102;
		Window_Minimize							:QWord							=	$1000103;
		Window_Restore							:QWord							=	$1000104;
		Window_Maximize							:QWord							=	$1000105;

	Event_Key									:QWord							=	$1000200;
		Key_Down								:QWord							=	$1000201;
		Key_Up									:QWord							=	$1000202;
		
	Event_Mouse									:QWord							=	$1000300;
		Mouse_Motion							:QWord							=	$1000301;
		
		MouseButton_LeftDown					:QWord							=	$1000311;
		MouseButton_LeftUp						:QWord							=	$1000312;
		
		MouseButton_RightDown					:QWord							=	$1000321;
		MouseButton_RightUp						:QWord							=	$1000322;
		
		MouseButton_MiddleDown					:QWord							=	$1000331;
		MouseButton_MiddleUp					:QWord							=	$1000332;
		
	Event_Focus									:QWord							=	$1000400;
		Focus_Gained							:QWord							=	$1000401;
		Focus_Lost								:QWord							=	$1000402;
		
	Event_Idle									:QWord							=	$1000500;
		Event_NoEvent							:QWord							=	$1000501;

implementation

begin
end.
