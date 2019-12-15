$port=arg[0]

netstat -ano `
 | select -skip 4 `
 | % {$a = $_ -split ' {3,}'; New-Object 'PSObject' -Property @{Original=$_;Fields=$a}} `
 | ? {$_.Fields[1] -match ($port+'$')} `
 | % {taskkill /F /PID $_.Fields[4] }
