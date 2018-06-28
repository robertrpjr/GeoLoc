-- COT-IRV-DEV8-03\app01.GlobalTrans

CREATE TABLE dimZip(
    [StateID] [varchar] (2) NOT NULL,
    [ZipCode] [varchar](10) NOT NULL PRIMARY KEY,
    [Latitude] [decimal](16, 12) NULL,
    [Longitude] [decimal](16, 12) NULL,
    [GeographyLocation] [geography] NULL,
    --[CreatedOn] [datetime] NOT NULL,
    --[LastUpdated] [datetime] NOT NULL,
    [GeographyLocation_temp] [varchar](100) NULL)


create table #stageDimZip
(
country varchar (2),
ZipCode varchar (10) PRIMARY KEY,
City varchar (180),
stateName varchar (50),
stateID varchar (2),
province varchar (50),
community varchar (20),
lat decimal (16,12),
long decimal (16,12),
accuracy varchar (5)
)


BULK
INSERT #stageDimZip
FROM 'c:\US.csv'
WITH
(
FIELDTERMINATOR = ',',
ROWTERMINATOR = '0x0a'
)
GO

--insert temp table into PostalCode
INSERT INTO dbo.dimZip
(StateID, ZipCode, Latitude, Longitude)
SELECT DISTINCT StateID, ZipCode, Lat, Long FROM #stageDimZip where stateID is not null


--convert long/lat to a varchar geographic point
UPDATE dbo.dimZip
SET GeographyLocation_temp= 'POINT(' + CONVERT(VARCHAR(100),longitude)
+' ' +  CONVERT(VARCHAR(100),latitude) +')'

--convert GeographyLocation_temp to geographic type store in GeographicLocation, with a Spatial index 
UPDATE dimZip
SET GeographyLocation  =  geography::STGeomFromText(GeographyLocation_temp,4326)

CREATE SPATIAL INDEX  SIndx_SpatialTable_geography_col1
   ON dimZip(GeographyLocation);

select * from dbo.dimZip
order by stateID
