unit PM_X11Window;

{$Mode ObjFpc}

interface

uses
	Gl,
	Glext,
	GlX,
	X,
	xutil,
	XLib,
	
	PM_Event,
	PM_Debug,
	PM_Utils,
	PM_FrameBuffer;

type
	oX11Window = Object
			Dpy: pDisplay;
			Root: tWindow;
			Attributes: array [0..4] of GLInt;
			Vi: pXVisualInfo;
			Cmap: tColorMap;
			Swa: tXSetWindowAttributes;
			Win: tWindow;
			Glc: tGlxContext;
			Gwa: tXWindowAttributes;
			Xev: tXEvent;
			XNev: tXEvent;
			
			KillAtom: tAtom;
			WMDataAtom: tAtom;
			WMStateAtom: tAtom;
			WMFullScreenAtom: tAtom;
			
			Xce: tXConfigureEvent;
			
			Name: ANSIString;
			WindowWidth, WindowHeight, BitDepth: Int64;
			OriginalWindowWidth, OriginalWindowHeight: Int64;
			FastEventBufferMode: Boolean;
			FullScreen: Boolean;
			
			CoreRenderTarget: RenderTarget;
			
			procedure CreateWindow(X, Y, BPP: Int64);
			procedure Init();
			procedure UpdateCanvas();
			procedure GetEvents();
			procedure ActivateGl();
			procedure ClearCanvas();
			procedure SetWindowName(Dat: ANSIString);
			procedure EnableFastEventBufferMode(Vl: Boolean);
			procedure SetManualKeyRepeat(KRepeat: Boolean);
		end;
	tRealArray1x2 = array [1..2] of Real;
	tInt64Array1x2 = array [1..2] of Int64;

implementation

uses
	PM_Image;

procedure oX11Window.SetManualKeyRepeat(KRepeat: Boolean);
begin
	if KRepeat = True then
		XAutoRepeatOff(Dpy)
	else
		XAutoRepeatOn(Dpy);
end;

{ Legacy code form the R0 test implementation:
procedure oX11Window.ShowFB();
var
	VxR, VyR: tRealArray1x2;
	PxR, PyR: tInt64Array1x2;
	//TempImg: Image;
	
begin
	//UpdateCanvas();
	//writeln('Heres the frame before...');
	//readln();
	
	RenderToScreen();
	//writeln('hit enter to clear');
	//readln();
	//ClearCanvas();
	//UpdateCanvas();
	//writeln('so here we go.... hit enter to draw');
	//readln();
	
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glDisable(GL_DEPTH_TEST);
	glLoadIdentity();

	//glColor4f(Colourization.R / 255, Colourization.G / 255, Colourization.B / 255, Colourization.A / 255);
	glColor4f(255, 255, 255, 255);

	PrometheusImageSystemHandler.BindTexture(DefaultRenderTexture);

	VxR[1] := 0;	VxR[2] := 1;
	VyR[1] := 0;	VyR[2] := 1;
	PxR[1] := 0;	PxR[2] := OriginalWindowWidth;
	PyR[1] := OriginalWindowHeight;	PyR[2] := 0;
	
	glBegin( GL_QUADS );
	glTexCoord2f( VxR[1], VyR[1] );
	glVertex3f( PxR[1], PyR[1], 0. );

	glTexCoord2f( VxR[2], VyR[1] );
	glVertex3f( PxR[2], PyR[1], 0. );

	glTexCoord2f( VxR[2], VyR[2] );
	glVertex3f( PxR[2], PyR[2], 0. );

	glTexCoord2f( VxR[1], VyR[2] );
	glVertex3f( PxR[1], PyR[2], 0. );
    glEnd();
    
    UpdateCanvas();
    //writeln('all done');
   // readln();
    RenderToFB();
end;

procedure oX11Window.RenderToFB();
begin
	glBindFrameBufferEXT(Gl_FrameBuffer_EXT, DefaultFrameBuffer);
	glViewport(0, 0, OriginalWindowWidth, OriginalWindowHeight);
	glOrtho(0, WindowWidth, WindowHeight, 0, -16, 16);
end;

procedure oX11Window.RenderToScreen();
begin
	glBindFrameBufferEXT(Gl_FrameBuffer_EXT, 0);
	glViewport(0, 0, OriginalWindowWidth, OriginalWindowHeight);
	glOrtho(0, WindowWidth, WindowHeight, 0, -16, 16);
end;
}
procedure oX11Window.EnableFastEventBufferMode(Vl: Boolean);
begin
	FastEventBufferMode := Vl;
end;

procedure oX11Window.Init();
begin
	Attributes[0] := GlX_RGBA;
	Attributes[1] := GlX_Depth_Size;
	Attributes[2] := 24;
	Attributes[3] := GlX_DoubleBuffer;
	Attributes[4] := None;
end;

procedure oX11Window.ActivateGl();
begin
	//Some defaults for prometheus to work correctly
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glDisable(GL_DEPTH_TEST);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	//write('PM_X11Window now initializing OpenGL FBO system... ');
	glext_LoadExtension('GL_EXT_framebuffer_object');
	glext_LoadExtension('GL_ARB_framebuffer_object');
	glext_LoadExtension('GL_ARB_shader_objects');
	glext_LoadExtension('ARB_geometry_shader4');
	//writeln(' ok!');
	
	{ //More R0 test code...
	writeln('PM_X11Window now running FBO conversion payload... ');
	writeln('FBO system will use dimension ',OriginalWindowWidth,':',OriginalWindowHeight);
	
	glGenFrameBuffersEXT(1, @DefaultFrameBuffer);
	glBindFrameBufferEXT(Gl_FrameBuffer, DefaultFrameBuffer);
	writeln('FBO Generation PASS');
	
	glGenTextures(1, @DefaultRenderTexture);
	glBindTexture(Gl_Texture_2D, DefaultRenderTexture);
	writeln('TEX Generation PASS');
	
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, OriginalWindowWidth, OriginalWindowHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, Nil);
	glTexParameteri(Gl_Texture_2D, Gl_Texture_Mag_Filter, Gl_Nearest);
	glTexParameteri(Gl_Texture_2D, Gl_Texture_Min_Filter, Gl_Nearest);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, DefaultRenderTexture, 0);
	writeln('TEX Manipulation PASS');
	
	glGenRenderBuffersEXT(1, @DefaultDepthBuffer);
	glBindRenderBufferEXT(Gl_RenderBuffer, DefaultDepthBuffer);
	glRenderBufferStorageEXT(Gl_RenderBuffer, Gl_Depth_Component, OriginalWindowWidth, OriginalWindowHeight);
	glFrameBufferRenderBufferEXT(Gl_FrameBuffer_EXT, Gl_Depth_Attachment_EXT, Gl_RenderBuffer_EXT, DefaultDepthBuffer);
	writeln('DEPTH Generation PASS');

	//some stuff that broke which we didnt need in R0...
	//glFrameBufferTexture2DEXT(Gl_FrameBuffer_EXT, Gl_Color_Attachment, DefaultRenderTexture, );
	
	//glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, depth_rb);

	//writeln('FBO TEX binding PASS');
	//DefaultDrawBuffer[1] := Gl_Color_Attachment0;
	//writeln('Pre-draw PASS');
	//glDrawBuffers(1, DefaultDrawBuffer);

	writeln('FBO System Attach PASS');
	
	writeln('PM_X11Window FBO system initialized ok!');
	RenderToFB();
	}
	
	CoreRenderTarget.Initialize(OriginalWindowWidth, OriginalWindowHeight);
end;

procedure oX11Window.CreateWindow(X, Y, BPP: Int64);
var
	FeedEvent: tXEvent;
	
begin
	dpy := XOpenDisplay(Nil);

	if Dpy = Nil then
		DebugWriteln('Error connecting to X Server');
	
	WindowHeight := Y;
	WindowWidth := X;
	OriginalWindowHeight := Y;
	OriginalWindowWidth := X;
	
	if (BPP <= 0) or (BPP >= Attributes[2]) then
		BPP := Attributes[2] //24 bit is a good default if you you dont want anything specific
	else
		Attributes[2] := BPP;
	
	BitDepth := Attributes[2];

	Root := DefaultRootWindow(Dpy);
	Vi := glXChooseVisual(Dpy, 0, Attributes);

	if Vi = Nil then
		DebugWriteln('No Visual found');
	
	cmap := XCreateColormap(Dpy, Root, Vi^.Visual, AllocNone);

	Swa.ColorMap := Cmap;
	Swa.override_redirect := gl_true;
	Swa.Event_Mask := ExposureMask Or KeyPressMask Or KeyReleaseMask or PointerMotionMask Or ButtonPressMask Or ButtonReleaseMask or StructureNotifyMask;
	
	DebugWrite('WINPREP ');
	Win := XCreateWindow(Dpy, Root, 0, 0, WindowWidth, WindowHeight, 0, Vi^.Depth, InputOutput, Vi^.Visual, CWColormap Or CWEventMask, @Swa);
	DebugWriteln('DONE');
	DebugWrite('MAP ');
	XSelectInput(Dpy, Root, Swa.Event_mask);
	XMapWindow(Dpy, Win);
	DebugWriteln('DONE');
	DebugWrite('STORE');
	XStoreName(Dpy, Win, PChar(Name));
	DebugWriteln(' DONE');
	
	Glc := glXCreateContext(Dpy, Vi, Nil, True);
	DebugWrite('CTXT');
	glXMakeCurrent(Dpy, Win, Glc);
	DebugWriteln(' ACTIVE');
	DebugWriteln('');

	DebugWriteln('Firing up GLSPEC...');
	DebugWrite('MODULES: ');
	
	glEnable( GL_TEXTURE_2D );
 
    glClearColor( 0.0, 0.0, 0.0, 0.0 );
    
    DebugWrite('GLCLCOL, ');
     
    glViewport( 0, 0, WindowWidth, WindowHeight );
     
     DebugWrite('VPORT, ');
     
    glClear( GL_COLOR_BUFFER_BIT );
     
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    
    DebugWrite('MATRIX, ');
    
    //glOrtho(0.0, PrometheusVideo.WindowWidth, PrometheusVideo.WindowHeight, 0.0, -1.0, 1.0);
    glOrtho(0, WindowWidth, WindowHeight, 0, -16, 16);
    
    DebugWrite('ORTHO, ');
    
    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();
    DebugWriteln('IDTY. DONE');
    DebugWriteln('ALL MODULES FOR SOUTHERLAND SYSTEM LOADED OK!');
    
    KillAtom := XInternAtom(Dpy, 'WM_DELETE_WINDOW', 0);
    WMDataAtom := XInternAtom(Dpy, 'WM_PROTOCOLS', False);
    
	XSetWMProtocols(Dpy , Root, @KillAtom, 1);
	
	//enable fullscreen mode if requested
	if FullScreen = True then
		begin
			WMStateAtom := XInternAtom(Dpy, '_NET_WM_STATE', False);
			WMFullScreenAtom := XInternAtom(Dpy, '_NET_WM_STATE_FULLSCREEN', FullScreen);
			with FeedEvent do
				begin
					_Type := ClientMessage;
					XClient.Window := Win;
					XClient.Message_type := WMStateAtom;
					XClient.Format := 32;
					XClient.Data.L[0] := 1;
					XClient.Data.L[1] := WMFullScreenAtom;
					XClient.Data.L[2] := 0;
					XSendEvent(Dpy, DefaultRootWindow(Dpy), False, SubStructureNotifyMask, @FeedEvent);
				end;
		end;
end;

procedure oX11Window.SetWindowName(Dat: ANSIString);
begin
	Name := Dat;
	XStoreName(Dpy, Win, PChar(Name));
end;

procedure oX11Window.UpdateCanvas();
begin
	CoreRenderTarget.Deactivate();
	
	CoreRenderTarget.Draw(0, 0);
	
	glXSwapBuffers(Dpy, Win);
	CoreRenderTarget.Activate();
end;

procedure oX11Window.ClearCanvas();
begin
	CoreRenderTarget.Deactivate();
	glClear(GL_COLOR_BUFFER_BIT);
	CoreRenderTarget.Activate();
end;

procedure oX11Window.GetEvents();
begin
	if XPending(Dpy) > 0 then
		begin
			if (XPending(Dpy) > 1) and (FastEventBufferMode = True) then
				begin
					repeat
						XPeekEvent(Dpy, @XNev);
						if (XNev._Type <> KeyPress) and (XNev._Type <> KeyRelease) then
							XNextEvent(Dpy, @Xev)
						else
							break;
						until XPending(Dpy) <= 1;
				end;
			if XPending(Dpy) <= 0 then
				Exit;
			XNextEvent(Dpy, @Xev);
			if Xev._Type = Expose then
				begin
					XGetWindowAttributes(Dpy, Win, @Gwa);
					
					if (Gwa.Width <> WindowWidth) or (Gwa.Height <> WindowHeight) then
						begin
							WindowWidth := Gwa.Width;
							WindowHeight := Gwa.Height;
							
							glXMakeCurrent(Dpy, win, Glc);
							PrometheusEventData.LastEventType := Event_Window;
							PrometheusEventData.LastEventDetail := Window_Resize;
							
							glViewport(0, 0, WindowWidth, WindowHeight);
							glOrtho(0, WindowWidth, WindowHeight, 0, -16, 16);
					
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
					glXMakeCurrent(Dpy, win, Glc);
					
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
					glXMakeCurrent(Dpy, win, Glc);
					
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
					PrometheusEventData.LastEventType := Event_Mouse;
					PrometheusEventData.LastEventDetail := Mouse_Motion;
					PrometheusEventData.MouseX := trunc((Xev.XMotion.X / WindowWidth) * OriginalWindowWidth);
					PrometheusEventData.MouseY := trunc((Xev.XMotion.Y / WindowHeight) * OriginalWindowHeight);
				end;
			if Xev._Type = ButtonPress then
				begin
					//writeln('BTP');
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
					XGetWindowAttributes(Dpy, Win, @Gwa);
					WindowWidth := Gwa.Width;
					WindowHeight := Gwa.Height;
					glViewport(0, 0, WindowWidth, WindowHeight);
					debugWriteln('VPORT TO ['+IntToStr(WindowWidth)+'.'+IntToStr(WindowHeight)+']');
					glOrtho(0, WindowWidth, WindowHeight, 0, -16, 16);
					glXMakeCurrent(Dpy, win, Glc);
					
					PrometheusEventData.LastEventType := Event_Window;
					PrometheusEventData.LastEventDetail := Window_Resize;
				end;}
		end
	else
		begin
			PrometheusEventData.LastEventType := Event_Idle;
			PrometheusEventData.LastEventDetail := Event_NoEvent;
		end;
end;

begin
end.
