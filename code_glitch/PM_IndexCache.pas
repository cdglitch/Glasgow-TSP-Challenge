unit PM_IndexCache;

{
	* We could add threads to this, hint hint XD
}

{$Mode ObjFpc}

interface

uses
	PM_Utils;

type
	PM_CacheElement = Object
			Hit: Int64;
			UID: ANSIString;
			TgtID: Int64;
		end;
	LookupCache = Object
			CacheSize: Int64;
			HitThreshHold: Int64;
			CacheData: array of PM_CacheElement;
			
			function SearchCache(UID: ANSIString): Int64;
			procedure SetCacheSize(Sz: Int64);
			procedure SetDropThreshold(TH: Int64);
			procedure CleanCache();
			procedure Empty();			
			procedure AddToCache(NewUID: ANSIString; NewTGTId: Int64);
			function GetOldestEntryID(): Int64;
		end;

implementation

procedure LookupCache.CleanCache();
var
	c, t: Int64;

begin
	if CacheSize <= 0 then
		Exit;
	
	if Length(CacheData) < 1 then
		Exit;
		
	t := GetTime();
	c := 0;
	repeat
		c += 1;
		if t - CacheData[c].Hit > HitThreshHold then
			begin
				with CacheData[c] do
					begin
						UID := '';
						Hit := 0;
						TgtID := 0;
					end;
			end;
		until c >= CacheSize;
end;

function LookupCache.GetOldestEntryID(): Int64;
var
	c, Oldest, OldestID: Int64;

begin
	GetOldestEntryID := 0;
	if Length(CacheData) < 1 then
		Exit;
		
	Oldest := GetTime();
	OldestID := 0;
	c := 0;
	repeat
		c += 1;
		if CacheData[c].Hit < Oldest then
			begin
				Oldest := CacheData[c].Hit;
				OldestID := c;
			end;
		until c >= CacheSize;
	GetOldestEntryID := OldestID;
end;


procedure LookupCache.SetDropThreshold(TH: Int64);
begin
	HitThreshHold := TH;
	CleanCache();
end;

procedure LookupCache.Empty();
begin
	SetCacheSize(0);
	HitThreshHold := 0;
end;

procedure LookupCache.SetCacheSize(Sz: Int64);
begin
	SetLength(CacheData, Sz + 1);
	CacheSize := Sz;
end;

procedure LookupCache.AddToCache(NewUID: ANSIString; NewTGTId: Int64);
var
	c: Int64;
	
begin
	if Length(CacheData) < 1 then
		Exit;
	//write('CACHE ADD ',NewUID,' ',NewTGTId,' slot ');
	CleanCache();
	c := GetOldestEntryID();
	//writeln(c);
	with CacheData[c] do
		begin
			UID := NewUID;
			TgtID := NewTGTId;
			Hit := GetTime();
		end;
end;

function LookupCache.SearchCache(UID: ANSIString): Int64;
var
	c: Int64;
	
begin
	if Length(CacheData) < 1 then
		begin
			SearchCache := -1;
			Exit;
		end;
		
	c := 0;
	repeat
		c += 1;
		if CacheData[c].UID = UID then
			begin
				CacheData[c].Hit := GetTime();
				SearchCache := CacheData[c].TgtID;
				Exit;
			end;
		until c >= CacheSize;
	SearchCache := -1;
end;

end.
