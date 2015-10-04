unit PM_Net;

{$Mode ObjFpc}

interface

type
	NetConnection = Object
			RemoteAddress: ANSIString;
			RemotePort: Int64;
		end;
	NetPortHandler = Object
		end;
	NetClient_Remote = Object
		end;
	NCR2 = Class(NetClient_Remote)
		end;

implementation

begin
end.
