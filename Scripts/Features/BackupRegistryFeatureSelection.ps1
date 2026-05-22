function Get-FeatureId {
    param(
        [Parameter(Mandatory)]
        $Feature
    )

    $featureId = [string]$Feature.FeatureId
    if ([string]::IsNullOrWhiteSpace($featureId)) {
        throw '所选功能缺少必需的 FeatureId。'
    }

    return $featureId
}

function Get-RegistryBackedFeatures {
    param(
        [Parameter(Mandatory)]
        [object[]]$Features
    )

    return @($Features | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.RegistryKey) })
}
