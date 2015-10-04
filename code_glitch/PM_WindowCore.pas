unit PM_WindowCore;

{$Mode ObjFpc}

interface

uses
	PM_FrameBuffer;

type
	PM_WindowGeneric = Class
			protected
				Width, Height: Int64;
				Name: ANSIString;
				Mode_FullScreen: Boolean;
				Initialized: Boolean;
				FastEventBufferMode: Boolean;
				
			
			public
				CoreRenderTarget: RenderTarget;
				ColourDepth: Int64;
				FullScreen: Boolean;
				procedure EnableFastEventBufferMode(Val: Boolean);
				procedure SetManualKeyRepeat(Val: Boolean);
				procedure CreateWindow(NewWidth, NewHeight, NewColourDepth: Int64); Virtual;
				procedure Resize(NewWidth, NewHeight: Int64); Virtual;
				procedure Rename(NewName: ANSIString); Virtual;
				procedure Close(); Virtual;
				procedure SetFullScreen(NewMode: Boolean); Virtual;
				procedure GetEvents(); Virtual;
				function WindowWidth(): Int64; Virtual;
				function WindowHeight(): Int64; Virtual;
		end;

implementation

procedure PM_WindowGeneric.EnableFastEventBufferMode(Val: Boolean);
begin
	FastEventBufferMode := Val;
end;

procedure PM_WindowGeneric.SetManualKeyRepeat(Val: Boolean);
begin
end;

function PM_WindowGeneric.WindowHeight(): Int64;
begin
	WindowHeight := Height;
end;

function PM_WindowGeneric.WindowWidth(): Int64;
begin
	WindowWidth := Width;
end;

procedure PM_WindowGeneric.GetEvents();
begin
end;

procedure PM_WindowGeneric.CreateWindow(NewWidth, NewHeight, NewColourDepth: Int64);
begin
	Initialized := True;
	Width := NewWidth;
	Height := NewHeight;
	ColourDepth := NewColourDepth;
	Name := 'BLANK';
end;

procedure PM_WindowGeneric.Resize(NewWidth, NewHeight: Int64);
begin
end;

procedure PM_WindowGeneric.Rename(NewName: ANSIString);
begin
end;

procedure PM_WindowGeneric.Close();
begin
	Initialized := False;
	Name := '';
	Width := 0;
	Height := 0;
	ColourDepth := 0;
end;

procedure PM_WindowGeneric.SetFullScreen(NewMode: Boolean);
begin
end;

begin
end.
