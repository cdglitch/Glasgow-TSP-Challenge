unit PM_Colour;

interface

type
	Colour = Object
			R, G, B, A: Int64;
			
			procedure SetRGBA(Red, Green, Blue, Alpha: Int64);
			procedure Empty();
		end;

function QuickColour(R, G, B, A: Int64): Colour;
procedure glColorPM(PMC: Colour);

implementation

uses
	Gl;

procedure glColorPM(PMC: Colour);
begin
	glColor4f(PMC.R / 255, PMC.G / 255, PMC.B / 255, PMC.A / 255);
end;

function QuickColour(R, G, B, A: Int64): Colour;
begin
	QuickColour.R := R;
	QuickColour.G := G;
	QuickColour.B := B;
	QuickColour.A := A;

	//QuickColour.SetRGBA(R, G, B, A);
end;

procedure Colour.Empty();
begin
	R := 0;
	G := 0;
	B := 0;
	A := 0;
end;

procedure Colour.SetRGBA(Red, Green, Blue, Alpha: Int64);
begin
	R := Red;
	G := Green;
	B := Blue;
	A := Alpha;
end;

begin
end.
