unit PM_GenericWindow;

{$Mode ObjFpc}

interface

uses
	PM_Event,
	PM_Debug,
	PM_Utils,
	
	Gl,
	Sdl;

type
	oGenericWindow = Object
			Canvas: pSdl_Surface;
			Width, Height: Int64;
			BitDepth: Int64;
			WindowName: ANSIString;
			SdlEvent: pSdl_Event;
			
			procedure Initialize();
			procedure UpdateCanvas();
			procedure ClearCanvas();
			procedure CreateWindow(X, Y, BPP: Int64);
			procedure GetEvents();
			procedure UpdateWindow();
			procedure SetWindowName(Nme: ANSIString);
		end;

implementation

procedure oGenericWindow.UpdateCanvas();
begin
	Sdl_Gl_SwapBuffers();
end;

procedure oGenericWindow.UpdateWindow();
begin
	Sdl_FreeSurface(Canvas);
	Canvas := SDL_SetVideoMode(Width, Height, BitDepth, Sdl_OpenGl);

	glEnable( GL_TEXTURE_2D );

	glClearColor( 0.0, 0.0, 0.0, 0.0 );

	glViewport( 0, 0, Width, Height );

	glClear( GL_COLOR_BUFFER_BIT );

	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();

	//glOrtho(0.0, PrometheusVideo.WindowWidth, PrometheusVideo.WindowHeight, 0.0, -1.0, 1.0);
	glOrtho(0, Width, Height, 0, -16, 16);

	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
	SDL_GL_SwapBuffers();
end;

procedure oGenericWindow.Initialize();
begin
	SDL_Init(SDL_INIT_EVERYTHING);
	New(SdlEvent);
end;

procedure oGenericWindow.ClearCanvas();
begin
	glClear(GL_COLOR_BUFFER_BIT);
end;

procedure oGenericWindow.CreateWindow(X, Y, BPP: Int64);
begin
	Width := X;
	Height := Y;
	BitDepth := BPP;
	
	SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 ); 
     
    Canvas := SDL_SetVideoMode(Width, Height, BitDepth, Sdl_OpenGl);
    
    glEnable( GL_TEXTURE_2D );
 
    glClearColor( 0.0, 0.0, 0.0, 0.0 );
     
    glViewport( 0, 0, Width, Height );
     
    glClear( GL_COLOR_BUFFER_BIT );
     
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    
    //aim: glOrtho(0, 1280, 720, 0, -16, 16); 
    glOrtho(0.0, Width, Height, 0.0, -16, 16);
	    
    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();
    
    glEnable (GL_BLEND); 
    glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
end;

procedure oGenericWindow.SetWindowName(Nme: ANSIString);
begin
	
end;

procedure oGenericWindow.GetEvents();
begin
	if Sdl_PollEvent(SdlEvent) <> 0 then
		begin
			case SdlEvent^.type_ of 
					Sdl_QuitEv:
						begin
							PrometheusEventData.LastEventType := Event_Window;
							PrometheusEventData.LastEventDetail := Window_Close;

						end;
					Sdl_VideoResize:
						begin
							PrometheusEventData.LastEventType := Event_Window;
							PrometheusEventData.LastEventDetail := Window_Resize;
							{PromCore.PromEvent.Type_ := 'SYSTEM';
							PromCore.PromEvent.StrVal := 'RESIZE';
							PromCore.PromEvent.StrVal2 := '';
							PromCore.PromEvent.IntVal := PromCore.SdlEvent.Resize.W;
							PromCore.PromEvent.IntVal2 := promCore.SdlEvent.Resize.H;}
						end;
					Sdl_KeyDown:
						begin
							PrometheusEventData.LastEventType := Event_Key;
							PrometheusEventData.LastEventDetail := Key_Down;
							PrometheusEventData.LastKeyID := ord(chr(SdlEvent^.Key.KeySym.Sym));
							if (PrometheusEventData.LastKeyID <= 255) and (PrometheusEventData.LastKeyID >= 0) then
								PrometheusEventData.KeyDown[PrometheusEventData.LastKeyID] := True;
							{PromCore.PromEvent.Type_ := 'KEY';
							PromCore.PromEvent.StrVal := 'DOWN';
							PromCore.PromEvent.StrVal2 := chr(PromCore.SdlEvent^.Key.KeySym.Sym);
							PromCore.PromEvent.IntVal := PromCore.SdlEvent^.Key.KeySym.Sym;
							PromCore.PromEvent.IntVal2 := 0;}
						end;
					Sdl_Keyup:
						begin
							PrometheusEventData.LastEventType := Event_Key;
							PrometheusEventData.LastEventDetail := Key_Up;
							PrometheusEventData.LastKeyID := ord(chr(SdlEvent^.Key.KeySym.Sym));
							if (PrometheusEventData.LastKeyID <= 255) and (PrometheusEventData.LastKeyID >= 0) then
								PrometheusEventData.KeyDown[PrometheusEventData.LastKeyID] := False;
							{PromCore.PromEvent.Type_ := 'KEY';
							PromCore.PromEvent.StrVal := 'UP';
							PromCore.PromEvent.StrVal2 := chr(PromCore.SdlEvent^.Key.KeySym.Unicode);
							PromCore.PromEvent.IntVal := PromCore.SdlEvent^.Key.KeySym.Unicode;
							PromCore.PromEvent.IntVal2 := 0;}
						end;
					Sdl_SysWmEvent:
						begin
							{PromCore.PromEvent.Type_ := 'SYSTEM';
							PromCore.PromEvent.StrVal := 'WM';
							PromCore.PromEvent.StrVal2 := '';
							PromCore.PromEvent.IntVal := 0;
							PromCore.PromEvent.IntVal2 := 0;}
						end;
					Sdl_NoEvent:
						begin
							{PromCore.PromEvent.Type_ := 'IDLE';
							PromCore.PromEvent.StrVal := 'NOEVENT';
							PromCore.PromEvent.StrVal2 := '';
							PromCore.PromEvent.IntVal := 0;
							PromCore.PromEvent.IntVal2 := 0;}
						end;
					Sdl_MouseMotion:
						begin
							{PromCore.PromEvent.Type_ := 'MOUSE';
							PromCore.PromEvent.StrVal := 'POSITION';
							PromCore.PromEvent.StrVal2 := '';
							PromCore.PromEvent.IntVal := PromCore.SdlEvent^.Motion.X;
							PromCore.PromEvent.IntVal2 := PromCore.SdlEvent^.Motion.Y;}
						end;
					Sdl_MouseButtonDown:
						begin
							{PromCore.PromEvent.Type_ := 'MOUSE';
							PromCore.PromEvent.StrVal := 'DOWN';
							if PromCore.SdlEvent^.Button.State = 1 then
								begin
									if PromCore.SdlEvent^.Button.Button = 1 then
										begin
											PromCore.PromEvent.StrVal2 := 'LEFT';
										end
									else if PromCore.SdlEvent^.Button.Button = 3 then
										begin
											PromCore.PromEvent.StrVal2 := 'RIGHT';
										end;
								end;}
						end;
					Sdl_MouseButtonUp:
						begin
							{PromCore.PromEvent.Type_ := 'MOUSE';
							PromCore.PromEvent.StrVal := 'UP';
							if PromCore.SdlEvent^.Button.State = 1 then
								begin
									if PromCore.SdlEvent^.Button.Button = 1 then
										begin
											PromCore.PromEvent.StrVal2 := 'LEFT';
										end
									else if PromCore.SdlEvent^.Button.Button = 3 then
										begin
											PromCore.PromEvent.StrVal2 := 'RIGHT';
										end;
								end;}
						end;
					Sdl_ActiveEvent:
						begin
						end;
				end;
		end;
end;

begin
end.
