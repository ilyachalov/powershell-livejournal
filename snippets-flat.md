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

## Простейшая («[clear](https://stat.livejournal.com/doc/server/ljp.csp.auth.clear.html)») аутентификация

### Через входной параметр «password»

Пример хеш-таблицы с входными параметрами для получения одного определенного поста из журнала (блога):
```powershell
$body = @{
  mode = "getevents"
  user = "vbgtut"
  password = "пароль"
  selecttype = "one"
  itemid = "148"
  ver = "1"
}
```
Отправка HTTP(S)-запроса, получение ответа и извлечение из тела ответа текста поста:
```
$Response = Invoke-WebRequest -URI "https://www.livejournal.com/interface/flat" -Body $body -Method "POST"
$params = toHash($Response.Content)
$params["events_1_event"]
```
Пример текста поста (возвращается перекодированным в [процентную кодировку](https://ru.wikipedia.org/wiki/URL#%D0%9A%D0%BE%D0%B4%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5_URL), которая используется в URL-адресах):
```
%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D0%BE%D1%82%2014.04.2015%20%D0%B3.%20%D0%9D%D0%B0%20%D1%82%D0%B5%D0%BB%D0%B5%D1%84%D0%BE%D0%BD.%0D%0A%0D%0A%C2%AB%D0%9A%D0%B0%D0%BA%20%D1%83%D0%BF%D0%BE%D0%B8%D1%82%D0%B5%D0%BB%D1%8C%D0%BD%D1%8B%20%D0%B2%20%D0%A0%D0%BE%D1%81%D1%81%D0%B8%D0%B8%20%D0%B2%D0%B5%D1%87%D0%B5%D1%80%D0%B0%C2%BB%20%28%D1%81%29.%0D%0A%0D%0A%3Ca%20href%3D%22https%3A%2F%2Fimg-fotki.yandex.ru%2Fget%2F4608%2F102249717.9%2F0_de845_6a44b264_orig.jpg%22%3E%3Cimg%20src%3D%22https%3A%2F%2Fimg-fotki.yandex.ru%2Fget%2F4608%2F102249717.9%2F0_de845_6a44b264_orig.jpg%22%20width%3D%22900%22%20height%3D%22599%22%20%2F%3E%3C%2Fa%3E
```
Раскодирование текста поста из процентной кодировки в кодировку UTF-8 с помощью метода «[UrlDecode](https://learn.microsoft.com/en-us/dotnet/api/system.web.httputility.urldecode)» класса «[System.Web.HttpUtility](https://learn.microsoft.com/en-us/dotnet/api/system.web.httputility)» платформы «[.NET](https://learn.microsoft.com/en-us/dotnet/)»:
```powershell
[System.Web.HttpUtility]::UrlDecode($params["events_1_event"])
```
Результат раскодирования:
```
Снимок от 14.04.2015 г. На телефон.

«Как упоительны в России вечера» (с).

<a href="https://img-fotki.yandex.ru/get/4608/102249717.9/0_de845_6a44b264_orig.jpg"><img src="https://img-fotki.yandex.ru/get/4608/102249717.9/0_de845_6a44b264_orig.jpg" width="900" height="599" /></a>
```

### Через входной параметр «hpassword»

Получение [хеш-суммы](https://ru.wikipedia.org/wiki/%D0%A5%D0%B5%D1%88-%D1%81%D1%83%D0%BC%D0%BC%D0%B0) пароля с помощью командлета «[Get-FileHash](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash)»:
```powershell
function getHash($str, $alg) {
  $stringAsStream = [System.IO.MemoryStream]::new()
  $writer = [System.IO.StreamWriter]::new($stringAsStream)
  $writer.write($str)
  $writer.Flush()
  $stringAsStream.Position = 0
  (Get-FileHash -InputStream $stringAsStream -Algorithm $alg).Hash
}
```
Пример получения хеш-суммы для строки `"пароль"` по [алгоритму «MD5»](https://ru.wikipedia.org/wiki/MD5):
```powershell
getHash "пароль" "MD5"
```
```
E242F36F4F95F12966DA8FA2EFD59992
```
Пример хеш-таблицы с входными параметрами для получения одного определенного поста из журнала (блога):
```powershell
$body = @{
  mode = "getevents"
  user = "vbgtut"
  hpassword = "E242F36F4F95F12966DA8FA2EFD59992"
  selecttype = "one"
  itemid = "148"
  ver = "1"
}
```
