declare @zip varchar (10);
declare @RangeInMiles int
set @RangeInMiles = 50

--Table shows all zips within X miles of a Cash Store
CREATE TABLE dimZipToStore(
      ZipCode varchar (10),
		ZipStateID varchar (2),
		StoreID varchar (5),
		StoreState varchar (3),
		DistanceInMiles FLOAT,
		CreateDate DateTime not null default (GetDate()),
		ExpiredDate Datetime		
		)

declare zip_cursor CURSOR FOR
Select ZipCode from dimZip;

OPEN zip_cursor;

FETCH NEXT FROM zip_cursor
INTO @zip;

WHILE @@FETCH_STATUS = 0
BEGIN

declare @geo geography
set @geo = (select z.GeographyLocation
			from dimZip z
			where z.ZipCode = @zip)


--Select the nearest Postal Codes
INSERT INTO dimZipToStore
(ZipCode, ZipStateID, StoreID, StoreState, DistanceInMiles)
SELECT top 1 dz.ZipCode, dz.StateID, ld.StoreID, l.StoreState, ld.GeographyLocation.STDistance(@geo)/1609.34 as DistanceInMiles --1609.344 meteres in mile
FROM dimZip dz
cross join dimLocationDetail ld
join dimlocation l on l.StoreID = ld.StoreID  
WHERE ld.GeographyLocation is not null
and dz.ZipCode = @zip 
and ld.GeographyLocation.STDistance(@geo)<=(@RangeInMiles * 1609.344)
order by DistanceInMiles

FETCH NEXT FROM zip_cursor  
   INTO @zip;  
END  
CLOSE zip_cursor;
DEALLOCATE zip_Cursor;
GO

select * from dimZipToStore
--DROP TABLE dimZipToStore
