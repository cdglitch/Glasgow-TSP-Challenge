{
	* This code, circa 2014, is designed to be an improvement over the unstable atrocious PM_X11Window type used to date.
	* It is based on the excellent example given over at http://content.gpwiki.org/index.php/OpenGL:Tutorials:Setting_up_OpenGL_on_X11
}
unit PM_WindowCore_X11;

{$Mode ObjFpc}

interface

uses
	Gl,
	Glx,
	Glext,
	X,
	XLib,
	XUtil,
	XF86VMode,
	
	PM_WindowCore,
	PM_Event;

type
	PM_X11Window_Container = Object
			X11Display: pDisplay;
			X11ScreenID: Integer;
			X11Window: TWindow;
			GLXContext: GlXContext;
			X11WindowAttributes: TXSetWindowAttributes;
			X11WindowCurrentAttributes: TXWindowAttributes;
			Fullscreen: Boolean;
			DoubleBuffered: Boolean;
			VideoModes: TXF86VidModeModeInfo;
			Width, Height, X, Y: Int64;
		end;
	PM_X11Window = Class(PM_WindowGeneric)
			private
				GLWindow: PM_X11Window_Container;
				Window: PM_X11Window_Container;
				AttributesList_SBL, AttributesList_DBL: array [0..16] of Integer;
				Xev: tXEvent;
				//XNev: tXEvent;
				Xce: tXConfigureEvent;
				OriginalWindowWidth, OriginalWindowHeight: Int64;
				
				procedure GenerateAttributes_SingleBufferMode();
				procedure GenerateAttributes_DoubleBufferMode();
				procedure InitializeOpenGL();
				procedure InitializeWindow();
				procedure GetEvents_Core();
			
			public
				procedure CreateWindow(X, Y, BPP: Int64); Override;
				procedure ClearCanvas();
				procedure UpdateCanvas();
				procedure GetEvents(); Override;
		end;
	
implementation

procedure PM_X11Window.GenerateAttributes_SingleBufferMode();
begin
	AttributesList_SBL[0] := Glx_RGBA;
	AttributesList_SBL[1] := Glx_Red_Size;
	AttributesList_SBL[2] := 4;
	AttributesList_SBL[3] := Glx_Green_Size;
	AttributesList_SBL[4] := 4;
	AttributesList_SBL[5] := Glx_Blue_Size;
	AttributesList_SBL[6] := 4;
	AttributesList_SBL[7] := Glx_Depth_Size;
	AttributesList_SBL[8] := 16;
	AttributesList_SBL[9] := None;
end;

procedure PM_X11Window.GenerateAttributes_DoubleBufferMode();
begin
	AttributesList_DBL[0] := Glx_RGBA;
	AttributesList_DBL[1] := Glx_DoubleBuffer;
	AttributesList_DBL[2] := Glx_Red_Size;
	AttributesList_DBL[3] := 4;
	AttributesList_DBL[4] := Glx_Green_Size;
	AttributesList_DBL[5] := 4;
	AttributesList_DBL[6] := Glx_Blue_Size;
	AttributesList_DBL[7] := 4;
	AttributesList_DBL[8] := Glx_Depth_Size;
	AttributesList_DBL[9] := 16;
	AttributesList_DBL[10] := None;
end;

procedure PM_X11Window.InitializeWindow();
var
	VisualInfo: pXVisualInfo;
	ColourMap: TColorMap;
	DisplayWidth, DisplayHeight: Int64;
	Version_GlxMaj, Version_GlxMin: Integer;
	Version_VMMaj, Version_VMMin: Integer;
	ModeList: ppXF86VidModeModeInfo;
	VideoModeNumber, BestVideoMode: Int64;
	Atom_WmDelete: TAtom;
	DummyWindow: TWindow;
	DummyBorder: LongWord;
	c: Int64;
	
begin
	BestVideoMode := 0;
	
	Window.X11Display := XOpenDisplay('');
	Window.X11ScreenID := DefaultScreen(Window.X11Display);
	XF86VidModeQueryVersion(Window.X11Display, @Version_VMMaj, @Version_VMMin);
	XF86VidModeGetAllModeLines(Window.X11Display, Window.X11ScreenID, @VideoModeNumber, @ModeList);
	
	GLWindow.VideoModes := ModeList^[0];
	Window.VideoModes := ModeList^[0];
	
	c := 0;
	repeat
		if (ModeList[c]^.hDisplay = Width) and (ModeList[c]^.vDisplay = Height) then
				BestVideoMode := c;
		c += 1;
		until c >= VideoModeNumber;
	
	GenerateAttributes_DoubleBufferMode();
	VisualInfo := GlxChooseVisual(Window.X11Display, Window.X11ScreenID, AttributesList_DBL);
	if VisualInfo = Nil then
		begin
			//This means there is no double buffering available...
			//So try again for single buffered mode...
			GenerateAttributes_SingleBufferMode();
			VisualInfo := GlxChooseVisual(Window.X11Display, Window.X11ScreenID, AttributesList_SBL);
			Window.DoubleBuffered := False;
		end
	else
		Window.DoubleBuffered := True;
	
	//GlxQueryVersion(Window.X11Display, @Version_GlxMaj, @Version_GlxMin); //This screws up for no reason...
	
	Window.GLXContext := GlxCreateContext(Window.X11Display, VisualInfo, Nil, True);
	ColourMap := XCreateColorMap(Window.X11Display, RootWindow(Window.X11Display, VisualInfo^.Screen), VisualInfo^.Visual, AllocNone);
	Window.X11WindowAttributes.ColorMap := ColourMap;
	Window.X11WindowAttributes.Border_Pixel := 0;
	
	if Mode_FullScreen = True then
		begin
			Window.FullScreen := True;
			
			XF86VidModeSwitchToMode(Window.X11Display, Window.X11ScreenID, ModeList[BestVideoMode]);
			XF86VidModeSetViewPort(Window.X11Display, Window.X11ScreenID, 0, 0);
			
			DisplayWidth := ModeList[BestVideoMode]^.hDisplay;
			DisplayHeight := ModeList[BestVideoMode]^.vDisplay;
			
			XFree(ModeList);
			
			Window.X11WindowAttributes.Override_Redirect := 1; //Assuming 1 = true
			Window.X11WindowAttributes.Event_Mask := ExposureMask Or KeyPressMask Or KeyReleaseMask or PointerMotionMask Or ButtonPressMask Or ButtonReleaseMask or StructureNotifyMask or ButtonMotionMask;
			Window.X11Window := XCreateWindow(Window.X11Display, RootWindow(Window.X11Display, VisualInfo^.Screen), 0, 0, DisplayWidth, DisplayHeight, 0, VisualInfo^.Depth, InputOutput, VisualInfo^.Visual, CWBorderPixel Or CWColorMap Or CWEventMask Or CWOverrideRedirect, @Window.X11WindowAttributes);
			XWarpPointer(Window.X11Display, None, Window.X11Window, 0, 0, 0, 0, 0, 0);
			XGrabKeyboard(Window.X11Display, Window.X11Window, True, GrabModeASync, GrabModeASync, CurrentTime);
		end
	else
		begin
			Window.X11WindowAttributes.Event_Mask := ExposureMask Or KeyPressMask Or KeyReleaseMask or PointerMotionMask Or ButtonPressMask Or ButtonReleaseMask or StructureNotifyMask or ButtonMotionMask;
			Window.X11Window := XCreateWindow(Window.X11Display, RootWindow(Window.X11Display, VisualInfo^.Screen), 0, 0, Width, Height, 0, VisualInfo^.Depth, InputOutput, VisualInfo^.Visual, CWBorderPixel Or CWColorMap Or CWEventMask Or CWOverrideRedirect, @Window.X11WindowAttributes);
			
			Atom_WmDelete := XInternAtom(Window.X11Display, 'WM_DELETE_WINDOW', True);
			XSetWMProtocols(Window.X11Display, Window.X11Window, @Atom_WmDelete, 1);
			XSetStandardProperties(Window.X11Display, Window.X11Window, PChar(Name), PChar(Name), None, Nil, 0, Nil);
			XMapRaised(Window.X11Display, Window.X11Window);
		end;
	
	glxMakeCurrent(Window.X11Display, Window.X11Window, Window.GlXContext);
end;

procedure PM_X11Window.InitializeOpenGL();
begin
	//Load up some extensions...
	glext_LoadExtension('GL_EXT_framebuffer_object');
	//glext_LoadExtension('GL_ARB_framebuffer_object');
	glext_LoadExtension('GL_EXT_shader_objects');
	//glext_LoadExtension('ARB_geometry_shader4');
	
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glDisable(GL_DEPTH_TEST);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);	
	
	glClearColor( 0.0, 0.0, 0.0, 0.0 );     
    glViewport( 0, 0, Width, Height );    
    glClear( GL_COLOR_BUFFER_BIT );
     
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    
    //glOrtho(0.0, PrometheusVideo.Width, PrometheusVideo.Height, 0.0, -1.0, 1.0);
    glOrtho(0, Width, Height, 0, -1000, 1000);
    
    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();
    
    CoreRenderTarget.Initialize(Width, Height);
	CoreRenderTarget.Activate();
end;

procedure PM_X11Window.ClearCanvas();
begin
	CoreRenderTarget.Deactivate();
	glClear(GL_COLOR_BUFFER_BIT);
	CoreRenderTarget.Activate();
	glClear(GL_COLOR_BUFFER_BIT);
end;

procedure PM_X11Window.UpdateCanvas();
begin
	CoreRenderTarget.Deactivate();
	
	CoreRenderTarget.Draw(0, 0);
	
	glXSwapBuffers(Window.X11Display, Window.X11Window);
	CoreRenderTarget.Activate();
end;

procedure PM_X11Window.CreateWindow(X, Y, BPP: Int64);
begin
	Inherited;
	InitializeWindow();
	InitializeOpenGL();
end;

procedure PM_X11Window.GetEvents();
begin
	if XPending(Window.X11Display) > 0 then
		begin
			if FastEventBufferMode = True then
				begin
					repeat
						GetEvents_Core();
						until XPending(Window.X11Display) <= 0;
				end
			else
				GetEvents_Core();
		end
	else
		begin
			PrometheusEventData.LastEventType := Event_Idle;
			PrometheusEventData.LastEventDetail := Event_NoEvent;
		end;
end;

procedure PM_X11Window.GetEvents_Core();
begin
	if XPending(Window.X11Display) <= 0 then
		Exit;
	XNextEvent(Window.X11Display, @Xev);
	if Xev._Type = Expose then
		begin
			XGetWindowAttributes(Window.X11Display, Window.X11Window, @Window.X11WindowCurrentAttributes);
			
			if (Window.X11WindowCurrentAttributes.Width <> Width) or (Window.X11WindowCurrentAttributes.Height <> Height) then
				begin
					Width := Window.X11WindowCurrentAttributes.Width;
					Height := Window.X11WindowCurrentAttributes.Height;
					
					glXMakeCurrent(Window.X11Display, Window.X11Window, Window.GLXContext);
					PrometheusEventData.LastEventType := Event_Window;
					PrometheusEventData.LastEventDetail := Window_Resize;
					
					glViewport(0, 0, Width, Height);
					glOrtho(0, Width, Height, 0, -16, 16);
			
					ClearCanvas();
				end
			else
				begin
					PrometheusEventData.LastEventType := Event_Focus;
					PrometheusEventData.LastEventDetail	:= Focus_Gained;
				end;
			
		end;
	if Xev._Type = ConfigureNotify then
		begin
			Xce := Xev.XConfigure;
		end;
	if Xev._Type = KeyPress then
		begin
			glXMakeCurrent(Window.X11Display, Window.X11Window, Window.GLXContext);
			
			PrometheusEventData.LastEventType := Event_Key;
			PrometheusEventData.LastEventDetail := Key_Down;
			PrometheusEventData.LastKeyID := XLookupKeysym(@Xev.xkey, 0);
			if PrometheusEventData.LastKeyID > 65280 then
				PrometheusEventData.LastKeyID := PrometheusEventData.LastKeyID - 65280;
			if (PrometheusEventData.LastKeyID <= 255) and (PrometheusEventData.LastKeyID >= 0) then
				PrometheusEventData.KeyDown[PrometheusEventData.LastKeyID] := True;
		end;
	if Xev._Type = KeyRelease then
		begin
			glXMakeCurrent(Window.X11Display, Window.X11Window, Window.GLXContext);
			
			PrometheusEventData.LastEventType := Event_Key;
			PrometheusEventData.LastEventDetail := Key_Up;
			PrometheusEventData.LastKeyID := XLookupKeysym(@Xev.xkey, 0);
			if PrometheusEventData.LastKeyID > 65280 then
				PrometheusEventData.LastKeyID := PrometheusEventData.LastKeyID - 65280;
			if (PrometheusEventData.LastKeyID <= 255) and (PrometheusEventData.LastKeyID >= 0) then
				PrometheusEventData.KeyDown[PrometheusEventData.LastKeyID] := False;
		end;
	if Xev._Type = MotionNotify then
		begin
			//The co-ordinates do not compensate for window resizing!!! This needs an update...
			PrometheusEventData.LastEventType := Event_Mouse;
			PrometheusEventData.LastEventDetail := Mouse_Motion;
			PrometheusEventData.MouseX := trunc(Xev.XMotion.X);
			PrometheusEventData.MouseY := trunc(Xev.XMotion.Y);
		end;
	if Xev._Type = ButtonPress then
		begin
			writeln('Mouepress at ',GetMouseX(),' , ',GetMouseY());
			PrometheusEventData.LastEventType := Event_Mouse;
			if Xev.XButton.Button = 1 then
				begin
					//writeln('LMD!');
					PrometheusEventData.LastEventDetail := MouseButton_LeftDown;
				end;
			if Xev.XButton.Button = 2 then
				begin
					PrometheusEventData.LastEventDetail := MouseButton_MiddleDown;
					//writeln('MMD');
				end;
			if Xev.XButton.Button = 3 then
				begin
					//writeln('RMD');
					PrometheusEventData.LastEventDetail := MouseButton_RightDown;
				end;
		end;
	//if (Xev.XDestroyWindow.Window = Root) and (Xev.XClient.Message_type = KillAtom) then
	//	writeln('T ',Xev.Xclient.data.l[2]);
	if Xev._Type = ButtonRelease then
		begin
			PrometheusEventData.LastEventType := Event_Mouse;
			if Xev.XButton.Button = 1 then
				begin
					PrometheusEventData.LastEventDetail := MouseButton_LeftUp;
				end;
			if Xev.XButton.Button = 2 then
				begin
					PrometheusEventData.LastEventDetail := MouseButton_MiddleUp;
				end;
			if Xev.XButton.Button = 3 then
				begin
					PrometheusEventData.LastEventDetail := MouseButton_RightUp;
				end;
		end;
	//if Xev._Type = 
	{if Xev._Type = ResizeRequest then
		begin	
			XGetWindowAttributes(Window.X11Display, GwaWindow.X11Window, @Window.X11WindowAttributes);
			Width := Window.X11WindowAttributes.Width;
			Height := Window.X11WindowAttributes.Height;
			glViewport(0, 0, Width, Height);
			debugWriteln('VPORT TO ['+IntToStr(Width)+'.'+IntToStr(Height)+']');
			glOrtho(0, Width, Height, 0, -16, 16);
			glXMakeCurrent(Window.X11Display, win, Window.GLXContext);
			
			PrometheusEventData.LastEventType := Event_Window;
			PrometheusEventData.LastEventDetail := Window_Resize;
		end;}
end;

begin
end.
