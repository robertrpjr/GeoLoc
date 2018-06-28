create table #temptableZiptoStore(
	FirstName varchar(max),
	LastName varchar(max),
	EmailAddress varchar(max),
	HomeAddress varchar(max),
	HomeCity varchar(max), 
	HomeState varchar(max),
	HomeZip varchar(max)
) 
insert into #temptableZiptoStore
	SELECT
		convert(xml,XMLRequest).value('(request/customer/firstName)[1]','varchar(max)') as FirstName, 
		convert(xml,XMLRequest).value('(request/customer/lastName)[1]','varchar(max)') as LastName, 
		convert(xml,XMLRequest).value('(request/customer/email)[1]','varchar(max)') as EmailAddress, 
		convert(xml,XMLRequest).value('(request/customer/address1)[1]','varchar(max)') as HomeAddress, 
		--convert(xml,XMLRequest).value('(request/customer/address2)[1]','varchar(max)') as HomeAddress2, 
		convert(xml,XMLRequest).value('(request/customer/city)[1]','varchar(max)') as HomeCity, 
		convert(xml,XMLRequest).value('(request/customer/state)[1]','varchar(max)') as HomeState,
		convert(xml,XMLRequest).value('(request/customer/zip)[1]','varchar(max)') as HomeZip 
		FROM [SalesForce].[dbo].[ExternalLeads_Audit] EA with (nolock)
		where convert(xml,XMLRequest).value('(request/control/campaignID)[1]','varchar(4)') = 'LF$6' 
		AND DATEDIFF(d,LastModifiedDate,'4/23/2018') = 0 
		and Notes is null 
		and LeadID = -1 order by LastModifiedDate DESC
		
select TMP.*, DZ.StoreID, DZ.StoreState, DZ.DistanceInMiles 
from #temptableZiptoStore TMP
join [cot-irv-dev8-03\app01].[GlobalTrans].[dbo].[dimZiptoStore] DZ
ON TMP.HomeZip = DZ.ZipCode
	

DROP TABLE #temptableZiptoStore;