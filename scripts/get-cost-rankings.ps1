param(
    [string]$OpenAiAdminKey = $env:OPENAI_ADMIN_KEY,
    [int]$DaysBack = 1,
    [int]$Top = 10,
    [string]$BucketWidth = "1d"
)

$ErrorActionPreference = "Stop"

function Get-UnixSecondsUtc([datetime]$date) {
    return [int][math]::Floor(([DateTimeOffset]$date.ToUniversalTime()).ToUnixTimeSeconds())
}

function Invoke-OpenAiCostApi {
    param(
        [string]$GroupBy,
        [int]$StartTime,
        [string]$Key
    )

    $encodedGroupBy = [System.Uri]::EscapeDataString($GroupBy)
    $url = "https://api.openai.com/v1/organization/costs?start_time=$StartTime&bucket_width=$BucketWidth&group_by=$encodedGroupBy&limit=180"
    $allBuckets = @()

    while ($url) {
        try {
            $response = Invoke-WebRequest `
                -Uri $url `
                -Headers @{ Authorization = "Bearer $Key"; "Content-Type" = "application/json" } `
                -Method Get `
                -UseBasicParsing `
                -TimeoutSec 60
        }
        catch {
            $webResponse = $_.Exception.Response
            if ($null -ne $webResponse) {
                $reader = [System.IO.StreamReader]::new($webResponse.GetResponseStream())
                try {
                    $content = $reader.ReadToEnd()
                }
                finally {
                    $reader.Dispose()
                }

                throw "OpenAI Cost API failed: $([int]$webResponse.StatusCode) $($webResponse.StatusDescription) $content"
            }

            throw
        }

        $page = $response.Content | ConvertFrom-Json
        $allBuckets += @($page.data)

        if ($page.has_more -and $page.next_page) {
            $url = "https://api.openai.com/v1/organization/costs?start_time=$StartTime&bucket_width=$BucketWidth&group_by=$encodedGroupBy&limit=180&page=$([System.Uri]::EscapeDataString($page.next_page))"
        }
        else {
            $url = $null
        }
    }

    return $allBuckets
}

function ConvertTo-Ranking {
    param(
        [array]$Buckets,
        [string]$Dimension
    )

    $rows = foreach ($bucket in $Buckets) {
        foreach ($result in @($bucket.results)) {
            $amount = 0.0
            if ($result.amount -and $result.amount.value) {
                $amount = [double]$result.amount.value
            }

            $key = switch ($Dimension) {
                "project" {
                    if ($result.project_name) { $result.project_name }
                    elseif ($result.project_id) { $result.project_id }
                    else { "(unknown project)" }
                }
                "user" {
                    if ($result.user_email) { $result.user_email }
                    elseif ($result.user_id) { $result.user_id }
                    else { "(unknown user)" }
                }
            }

            [pscustomobject]@{
                key = $key
                amount_usd = $amount
                quantity = if ($null -ne $result.quantity) { [double]$result.quantity } else { 0.0 }
            }
        }
    }

    $rows |
        Group-Object key |
        ForEach-Object {
            [pscustomobject]@{
                name = $_.Name
                amount_usd = [math]::Round(($_.Group | Measure-Object amount_usd -Sum).Sum, 6)
                quantity = [math]::Round(($_.Group | Measure-Object quantity -Sum).Sum, 2)
            }
        } |
        Sort-Object amount_usd -Descending |
        Select-Object -First $Top
}

if ([string]::IsNullOrWhiteSpace($OpenAiAdminKey)) {
    throw "OPENAI_ADMIN_KEY is not set."
}

$OpenAiAdminKey = $OpenAiAdminKey.Trim()
if (($OpenAiAdminKey.StartsWith('"') -and $OpenAiAdminKey.EndsWith('"')) -or ($OpenAiAdminKey.StartsWith("'") -and $OpenAiAdminKey.EndsWith("'"))) {
    $OpenAiAdminKey = $OpenAiAdminKey.Substring(1, $OpenAiAdminKey.Length - 2).Trim()
}

$startTime = Get-UnixSecondsUtc ((Get-Date).ToUniversalTime().Date.AddDays(-1 * $DaysBack))

$projectBuckets = Invoke-OpenAiCostApi -GroupBy "project_id" -StartTime $startTime -Key $OpenAiAdminKey
$userBuckets = Invoke-OpenAiCostApi -GroupBy "user_id" -StartTime $startTime -Key $OpenAiAdminKey

[pscustomobject]@{
    start_time = $startTime
    days_back = $DaysBack
    project_ranking = @(ConvertTo-Ranking -Buckets $projectBuckets -Dimension "project")
    user_ranking = @(ConvertTo-Ranking -Buckets $userBuckets -Dimension "user")
} | ConvertTo-Json -Depth 6
