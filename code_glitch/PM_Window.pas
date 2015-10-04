unit PM_Window;

interface

uses
	PM_Debug,
	PM_Event,
	{$Ifdef Linux}
		PM_WindowCore_X11;
	{$Else}
		PM_GenericWindow;
	{$Endif}

{$Ifdef Linux}
	{$Include Src/PM/PM_Window_LinuxHeader.pas}
{$Else}
	{$Include Src/PM/PM_Window_GenericHeader.pas}
{$Endif}

implementation

{$Ifdef Linux}
	{$Include Src/PM/PM_Window_LinuxMain.pas}

	{$Include Src/PM/PM_Window_LinuxInit.pas}
{$Else}
	{$Include Src/PM/PM_Window_GenericMain.pas}

	{$Include Src/PM/PM_Window_GenericInit.pas}
{$Endif}
