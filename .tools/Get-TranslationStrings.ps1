param(
	[Switch]$Remove,
	[Switch]$WhatIf,
	[Switch]$Verbose,
	[String]$BlockName = "** Auto-inserted locale block. **",
	[String]$DefaultLocaleFile = "..\Localization\enUS.lua",
	[String]$OutputFile
)

If (-not (Test-Path $DefaultLocaleFile)) {
	Write-Error "Couldn't find `"$DefaultLocaleFile`"." -Category ReadError
	exit
}

if ($OutputFile -eq "") {
	$OutputFile = $DefaultLocaleFile
}

If (-not (Test-Path $OutputFile)) {
	Write-Error "Couldn't find `"$OutputFile`"." -Category ReadError
	exit
}

$DefaultLocaleFile = (Get-Item $DefaultLocaleFile).FullName
$OutputFile = (Get-Item $OutputFile).FullName
$DefaultLocaleContent = (Get-Content -Raw $DefaultLocaleFile -Encoding UTF8)
$EOL = "`r`n"
$Header = "-- BEGIN $BlockName$EOL"
$Footer = "-- END $BlockName$EOL"

if ( $Remove ) {
	$content = $DefaultLocaleContent

	if (-not $content) {
		Write-Host "Empty file. Exiting."
		exit
	}

	$start = $content.IndexOf($Header)
	$end = $content.LastIndexOf($Footer)
	
	if ( $start -gt -1 -and $end -gt -1 )  {

		if ($Verbose) {
			$content.Substring($start + $Header.Length, $end - $start - $Header.Length)
		}

		if ($start -ge $EOL.Length ) {
			$start = $start - $EOL.Length
		}
		$end = $end + $Footer.Length
		$content = $content.Remove($start, $end - $start)

		if ($WhatIf) {
			Write-Host "What if: Locale block removed."
		} else{
			[System.IO.File]::WriteAllText($OutputFile, $content)
			Write-Host "Locale block was removed."
		}
	} else {
		Write-Host "Locale block not found. Nothing was removed."
	}
} else {
	$Files = Get-ChildItem ..\ -File -Recurse -Filter '*.lua' | Where-Object {$_.FullName -notmatch '(?:\.tools|\.github|\.release|\.vscode|Localization|Libs).*$'}
	$RegexOptions = 1 -bor 2 -bor 16
	$searchKeyword = "L"
	$TableName = "L"
	$MissingEntries = @()

	foreach ($File in $Files) {
		$Content  = (Get-Content -Raw $File.FullName -Encoding UTF8)
		if ( $Content ) {
			$Results = [Text.RegularExpressions.Regex]::Matches($Content, "$searchKeyword\s*[[(]\s*([`"'].+?[`"']|\[\[.+?\]\])\s*[])]", $RegexOptions)
		
			foreach($Result in $Results) {
				if ($Result.Success) {
					$Value = $Result.Groups[1].Value
					if ( -not ( $DefaultLocaleContent -and $DefaultLocaleContent.Contains($Value) ) -and $MissingEntries.IndexOf($Value) -eq -1  ) {
						$MissingEntries += $Value
					}
				}
			}
		}
	}

	if ( $MissingEntries.Length -gt 0 ) {
		$content = $DefaultLocaleContent
		$Sorted = $MissingEntries | Sort-Object
		$Data = ""

		foreach ($Value in $Sorted) {
			$MultLineString = [Text.RegularExpressions.Regex]::Match($Value, "\[\[.+\]\]", $RegexOptions)
			if ($MultLineString.Success) {
				$Data += "$TableName[ $($MultLineString.Value) ] = true$EOL"
			} else {
				$Data += "$TableName[$Value] = true$EOL"
			}
		}

		if ($Verbose) {
			$Data
		}

		if ( $Content ) {
			$start = $content.IndexOf($Header)
			$end = $content.LastIndexOf($Footer)
			if ( $start -gt -1 -and $end -gt -1 )  {
				$insert = "$Header$Data$Footer"
				if ($start -ge $EOL.Length ) {
					$start = $start - $EOL.Length
					$insert = "$EOL$Header$Data$Footer"
				}
				$end = $end + $Footer.Length
				$content = $content.Remove($start, $end - $start)
				$content = $content.Insert($start, $insert)
			} elseif ($start -gt -1 -and $end -eq -1)  { 
				Write-Error "Found `"$Header`" but not `"$Footer`" in file `"$File`"." -Category InvalidResult
				Exit
			} elseif ($end -gt -1 -and $start -eq -1) {
				Write-Error "Found `"$Footer`" but not `"$Header`" in file `"$File`"." -Category InvalidResult
				Exit
			} else {
				$content += "$EOL$Header$Data$Footer"
			}
		} else {
			$content = "$Header$Data$Footer"
		}

		if ( $WhatIf ) {
			Write-Host "What if: Found $($Sorted.Length) entries. Writing locale block to file '$OutputFile'."
		} else {
			Write-Host "Found $($Sorted.Length) entries.  Writing locale block to file '$OutputFile'."
			[System.IO.File]::WriteAllText($OutputFile, $content)
		}

	} else {
		Write-Host "All entries in the codebase are also found in the default locale file."
	}
}
