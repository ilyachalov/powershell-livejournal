#  Скрипт предназначен для загрузки всех постов журнала с сервера «LiveJournal.com».
#  Автор: https://ilyachalov.livejournal.com (Илья Чалов).

#  КАК ЗАПУСТИТЬ СКРИПТ

#  Первый и второй примеры делают одно и то же. Третий пример запускает режим
#  отладки, в котором будут выведены дополнительные сообщения. Внимание, скрипт
#  создает в текущем местоположении папки и файлы, поэтому запускать его
#  следует в отдельной, специально для него отведенной папке. Пароль
#  запрашивается отдельно, не в параметре, из соображений безопасности.

#  PS > .\Get-LiveJournal -User "vbgtut"     # (1)
#  PS > .\Get-LiveJournal "vbgtut"           # (2)
#  PS > .\Get-LiveJournal "vbgtut" -Debug    # (3)

#  ПАРАМЕТРЫ СКРИПТА

[CmdletBinding()] param([String]$user)
if (!$user) {
  Write-Error "Нужен один параметр (имя пользователя)! Скрипт прерван."
  return
}
$password = Read-Host "Введите пароль пользователя `"$user`"" -MaskInput

#  КОНСТАНТЫ СКРИПТА

$uri = "https://www.livejournal.com/interface/flat"
$serverError = "Ошибка на сервере! Скрипт прерван."

#  БИБЛИОТЕКА ВСПОМОГАТЕЛЬНЫХ ФУНКЦИЙ

#  Преобразование многострочной строки (multiline string) в хеш-таблицу
function toHashTable($str) {
  $arr = $str -split '\r?\n'
  $hash = @{}
  $len = if ($arr.Length % 2) { $arr.Length - 1 } else { $arr.Length }
  for ($i = 0; $i -lt $len; $i += 2) {
    $hash[$arr[$i]] = $arr[$i + 1]
  }
  return $hash
}

#  Получение хеш-суммы заданной строки по заданному алгоритму
function getHash($str, $alg) {
  $stringAsStream = [System.IO.MemoryStream]::new()
  $writer = [System.IO.StreamWriter]::new($stringAsStream)
  $writer.write($str)
  $writer.Flush()
  $stringAsStream.Position = 0
  (Get-FileHash -InputStream $stringAsStream -Algorithm $alg).Hash.ToLower()
}

#  Преобразование хеш-таблицы с параметрами в таблицу записей об обновлениях журнала
function toActionsTable($hashT) {
  $arrL = [System.Collections.ArrayList]::new()
  foreach ($key in $hashT.Keys) {
    if ($key -match '^.+_(.+)_(.+)$') {  #  отбрасываю общие параметры и
      $num = [int]$Matches[1]            #  вычленяю части названия ключа
      $colName = $Matches[2]
      $val = $hashT[$key]
      $searchRes = $arrL | Where-Object { $_.num -eq $num }
      $row = if ($searchRes) {
        $searchRes[0]
      } else {
        $i = $arrL.Add(("" | Select-Object "num","itemT","itemN","time","downloaded"))
        $arrL[$i].num = $num
        $arrL[$i]
      }
      if ($colName -eq "item") {
        $val -match '^(.+)-(.+)$' | Out-Null
        $row.itemT = $Matches[1]
        $row.itemN = [int]$Matches[2]
      } elseif ($colName -eq "action") {
        # отбрасываю это поле за ненадобностью
      } else {
        $row.$colName = $val
      }
    }
  }
  return $arrL
}

#  Преобразование хеш-таблицы с параметрами в таблицу с постами журнала
function toEventsTable($hashT) {
  $arrL = [System.Collections.ArrayList]::new()
  foreach ($key in $hashT.Keys) {
    if ($key -match '^events_(.+)_(.+)$') {
      $num = [int]$Matches[1]
      $colName = $Matches[2]
      $val = $hashT[$key]
      $searchRes = $arrL | Where-Object { $_.num -eq $num }
      $row = if ($searchRes) {
        $searchRes[0]
      } else {
        $i = $arrL.Add(("" | Select-Object "num","itemid","anum","eventtime","subject","url","event"))
        $arrL[$i].num = $num
        $arrL[$i]
      }
      if ($colName -eq "url") {
        $val -match '^https://.+.livejournal.com/(.+)$' | Out-Null
        $row.$colName = $Matches[1]
      } elseif ($colName -eq "itemid") {
        $row.$colName = [int]$val
      } else {
        $row.$colName = $val
      }
    }
  }
  return $arrL
}

#  НАЧАЛО ГЛАВНОЙ ЧАСТИ СКРИПТА

$startTime = Get-Date
$folder = $startTime.ToString("yyyy-MM-dd HH.mm.ss")

#  Получаю «cookie» от сервера (начало сессии)
$body = @{
  mode = "getchallenge"
}
$Response = Invoke-WebRequest -URI $uri -Body $body -Method "POST"
Write-Debug ($body["mode"] + ": " + $Response.StatusCode + " " + $Response.StatusDescription)
if ($Response.StatusCode -ne 200) { Write-Error $serverError; return }
$params = toHashTable($Response.Content)
if ($params["success"] -ne "OK") {
  Write-Error "$($params["success"]): $($params["errmsg"])"; return
}
$hPass = getHash $password "MD5"
$hResp = getHash ($params["challenge"] + $hPass) "MD5"
$body = @{
  mode = "sessiongenerate"
  user = $user
  auth_method = "challenge"
  auth_challenge = $params["challenge"]
  auth_response = $hResp
}
$Response = Invoke-WebRequest -URI $uri -Body $body -Method "POST"
Write-Debug ($body["mode"] + ": " + $Response.StatusCode + " " + $Response.StatusDescription)
if ($Response.StatusCode -ne 200) { Write-Error $serverError; return }
$params = toHashTable($Response.Content)
if ($params["success"] -ne "OK") {
  Write-Error "$($params["success"]): $($params["errmsg"])"; return
}
$ljsession = $params["ljsession"]

#  Получение всех записей об обновлениях журнала
$lastsync = ""
[int]$sync_total = 0
$tableS = ""
do {
  $body = @{
    mode = "syncitems"
    user = $user
    auth_method = "cookie"
  }
  if ($lastsync) { $body["lastsync"] = $lastsync }
  $headers = @{
    "X-LJ-Auth" = "cookie"
    Cookie = "ljsession=$ljsession"
  }
  $Response = Invoke-WebRequest -URI $uri -Body $body -Method "POST" -Headers $headers
  Write-Debug ($body["mode"] + "(" + $body["lastsync"] + "): " + $Response.StatusCode +
               " " + $Response.StatusDescription)
  if ($Response.StatusCode -ne 200) { Write-Error $serverError; return }
  $params = toHashTable($Response.Content)
  if ($params["success"] -ne "OK") {
    Write-Error "$($params["success"]): $($params["errmsg"])"; return
  }
  if (!$sync_total) { $sync_total = $params["sync_total"] }
  if ($tableS) {
    $tableS = $tableS + (toActionsTable $params)
  } else {
    $tableS = toActionsTable $params
  }
  $lastsync = ($tableS.time | Measure-Object -Maximum).Maximum
} while ($tableS.Length -lt $sync_total)

#  Отбор только записей об обновлениях журнала, касающихся постов
$tableSL = $tableS | Where-Object { $_.itemT -eq "L" }

#  Получение всех постов журнала
$lastsync = ""
while ($tableSL | Where-Object { $null -eq $_.downloaded }) {
  $body = @{
    mode = "getevents"
    user = $user
    auth_method = "cookie"
    selecttype = "syncitems"
    ver = "1"
  }
  if ($lastsync) { $body["lastsync"] = $lastsync }
  $headers = @{
    "X-LJ-Auth" = "cookie"
    Cookie = "ljsession=$ljsession"
  }
  $Response = Invoke-WebRequest -URI $uri -Body $body -Method "POST" -Headers $headers
  Write-Debug ($body["mode"] + "(" + $body["lastsync"] + "): " + $Response.StatusCode +
               " " + $Response.StatusDescription)
  if ($Response.StatusCode -ne 200) { Write-Error $serverError; return }
  $params = toHashTable($Response.Content)
  if ($params["success"] -ne "OK") {
    Write-Error "$($params["success"]): $($params["errmsg"])"; return
  }
  if (!(Test-Path -Path ".\$user\")) {
    New-Item -ItemType "directory" -Path ".\$user\$folder\" | Out-Null
  }
  $datetime = ($lastsync) ? $lastsync : "1970-01-01 00:00:00"
  $datetime = $datetime -replace ":", "."
  $Response.Content | Out-File -FilePath ".\$user\$folder\$datetime-$($params["events_count"]).txt" `
                      -NoNewline -NoClobber
  if ($?) { ".\$user\$folder\$datetime-$($params["events_count"]).txt" }
  $tableE = toEventsTable $params
  $tableE | ForEach-Object {
    $itemid = $_.itemid
    $searchRes = $tableSL | Where-Object { $_.itemN -eq $itemid }
    $searchRes[0].downloaded = 1
  }
  $downloaded = $tableSL | Where-Object { $true -eq $_.downloaded }
  $lastsync = ($downloaded.time | Measure-Object -Maximum).Maximum
}

#  Завершение сессии по ее идентификатору
$ljsession -match '^.+:.+:.(.+):.+:.+$' | Out-Null
$body = @{
  mode = "sessionexpire"
  user = $user
  auth_method = "cookie"
  "expire_id_$($Matches[1])" = "true"
}
$headers = @{
  "X-LJ-Auth" = "cookie"
  Cookie = "ljsession=$ljsession"
}
$Response = Invoke-WebRequest -URI $uri -Body $body -Method "POST" -Headers $headers
Write-Debug ($body["mode"] + "(" + $Matches[1] + "): " + $Response.StatusCode +
             " " + $Response.StatusDescription)
if ($Response.StatusCode -ne 200) { Write-Error $serverError; return }
$params = toHashTable($Response.Content)
if ($params["success"] -ne "OK") {
  Write-Error "$($params["success"]): $($params["errmsg"])"; return
}

#  ОКОНЧАНИЕ ГЛАВНОЙ ЧАСТИ СКРИПТА

$endTime = Get-Date
"Работа выполнена за " + ($endTime - $startTime).Seconds + " сек."
