unit PM_FrameBuffer;

{$Mode ObjFpc}

interface

uses
	Gl,
	Glext,
	PM_Image;

type
	RenderTarget = Object
			private
				Width, Height: Int64;
				Initialized: Boolean;
				Active: Boolean;
				FrameBufferObject: GLUInt;
				RenderTexture: GLUInt;
				DepthBuffer: GLUInt;
				//DrawBuffers: array [0..1] of GLEnum;
			
			public
				procedure Initialize(W, H: Int64);
				procedure Activate();
				procedure Deactivate();
				procedure Empty();			
				procedure Draw(X, Y: Int64);
		end;
	pRenderTarget = ^RenderTarget;
	RenderTargetManager = Object
			ActiveTargets: array of pRenderTarget;
			ActiveFlag: array of Boolean;
			Targets: Int64;
			
			procedure Initialize();
			function Malloc(): Int64;
			procedure Empty();
			procedure RenderToScreen();
			procedure RenderToTargets();
			function TargetIDByHandle(Hnd: pRenderTarget): Int64;
			function ToggleTarget(Hnd: pRenderTarget; Flag: Boolean): Boolean;
			procedure WipeTargets();
			procedure AddTarget(TgT: pRenderTarget);
		end;

//var
//	PM_RenderTargetManager: RenderTargetManager;

procedure ClearRenderTarget();

implementation

uses
	PM_Window;

procedure ClearRenderTarget();
begin
	glClear(GL_COLOR_BUFFER_BIT);
end;

function RenderTargetManager.TargetIDByHandle(Hnd: pRenderTarget): Int64;
var
	c: Int64;

begin
	TargetIDByHandle := 0;
	if Targets <= 0 then
		Exit;
	
	c := 0;
	repeat
		 c += 1;
		 if Hnd = ActiveTargets[c] then
			begin
				TargetIDByHandle := c;
				Exit;
			end;
		 until c >= Targets;
end;

function RenderTargetManager.ToggleTarget(Hnd: pRenderTarget; Flag: Boolean): Boolean;
var
	c: Int64;

begin
	if Targets <= 0 then
		Exit;
	c := TargetIDByHandle(Hnd);
	ActiveFlag[c] := Flag;
	if Flag = True then
		ActiveTargets[c]^.Activate()
	else
		ActiveTargets[c]^.Deactivate();
	ToggleTarget := Flag;
end;

procedure RenderTargetManager.WipeTargets();
var
	c: Int64;

begin
	if Targets > 0 then
		begin
			c := 0;
			repeat
				c += 1;
				ActiveTargets[c]^.Deactivate();
				ActiveFlag[c] := False;
				until c >= Targets;
		end;
	Targets := 0;
end;

procedure RenderTargetManager.RenderToTargets();
var
	c: Int64;

begin
	if Targets > 0 then
		begin
			c := 0;
			repeat
				c += 1;
				if ActiveFlag[c] = True then
					ActiveTargets[c]^.Activate();
				until c >= Targets;
		end;
end;

procedure RenderTargetManager.RenderToScreen();
var
	c: Int64;

begin
	if Targets > 0 then
		begin
			c := 0;
			repeat
				c += 1;
				if ActiveFlag[c] = True then
					ActiveTargets[c]^.Deactivate();
				until c >= Targets;
		end;
end;

function RenderTargetManager.Malloc(): Int64;
begin
	if Targets <= 0 then
		Targets := 0;
	
	Targets += 1;
	SetLength(ActiveTargets, Targets + 1);
	SetLength(ActiveFlag, Targets + 1);
	Malloc := Targets;
end;

procedure RenderTargetManager.AddTarget(TgT: pRenderTarget);
var
	c: Int64;
	
begin
	if TargetIDByHandle(TgT) <= 0 then
		Exit;
	c := Malloc();
	ActiveTargets[c] := Tgt;
	ActiveFlag[c] := True;
end;

procedure RenderTargetManager.Empty();
begin
	SetLength(ActiveTargets, 1);
	SetLength(ActiveFlag, 1);
	Targets := 0;
end;

procedure RenderTargetManager.Initialize();
begin
	SetLength(ActiveTargets, 1);
	SetLength(ActiveFlag, 1);
	Targets := 0;
end;

procedure RenderTarget.Draw(X, Y: Int64);
var
	VxR, VyR: tRealArray1x2;
	PxR, PyR: tInt64Array1x2;
	
begin
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glDisable(GL_DEPTH_TEST);
	glLoadIdentity();

	//glColor4f(Colourization.R / 255, Colourization.G / 255, Colourization.B / 255, Colourization.A / 255);
	glColor4f(255, 255, 255, 255);

	PrometheusImageSystemHandler.BindTexture(RenderTexture);

	VxR[1] := 0;	VxR[2] := 1;
	VyR[1] := 0;	VyR[2] := 1;
	PxR[1] := X;	PxR[2] := Width;
	PyR[1] := Height;	PyR[2] := Y;
	
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
end;

procedure RenderTarget.Empty();
begin
	if Initialized = False then
		Exit;
		
	if Active = True then
		Deactivate();
		
	Width := 0;
	Height := 0;
	glDeleteFrameBuffersEXT(1, @FrameBufferObject);
	glDeleteTextures(1, @RenderTexture);
	glDeleteRenderBuffersEXT(1, @DepthBuffer);
	Initialized := False;
end;

procedure RenderTarget.DeActivate();
begin
	glBindFrameBufferEXT(Gl_FrameBuffer_EXT, 0);
	glViewport(0, 0, GetWindowWidth(), GetWindowHeight());
	glOrtho(0, GetWindowWidth(), GetWindowHeight(), 0, -16, 16);
	
	glLoadIdentity();
	glPopMatrix();
	Active := False;
	
	{
	//writeln('Deactived call, reactivating FBO: ',ParentFBO);
	if ParentFBO <> 0 then //if we unbound an FBO beforem rebind it...
		begin
			glBindFrameBufferEXT(Gl_FrameBuffer_EXT, ParentFBO);
			glViewport(0, 0, GetWindowWidth(), GetWindowHeight());
			glOrtho(0, GetWindowWidth(), GetWindowHeight(), 0, -16, 16);
			ParentFBO := 0;
		end;
	}
end;

procedure RenderTarget.Activate();
begin
	{
	glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, @ParentFBO);
	//writeln('Got parent FBO ID:',ParentFBO);
	if ParentFBO <> 0 then
		begin
			Deactivate();
		end;
	}
	glBindFrameBufferEXT(Gl_FrameBuffer_EXT, 0);
	glBindFrameBufferEXT(Gl_FrameBuffer_EXT, FrameBufferObject);
	glViewport(0, 0, Width, Height);
	glOrtho(0, Width, Height, 0, -16, 16);
	Active := True;
	glLoadIdentity();
	glPopMatrix();
end;

procedure RenderTarget.Initialize(W, H: Int64);
var
	Status: GLEnum;
	
begin
	if Initialized = True then
		Empty();
		
	Width := W;
	Height := H;	
	
	glGenTextures(1, @RenderTexture);
	glBindTexture(Gl_Texture_2D, RenderTexture);
	
	glTexParameteri(Gl_Texture_2D, Gl_Texture_Mag_Filter, Gl_Linear);
	glTexParameteri(Gl_Texture_2D, Gl_Texture_Min_Filter, Gl_Linear);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, Width, Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, Nil);
	
	glGenFrameBuffersEXT(1, @FrameBufferObject);
	glBindFrameBufferEXT(Gl_FrameBuffer, FrameBufferObject);
	
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, RenderTexture, 0);
	
	glGenRenderBuffersEXT(1, @DepthBuffer);
	glBindRenderBufferEXT(Gl_RenderBuffer, DepthBuffer);
	glRenderBufferStorageEXT(Gl_RenderBuffer, Gl_Depth_Component, Width, Height);
	glFrameBufferRenderBufferEXT(Gl_FrameBuffer_EXT, Gl_Depth_Attachment_EXT, Gl_RenderBuffer_EXT, DepthBuffer);
	
	Status := glCheckFrameBufferStatusEXT(GL_FRAMEBUFFER_EXT);
	//if Status = GL_FRAMEBUFFER_COMPLETE_EXT then
	//	writeln('FBO OK!');
	
	//Activate();
	//PM_RenderTargetManager.AddTarget(@Self);
	Initialized := True;
	//writeln('New FBO ',Width,'x',Height);
end;

begin
end.
