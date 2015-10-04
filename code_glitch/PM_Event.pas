unit PM_Event;

interface

const
	Event_Window				:QWord		=	$1000100;
		Window_Resize			:QWord		=	$1000101;
		Window_Close			:QWord		=	$1000102;
		Window_Minimize			:QWord		=	$1000103;
		Window_Restore			:QWord		=	$1000104;
		Window_Maximize			:QWord		=	$1000105;

	Event_Key					:QWord		=	$1000200;
		Key_Down				:QWord		=	$1000201;
		Key_Up					:QWord		=	$1000202;
		
	Event_Mouse					:QWord		=	$1000300;
		Mouse_Motion			:QWord		=	$1000301;
		
		MouseButton_LeftDown	:QWord		=	$1000311;
		MouseButton_LeftUp		:QWord		=	$1000312;
		
		MouseButton_RightDown	:QWord		=	$1000321;
		MouseButton_RightUp		:QWord		=	$1000322;
		
		MouseButton_MiddleDown	:QWord		=	$1000331;
		MouseButton_MiddleUp	:QWord		=	$1000332;
		
	Event_Focus					:QWord		=	$1000400;
		Focus_Gained			:QWord		=	$1000401;
		Focus_Lost				:QWord		=	$1000402;
		
	Event_Idle					:QWord		=	$1000500;
		Event_NoEvent			:QWord		=	$1000501;

type
	PM_EventStore = Object
			LastEventType: QWord;
			LastEventDetail: QWord;
			
			LastKeyID: Int64;
			LastMouseX, LasMouseY: Int64;
			
			Focused: Boolean;
			
			MouseX, MouseY: Int64;
			KeyDown: array [0..255] of Boolean;
		end;
		
function IsKeyPressed(ID: Int64): Boolean;
function IsKeyUp(): Boolean;
function IsKeyDown(): Boolean;
function GetKeyUp(): Int64;
function GetKeyDown(): Int64;
function IsIdle(): Boolean;
function IsClose(): Boolean;
function GetMouseX(): Int64;
function GetMouseY(): Int64;
function IsLeftMouseDown(): Boolean;
function IsLeftMouseUp(): Boolean;
function IsRightMouseDown(): Boolean;
function IsRightMouseUp(): Boolean;

var
	PrometheusEventData: PM_EventStore;

implementation

function IsLeftMouseDown(): Boolean;
begin
	if (PrometheusEventData.LastEventType = Event_Mouse) and (PrometheusEventData.LastEventDetail = MouseButton_LeftDown) then
		IsLeftMouseDown := True
	else
		IsLeftMouseDown := False;
end;

function IsLeftMouseUp(): Boolean;
begin
	if (PrometheusEventData.LastEventType = Event_Mouse) and (PrometheusEventData.LastEventDetail = MouseButton_LeftUp) then
		IsLeftMouseUp := True
	else
		IsLeftMouseUp := False;
end;

function IsRightMouseDown(): Boolean;
begin
	if (PrometheusEventData.LastEventType = Event_Mouse) and (PrometheusEventData.LastEventDetail = MouseButton_RightDown) then
		IsRightMouseDown := True
	else
		IsRightMouseDown := False;
end;

function IsRightMouseUp(): Boolean;
begin
	if (PrometheusEventData.LastEventType = Event_Mouse) and (PrometheusEventData.LastEventDetail = MouseButton_RightUp) then
		IsRightMouseUp := True
	else
		IsRightMouseUp := False;
end;

function GetMouseX(): Int64;
begin
	GetMouseX := PrometheusEventData.MouseX;
end;

function GetMouseY(): Int64;
begin
	GetMouseY := PrometheusEventData.MouseY;
end;

function IsClose(): Boolean;
begin
	if (PrometheusEventData.LastEventType = Event_Window) and (PrometheusEventData.LastEventDetail = Window_Close) then
		IsClose := True
	else
		IsClose := False;
end;

function IsIdle(): Boolean;
begin
	if PrometheusEventData.LastEventType = Event_Idle then
		IsIdle := True
	else
		IsIdle := False;
end;

function IsKeyDown(): Boolean;
begin
	if (PrometheusEventData.LastEventType = Event_Key) and (PrometheusEventData.LastEventDetail = Key_Down) then
		IsKeyDown := True
	else
		IsKeyDown := False;
end;

function IsKeyUp(): Boolean;
begin
	if (PrometheusEventData.LastEventType = Event_Key) and (PrometheusEventData.LastEventDetail = Key_Up) then
		IsKeyUp := True
	else
		IsKeyUp := False;
end;

function IsKeyPressed(ID: Int64): Boolean;
begin
	IsKeyPressed := False;
	if (ID < 0) or (ID > 255) then
		Exit;
		
	IsKeyPressed := PrometheusEventData.KeyDown[ID];
end;

function GetKeyUp(): Int64;
begin
	if (PrometheusEventData.LastEventType = Event_Key) and (PrometheusEventData.LastEventDetail = Key_Up) then
		GetKeyUp := PrometheusEventData.LastKeyID
	else
		GetKeyUp := 0;
end;

function GetKeyDown(): Int64;
begin
	if (PrometheusEventData.LastEventType = Event_Key) and (PrometheusEventData.LastEventDetail = Key_Down) then
		GetKeyDown := PrometheusEventData.LastKeyID
	else
		GetKeyDown := 0;
end;

begin
end.
