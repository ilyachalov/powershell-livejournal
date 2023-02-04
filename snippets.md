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
Пример тела ответа:
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
Пример тела ответа:
```
<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct><member><name>auth_scheme</name><value><string>c0</string></value></member><member><name>server_time</name><value><int>1674771448</int></value></member><member><name>challenge</name><value><string>c0:1674770400:1048:60:yeM13Zf4UeujVPDIapTv:03d7b6a66990e95ba17ced533b9b98d2</string></value></member><member><name>expire_time</name><value><int>1674771508</int></value></member></struct></value></param></params></methodResponse>
```
