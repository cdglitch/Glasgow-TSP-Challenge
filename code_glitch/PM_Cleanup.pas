unit PM_Cleanup;

{$Mode ObjFpc}

interface

uses
	PM_Image;

type
	oPrometheusImageRegistry = Object
			ImagePTR: array of pImage;
			DataLength: Int64;

			private
				function Malloc(): Int64;

			public	
				procedure RegisterImagePTR(Ptr: pImage);
				procedure Wipe();
		end;

var
	PrometheusImageRegistry: oPrometheusImageRegistry;

implementation

uses
	PM_Logs;

function oPrometheusImageRegistry.Malloc(): Int64;
begin
	if DataLength <= 0 then
		DataLength := 1;
	SetLength(ImagePTR, DataLength + 1);
	Malloc := DataLength;
end;

procedure oPrometheusImageRegistry.RegisterImagePTR(Ptr: pImage);
var
	c: Int64;
	
begin
	c := Malloc();
	ImagePTR[c] := Ptr;
	LogMsg('PM_Cleanup: Registered new object of type Image');
end;

procedure oPrometheusImageRegistry.Wipe();
var
	c: Int64;

begin
	if DataLength <= 0 then
		Exit;
		
	c := 0;
	repeat
		c += 1;
		
		try
			ImagePTR[c]^.Empty();
		Except
			LogMsg('PM_Cleanup: Invalid pointer address eaccessed');
		end;
		
		until c >= DataLength;
end;

begin
end.
