param(
    [string]$ChatGptAdminToken = $env:CHATGPT_ADMIN_TOKEN,
    [string]$OpenAiAdminKey = $env:OPENAI_ADMIN_KEY,
    [int]$DaysBack = 7
)

$ErrorActionPreference = "Stop"

function Get-UnixSecondsUtc([datetime]$date) {
    return [int][math]::Floor(([DateTimeOffset]$date.ToUniversalTime()).ToUnixTimeSeconds())
}

function Invoke-CostApiProbe {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Token
    )

    if ([string]::IsNullOrWhiteSpace($Token)) {
        [pscustomobject]@{
            name = $Name
            url = $Url
            status = "skipped"
            note = "token not set"
            body_preview = $null
        }
        return
    }

    $Token = $Token.Trim()
    if (($Token.StartsWith('"') -and $Token.EndsWith('"')) -or ($Token.StartsWith("'") -and $Token.EndsWith("'"))) {
        $Token = $Token.Substring(1, $Token.Length - 2).Trim()
    }

    try {
        $response = Invoke-WebRequest `
            -Uri $Url `
            -Headers @{ Authorization = "Bearer $Token"; "Content-Type" = "application/json" } `
            -Method Get `
            -UseBasicParsing `
            -TimeoutSec 30

        ConvertTo-ProbeResult -Name $Name -Url $Url -StatusCode ([int]$response.StatusCode) -StatusDescription $response.StatusDescription -Content ([string]$response.Content)
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

            ConvertTo-ProbeResult -Name $Name -Url $Url -StatusCode ([int]$webResponse.StatusCode) -StatusDescription $webResponse.StatusDescription -Content $content
            return
        }

        [pscustomobject]@{
            name = $Name
            url = $Url
            status = "error"
            note = $_.Exception.Message
            body_preview = $null
        }
    }
}

function ConvertTo-ProbeResult {
    param(
        [string]$Name,
        [string]$Url,
        [object]$StatusCode,
        [string]$StatusDescription,
        [string]$Content
    )

    $body = [string]$Content
    if ($body.Length -gt 1200) {
        $body = $body.Substring(0, 1200) + "..."
    }

    [pscustomobject]@{
        name = $Name
        url = $Url
        status = $StatusCode
        note = $StatusDescription
        body_preview = $body
    }
}

$startTime = Get-UnixSecondsUtc ((Get-Date).ToUniversalTime().Date.AddDays(-1 * $DaysBack))

$probes = @(
    @{
        Name = "official-openai-organization-costs-with-openai-admin-key"
        Url = "https://api.openai.com/v1/organization/costs?start_time=$startTime&bucket_width=1d&limit=1"
        Token = $OpenAiAdminKey
    },
    @{
        Name = "official-openai-organization-costs-by-user-with-openai-admin-key"
        Url = "https://api.openai.com/v1/organization/costs?start_time=$startTime&bucket_width=1d&group_by=user_id&limit=10"
        Token = $OpenAiAdminKey
    },
    @{
        Name = "official-openai-organization-costs-with-chatgpt-admin-token"
        Url = "https://api.openai.com/v1/organization/costs?start_time=$startTime&bucket_width=1d&limit=1"
        Token = $ChatGptAdminToken
    },
    @{
        Name = "chatgpt-admin-organization-costs"
        Url = "https://chatgpt.com/api/admin/v1/organization/costs?start_time=$startTime&bucket_width=1d"
        Token = $ChatGptAdminToken
    },
    @{
        Name = "chatgpt-admin-organization-costs-exact"
        Url = "https://chatgpt.com/api/admin/v1/organization/costs"
        Token = $ChatGptAdminToken
    },
    @{
        Name = "chatgpt-admin-organization-usage"
        Url = "https://chatgpt.com/api/admin/v1/organization/usage?start_time=$startTime&bucket_width=1d"
        Token = $ChatGptAdminToken
    },
    @{
        Name = "chatgpt-admin-organization-usage-exact"
        Url = "https://chatgpt.com/api/admin/v1/organization/usage"
        Token = $ChatGptAdminToken
    },
    @{
        Name = "chatgpt-admin-users-usage"
        Url = "https://chatgpt.com/api/admin/v1/users/usage?start_time=$startTime&bucket_width=1d"
        Token = $ChatGptAdminToken
    },
    @{
        Name = "chatgpt-admin-users-usage-exact"
        Url = "https://chatgpt.com/api/admin/v1/users/usage"
        Token = $ChatGptAdminToken
    }
)

$results = foreach ($probe in $probes) {
    Invoke-CostApiProbe -Name $probe.Name -Url $probe.Url -Token $probe.Token
}

$results | ConvertTo-Json -Depth 5
