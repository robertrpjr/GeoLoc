--script to update dimZipToStore

--create temp table to to rerun orignail Proc
CREATE TABLE #tempDimZipToStore(
      ZipCode varchar (10),
		ZipStateID varchar (2),
		StoreID varchar (5),
		StoreState varchar (3),
		DistanceInMiles FLOAT,
		CreateDate DateTime not null default (GetDate()),
		ExipiredDate Datetime		
		)

declare @zip varchar (10);
declare @RangeInMiles int
declare @geo geography
set @RangeInMiles = 50

--set cursor to get each zip from dimZip table
declare zip_cursor CURSOR FOR
Select ZipCode from dimZip;

OPEN zip_cursor;

FETCH NEXT FROM zip_cursor
INTO @zip;

WHILE @@FETCH_STATUS = 0
BEGIN

set @geo = (select z.GeographyLocation
			from dimZip z
			where z.ZipCode = @zip)


--Select the nearest Store to each postal code if a store exist within 50 miles
INSERT INTO #tempDimZipToStore
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

-- Insert new stores if there isn't one currently by zip code and distance is no more than 50 miles
 INSERT INTO dimZipToStore (
    ZipCode,
    ZipStateID,
    StoreID,
    StoreState,
    DistanceInMiles)
SELECT
    ZipCode = N.ZipCode,
    ZipStateID = N.ZipStateID,
    StoreID = N.StoreID,
    StoreState = N.StoreState,
    DistanceInMiles = N.DistanceInMiles
FROM
    #tempDimZipToStore AS N --New
WHERE
    N.DistanceInMiles <= 50 AND
    NOT EXISTS (
        SELECT
            'there is currently no store for this zip code'
        FROM
            dimZipToStore AS O --Original
        WHERE
            N.ZipCode = O.ZipCode)


 -- Insert the new, closer store (just the closest one)
;WITH DistanceRankingsByZipCode AS
(
    SELECT
        N.ZipCode,
        N.ZipStateID,
        N.StoreID,
        N.StoreState,
        N.DistanceInMiles,
        DistanceRankingByZipCode = ROW_NUMBER() OVER (PARTITION BY N.ZipCode ORDER BY N.DistanceInMiles ASC)
    FROM
        #tempDimZipToStore AS N
)
INSERT INTO dimZipToStore (
    ZipCode,
    ZipStateID,
    StoreID,
    StoreState,
    DistanceInMiles)
SELECT
    ZipCode = N.ZipCode,
    ZipStateID = N.ZipStateID,
    StoreID = N.StoreID,
    StoreState = N.StoreState,
    DistanceInMiles = N.DistanceInMiles
FROM
    DistanceRankingsByZipCode AS N
WHERE
    N.DistanceRankingByZipCode = 1 AND
    EXISTS (
        SELECT
            'there is currently a farther active store for the same zip code'
        FROM
            dimZipToStore AS O
        WHERE
            N.ZipCode = O.ZipCode AND
            N.DistanceInMiles < O.DistanceInMiles AND
            O.ExpiredDate IS NULL)



-- Update old record if a closer store exists (it's now on the same table)
;WITH MinDistanceByZipCode AS
(
    SELECT
        D.ZipCode,
        MinDistanceInMiles = MIN(D.DistanceInMiles)
    FROM
        dimZipToStore AS D
    GROUP BY
        D.ZipCode
)
UPDATE O SET
    ExpiredDate = GETDATE()
FROM
    dimZipToStore AS O
    INNER JOIN MinDistanceByZipCode AS C ON O.ZipCode = C.ZipCode
WHERE
    O.ExpiredDate IS NULL AND
    O.DistanceInMiles > C.MinDistanceInMiles

select * from dimZipToStore
Drop TABLE #tempDimZipToStore