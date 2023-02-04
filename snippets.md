## HTTP(S)-запрос и HTTP(S)-ответ по [интерфейсу «flat»](https://stat.livejournal.com/doc/server/ljp.csp.flat.protocol.html)

```powershell
$body = @{
  mode = "getchallenge"
  # ...другие входные параметры...
}
```
```powershell
$Response = Invoke-WebRequest -URI "https://www.livejournal.com/interface/flat" -Body $body -Method "POST"
```
```powershell
$Response.Content
```
Пример ответа:
```
auth_scheme
c0
challenge
c0:1674766800:1054:60:ZmbOcwbxmdswLmKngEVl:3a50482295a65607685badc39b09d47b
expire_time
1674767914
server_time
1674767854
success
OK
```

## HTTP(S)-запрос и HTTP(S)-ответ по [интерфейсу «XML-RPC»](https://stat.livejournal.com/doc/server/ljp.csp.xml-rpc.protocol.html)

```powershell
$body = @"
<?xml version="1.0"?>
<methodCall>
  <methodName>LJ.XMLRPC.getchallenge</methodName>
</methodCall>
"@
```
```powershell
$Response = Invoke-WebRequest -URI "https://www.livejournal.com/interface/xmlrpc" -Body $body -Method "POST"
```
```powershell
$Response.Content
```
