//Custom PM_Image unit with software RenderToImage() implementation for extension of axis_gl;
unit PM_Image;

interface

uses
	uTGASupport,
	uPNGSupport,
	
	Gl,
	
	PM_Utils,
	PM_Colour,
	PM_TextUtils,
	PM_Debug;

type
	tRealArray1x2 = array [1..2] of Real;
	tInt64Array1x2 = array [1..2] of Int64;
	pImage = ^Image;
	Image = Object
			TextureData: GLUint;
			XScale, YScale: Real;
			Width, Height: Int64;
			Rotation: Real;
			Colourization: Colour;
			
			procedure Draw(X, Y: Int64);
			procedure DrawRotated(X,Y: Int64; Deg: Real);
			procedure DrawSelection(sX, sY, sW, sH, dX, dY: Int64);
			procedure Rotate(Deg: Int64);
			procedure Load(Src: ANSIString);
			procedure Resize(X, Y: Int64);
			procedure Empty();
			procedure SetMemSize(X, Y: Int64);
			procedure RenderToImage(X, Y: Int64; Dest: pImage);
			
			function GetWidth(): Int64;
			function GetHeight(): Int64;

				procedure LoadFromTGA(Src: ANSIString);
				procedure LoadFromPNG(Src: ANSIString);
				procedure LoadFromBMP(Src: ANSIString);
				procedure LoadFromTexture(Src: pGLUInt; W, H: Int64);
			
				//procedure RenderQuad(TextureArrayX: tRealArray1x2; TextureArrayY: tRealArray1x2; ScreenArrayX: tInt64Array1x2; ScreenArrayY: tInt64Array1x2);
				procedure RenderQuad(VxR, VyR: tRealArray1x2; PxR, PyR: tInt64Array1x2);

			procedure InitReg();
		end;
	oPrometheusImageSystemHandler = object
			BoundTexture: GLUint;
			procedure BindTexture(Tex: GLUint);
		end;

var
	PrometheusImageSystemHandler: oPrometheusImageSystemHandler;

implementation

uses
	PM_Cleanup;

procedure Image.LoadFromTexture(Src: pGLUInt; W, H: Int64);
begin
	Empty(); //prep everything for load
	
	glGetTexLevelParameteriv(Gl_Texture_2D, 0, Gl_Texture_Width, @Width);
	glGetTexLevelParameteriv(Gl_Texture_2D, 0, Gl_Texture_Height, @Height);
	//writeln('Texin X:Y   ',Width,':',Height);
	
	glShadeModel(GL_SMOOTH);
	glGenTextures(1, @TextureData);
	//glBindTexture(GL_TEXTURE_2D, TextureData);
	PrometheusImageSystemHandler.BindTexture(TextureData);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, Width, Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, Src);
	
	Rotation := 0;
	XScale := 1;
	YScale := 1;
	Colourization.SetRGBA(255, 255, 255, 255);
end;

procedure Image.InitReg();
begin
	PrometheusImageRegistry.RegisterImagePTR(@Self);
end;

procedure Image.SetMemSize(X, Y: Int64);
var
	TData: Pointer;
	
begin
	Empty();
	
	GetMem(TData, X * Y * GL_RGBA);
	glGenTextures(1, @TextureData);
	glBindTexture(Gl_Texture_2D, TextureData);
	glTexImage2D(Gl_Texture_2D, 0, GL_RGBA, X, Y, 0, GL_RGBA, GL_UNSIGNED_BYTE, TData);
	glTexParameteri(Gl_Texture_2D, Gl_Texture_Mag_Filter, Gl_Linear);
	glTexParameteri(Gl_Texture_2D, Gl_Texture_Min_Filter, Gl_Linear);
	Width := X;
	Height := Y;
	Rotation := 0;
	Colourization := QuickColour(255, 255, 255, 255);
	XScale := 1;
	YScale := 1;
	FreeMem(TData);
end;

procedure Image.RenderToImage(X, Y: Int64; Dest: pImage);
begin
end;

function Image.GetWidth(): Int64;
begin
	GetWidth := Round(Width * XScale);
end;

function Image.GetHeight(): Int64;
begin
	GetHeight := Round(Height * YScale);
end;

procedure oPrometheusImageSystemHandler.BindTexture(Tex: GLUint);
var
	RAM: Int64;
	
begin
	glGetIntegerv(Gl_Texture_Binding_2D, @RAM);
	if RAM <> Tex then
		glBindTexture(Gl_Texture_2D, Tex);
end;

procedure Image.Resize(X, Y: Int64);
begin
	if GetWidth <> X then
		XScale := X / Width;
	
	if GetHeight <> Y then
		YScale := Y / Height;
end;

procedure Image.Empty();
begin
	Rotation := 0;
	XScale := 0;
	YScale := 0;
	Width := 0;
	Height := 0;
	glDeleteTextures(1, @TextureData);
	Colourization.SetRGBA(0, 0, 0, 0);
end;

procedure Image.LoadFromBMP(Src: ANSIString);
begin
end;

procedure Image.DrawRotated(X,Y: Int64; Deg: Real);
var
    tX, tY: LongInt;
	
    VxR: tRealArray1x2;
    VyR: tRealArray1x2;
    
    PxR: tInt64Array1x2;
    PyR: tInt64Array1x2;
	
begin	
	tX := Width div 2;
	tY := Height div 2;

	//glBindTexture(GL_TEXTURE_2D, TextureData);
	PrometheusImageSystemHandler.BindTexture(TextureData);
	
	glPushMatrix();  // Save modelview matrix

	glTranslatef(X, Y, 0.0);  // Position sprite
	
	if Deg <> 0 then
		glRotatef(Deg, 0, 0, 1);

	VxR[1] := 0;
	VxR[2] := 1;
	VyR[1] := 1;
	VyR[2] := 0;

	PxR[1] := trunc(-tX * XScale);
	PxR[2] := trunc(tX * XScale);
	PyR[1] := trunc(tY * YScale);
	PyR[2] := trunc(-tY * YScale);

	glColor4f(Colourization.R / 255, Colourization.G / 255, Colourization.B / 255, Colourization.A / 255);
	RenderQuad(VxR, VyR, PxR, PyR);

	glPopMatrix();
	Rotation := Deg;
end;

{

procedure Image.RenderQuad(TextureArrayX: tRealArray1x2; TextureArrayY: tRealArray1x2; ScreenArrayX: tInt64Array1x2; ScreenArrayY: tInt64Array1x2);
begin		
	//glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
	glBegin(GL_QUADS);
		glTexCoord2f(TextureArrayX[2], TextureArrayY[1]);
		glVertex3f(ScreenArrayX[2], ScreenArrayY[1], 0);
		writeln('TX [',TextureArrayX[2], '.', TextureArrayY[1],'] SX [',ScreenArrayX[2],'.',ScreenArrayY[1],']');
		
		glTexCoord2f(TextureArrayX[1], TextureArrayY[1]);
		glVertex3f(ScreenArrayX[1], ScreenArrayY[1], 0);
		writeln('TX [',TextureArrayX[1], '.', TextureArrayY[1],'] SX [',ScreenArrayX[1],'.',ScreenArrayY[1],']');
		
		glTexCoord2f(TextureArrayX[2], TextureArrayY[2]);
		glVertex3f(ScreenArrayX[2], ScreenArrayY[2], 0);
		writeln('TX [',TextureArrayX[2], '.', TextureArrayY[2],'] SX [',ScreenArrayX[2],'.',ScreenArrayY[2],']');
		
		glTexCoord2f(TextureArrayX[1], TextureArrayY[2]);
		glVertex3f(ScreenArrayX[1], ScreenArrayY[2], 0);
		writeln('TX [',TextureArrayX[1], '.', TextureArrayY[2],'] SX [',ScreenArrayX[1],'.',ScreenArrayY[2],']');
		
		//readln();
	glEnd;
end;
}

procedure Image.RenderQuad(VxR, VyR: tRealArray1x2; PxR, PyR: tInt64Array1x2);
begin		
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

procedure Image.LoadFromTGA(Src: ANSIString);
var
	TGA: TRawTGA;
	
begin
	Empty(); //prep everything for load
	
	TGA := TRawTGA.Create(Src);
	
	glShadeModel(GL_SMOOTH);
	glGenTextures(1, @TextureData);
	//glBindTexture(GL_TEXTURE_2D, TextureData);
	PrometheusImageSystemHandler.BindTexture(TextureData);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, TGA.Width, TGA.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, TGA.Data );
	
	Width := TGA.Width;
	Height := TGA.Height;
	Rotation := 0;
	XScale := 1;
	YScale := 1;
	Colourization.SetRGBA(255, 255, 255, 255);
	TGA.Destroy();
end;

procedure Image.LoadFromPNG(Src: ANSIString);
var
	png: TRawPNG;
	
begin
	png := TRawPNG.Create(Src);

	glGenTextures(1, @TextureData);
	//glBindTexture(GL_TEXTURE_2D, TextureData);
	PrometheusImageSystemHandler.BindTexture(TextureData);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, png.Width, png.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, png.Data );
	
	Width := png.Width;
	Height := png.Height;
	Rotation := 0;
	XScale := 1;
	YScale := 1;
	Colourization.SetRGBA(255, 255, 255, 255);
	png.Destroy();
end;

procedure Image.Load(Src: ANSIString);
var
	FileHead: FileHeader;

begin
	if DoesFileExist(Src) = False then
		Exit;
	FileHead := GetFileHeader(Src, 4);
	if IntArrayMatch(FileHead, PM_TYPEHEADER_TGA, 4) = True then
		LoadFromTGA(Src)
	else if IntArrayMatch(FileHead, PM_TYPEHEADER_PNG, 4) = True then
		LoadFromPNG(Src)
	else
		DebugWriteln('ERROR: ATTEMPTED TO LOAD IMAGE FROM [' + Src + '] BUT FILEHEADER INVALID [' + IntToStr(FileHead[1]) + ' - ' + IntToStr(FileHead[2]) + ' - ' + IntToStr(FileHead[3]) + ' - ' + IntToStr(FileHead[4]) + ']');
	InitReg();
end;

procedure Image.Draw(X, Y: Int64);
var
	TaX, TaY: tRealArray1x2;
	SaX, SaY: tInt64Array1x2;
	
begin
	if (Rotation = 0) then
		begin
			glEnable(GL_TEXTURE_2D);
			glEnable(GL_BLEND);
			glDisable(GL_DEPTH_TEST);
			glLoadIdentity();
			
			glColor4f(Colourization.R / 255, Colourization.G / 255, Colourization.B / 255, Colourization.A / 255);
			
			PrometheusImageSystemHandler.BindTexture(TextureData);
			
			TaX[1] := 0;	Tax[2] := 1;
			TaY[1] := 0;	TaY[2] := 1;
			SaX[1] := X;	Sax[2] := X + round(GetWidth * XScale);
			SaY[1] := Y;	SaY[2] := Y + round(GetHeight * YScale);
			
			RenderQuad(TaX, TaY, SaX, SaY);
		end
	else 
		DrawRotated(X + (GetWidth div 2), Y + (GetHeight div 2), Rotation);
	//DrawSelection(0, 0, GetWidth, GetHeight, X, Y);
end;

procedure Image.DrawSelection(sX, sY, sW, sH, dX, dY: Int64);
var
    VxR: tRealArray1x2;
    VyR: tRealArray1x2;
    
    PxR: tInt64Array1x2;
    PyR: tInt64Array1x2;
    
begin
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glDisable(GL_DEPTH_TEST);
	glLoadIdentity();
	
    VxR[1] := sX / GetWidth;
    VxR[2] := (sX + sW) / GetWidth;
    VyR[1] := sY / GetHeight;
    VyR[2] := (sY + sH) / GetHeight;
    
    PxR[1] := dX;
    PxR[2] := dX + (sW);
    PyR[1] := dY;
    PyR[2] := dY + (sH);
    //PyR[2] := trunc((sH) * YScale) + dY;
    
    //glBindTexture( GL_TEXTURE_2D, TextureData );
    PrometheusImageSystemHandler.BindTexture(TextureData);
	glColor4f(Colourization.R / 255, Colourization.G / 255, Colourization.B / 255, Colourization.A / 255);
	
    RenderQuad(VxR, VyR, PxR, PyR);
end;

procedure Image.Rotate(Deg: Int64);
begin
	Rotation := Rotation + Deg;
end;

begin
end.
