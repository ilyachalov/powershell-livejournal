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
