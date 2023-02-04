## HTTP(S)-запрос и ответ по [интерфейсу «flat»](https://stat.livejournal.com/doc/server/ljp.csp.flat.protocol.html) без аутентификации

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
Помещаем тело ответа (параметры результата) в хеш-таблицу (ассоциативный массив):
```powershell
function toHash($str) {
  $arr = $str -split '\r?\n'
  $hash = @{}
  for ($i = 0; $i -lt $arr.Length; $i += 2) {
    $hash[$arr[$i]] = $arr[$i + 1]
  }
  return $hash
}
```
```powershell
$params = toHash($Response.Content)
```
```powershell
$params
```
Пример содержимого полученной хеш-таблицы (ассоциативного массива):
```
Name           Value
----           -----
expire_time    1674767914
challenge      c0:1674766800:1054:60:ZmbOcwbxmdswLmKngEVl:3a50482295a65607685badc39b09d47b
server_time    1674767854
success        OK
auth_scheme    c0
```

## HTTP(S)-запрос и ответ по [интерфейсу «XML-RPC»](https://stat.livejournal.com/doc/server/ljp.csp.xml-rpc.protocol.html) без аутентификации

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
Приведение тела ответа в удобный для чтения человеком вид с помощью класса «[System.Xml.Linq.XDocument](https://learn.microsoft.com/en-us/dotnet/api/system.xml.linq.xdocument)» платформы «[.NET](https://learn.microsoft.com/en-us/dotnet/)»:
```powershell
[System.Xml.Linq.XDocument]::Parse($Response.Content).ToString()
```
```
<methodResponse>
  <params>
    <param>
      <value>
        <struct>
          <member>
            <name>auth_scheme</name>
            <value>
              <string>c0</string>
            </value>
          </member>
          <member>
            <name>server_time</name>
            <value>
              <int>1674771448</int>
            </value>
          </member>
          <member>
            <name>challenge</name>
            <value>
              <string>c0:1674770400:1048:60:yeM13Zf4UeujVPDIapTv:03d7b6a66990e95ba17ced533b9b98d2</string>
            </value>
          </member>
          <member>
            <name>expire_time</name>
            <value>
              <int>1674771508</int>
            </value>
          </member>
        </struct>
      </value>
    </param>
  </params>
</methodResponse>
```
Помещаем тело ответа (параметры результата) в хеш-таблицу (ассоциативный массив) с помощью класса «[System.Xml.XmlDocument](https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmldocument)» платформы «[.NET](https://learn.microsoft.com/en-us/dotnet/)»:
```powershell
function toHash($str) {
  $xml = [xml]$str
  $arr = $xml.methodResponse.params.param.value.struct.member
  $hash = @{}
  for ($i = 0; $i -lt $arr.Length; $i++) {
    $hash[$arr[$i].name] = $arr[$i].value.FirstChild."#text"
  }
  return $hash
}
```
```powershell
$params = toHash($Response.Content)
```
```powershell
$params
```
Пример содержимого полученной хеш-таблицы (ассоциативного массива):
```
Name           Value
----           -----
challenge      c0:1674770400:1048:60:yeM13Zf4UeujVPDIapTv:03d7b6a66990e95ba17ced533b9b98d2
auth_scheme    c0
expire_time    1674771508
server_time    1674771448
```
