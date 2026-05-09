param(
    [string]$UserServiceBaseUrl = "http://localhost:8080",
    [string]$SurveyServiceBaseUrl = "http://localhost:8081",
    [string]$AnalyticsServiceBaseUrl = "http://localhost:8082"
)

function Invoke-JsonRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [hashtable]$Headers,
        [object]$Body
    )

    $requestParams = @{
        Method = $Method
        Uri = $Uri
    }

    if ($null -ne $Headers) {
        $requestParams.Headers = $Headers
    }

    if ($null -ne $Body) {
        $requestParams.ContentType = "application/json"
        $requestParams.Body = ($Body | ConvertTo-Json -Depth 10)
    }

    return Invoke-RestMethod @requestParams
}

function Wait-ForHealth {
    param(
        [Parameter(Mandatory = $true)][string]$ServiceName,
        [Parameter(Mandatory = $true)][string]$HealthUrl
    )

    for ($attempt = 1; $attempt -le 30; $attempt++) {
        try {
            $result = Invoke-RestMethod -Method Get -Uri $HealthUrl
            if ($result.status -eq "ok") {
                Write-Host "$ServiceName is healthy"
                return
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    }

    throw "$ServiceName did not become healthy in time: $HealthUrl"
}

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message. Expected: $Expected. Actual: $Actual"
    }
}

Wait-ForHealth -ServiceName "user-service" -HealthUrl "$UserServiceBaseUrl/health"
Wait-ForHealth -ServiceName "survey-service" -HealthUrl "$SurveyServiceBaseUrl/health"
Wait-ForHealth -ServiceName "analytics-service" -HealthUrl "$AnalyticsServiceBaseUrl/health"

$suffix = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$email = "integration-$suffix@example.com"

$user = Invoke-JsonRequest `
    -Method "Post" `
    -Uri "$UserServiceBaseUrl/register" `
    -Body @{
        email = $email
        password = "StrongPass123"
    }

$survey = Invoke-JsonRequest `
    -Method "Post" `
    -Uri "$SurveyServiceBaseUrl/surveys" `
    -Body @{
        author_id = $user.id
        title = "Integration Survey $suffix"
        description = "Smoke test survey"
        category = "integration"
        status = "active"
        questions = @(
            @{
                name = "experience"
                text = "How was your experience?"
                type = "text"
                required = $true
            },
            @{
                name = "language"
                text = "Pick one language"
                type = "single_choice"
                options = @("python", "go", "java")
                required = $true
            }
        )
    }

$answerHeaders = @{
    "Idempotency-Key" = "verify-answer-$($survey.id)-$($user.id)"
    "X-Source-Service" = "verify-script"
}

$answerBody = @{
    survey_id = $survey.id
    respondent_id = $user.id
    answers = @(
        @{
            name = "experience"
            value = "Great"
        },
        @{
            name = "language"
            value = "python"
        }
    )
}

$firstAnswer = Invoke-JsonRequest `
    -Method "Post" `
    -Uri "$SurveyServiceBaseUrl/answers" `
    -Headers $answerHeaders `
    -Body $answerBody

$replayedAnswer = Invoke-JsonRequest `
    -Method "Post" `
    -Uri "$SurveyServiceBaseUrl/answers" `
    -Headers $answerHeaders `
    -Body $answerBody

Assert-Equal -Actual $firstAnswer.id -Expected $replayedAnswer.id -Message "Survey idempotency failed"

Start-Sleep -Seconds 2

$answerCount = Invoke-JsonRequest `
    -Method "Get" `
    -Uri "$SurveyServiceBaseUrl/surveys/$($survey.id)/answers/count"

$userStats = Invoke-JsonRequest `
    -Method "Get" `
    -Uri "$UserServiceBaseUrl/users/$($user.id)/stats"

$basicAnalytics = Invoke-JsonRequest `
    -Method "Get" `
    -Uri "$AnalyticsServiceBaseUrl/analytics/surveys/$($survey.id)/basic"

$detailedAnalytics = Invoke-JsonRequest `
    -Method "Get" `
    -Uri "$AnalyticsServiceBaseUrl/analytics/surveys/$($survey.id)/detailed"

$userSurveyAnalytics = Invoke-JsonRequest `
    -Method "Get" `
    -Uri "$AnalyticsServiceBaseUrl/analytics/users/$($user.id)/statistics"

$achievements = Invoke-JsonRequest `
    -Method "Get" `
    -Uri "$AnalyticsServiceBaseUrl/users/$($user.id)/achievements"

Assert-Equal -Actual $answerCount.answers_count -Expected 1 -Message "Survey answer count mismatch"
Assert-Equal -Actual $userStats.xp -Expected 5 -Message "User XP mismatch"
Assert-Equal -Actual $basicAnalytics.answers_count -Expected 1 -Message "Basic analytics mismatch"
Assert-Equal -Actual $detailedAnalytics.total_submissions -Expected 1 -Message "Detailed analytics mismatch"
Assert-Equal -Actual $userSurveyAnalytics.total_surveys -Expected 1 -Message "User survey analytics mismatch"
Assert-Equal -Actual $userSurveyAnalytics.total_answers -Expected 1 -Message "User total answers mismatch"

if ($achievements.achievements.Count -lt 1) {
    throw "Expected at least one achievement for user $($user.id)"
}

Write-Host "Integration smoke test passed"
