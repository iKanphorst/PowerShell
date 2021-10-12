## Initialize the CCM resource manager com object
[__comobject]$CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
## Get the CacheElementIDs to delete
$CacheInfo = $CCMComObject.GetCacheInfo().GetCacheElements()
## Remove cache items
ForEach ($CacheItem in $CacheInfo) {
    $CCMComObject.GetCacheInfo().DeleteCacheElement([string]$($CacheItem.CacheElementID))
}