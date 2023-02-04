#### HTTP(S)-запрос и HTTP(S)-ответ по [интерфейсу «flat»](https://stat.livejournal.com/doc/server/ljp.csp.flat.protocol.html)

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

#### HTTP(S)-запрос и HTTP(S)-ответ по [интерфейсу «XML-RPC»](https://stat.livejournal.com/doc/server/ljp.csp.xml-rpc.protocol.html)
