# This requires the repo variable to be set, I'm setting it in the profile script to "E:\Repo\Doyle"
# But that will be different for each system. Should probably be moved to C:\Local\Repo.

# Get list of production Functions and import them
<#
we eventually shouldn't need this because all of our production functions should be rolled up into
modules.
#>
$FunctionsPath = "$Repo\Production\Functions"
$Functions = Get-ChildItem $FunctionsPath -Recurse | Select-Object -ExpandProperty FullName | Where-Object {$_ -like "*.ps1"}
ForEach ($Function in $Functions) {
    $Content = Get-Content $Function
    # Replace function declarations so that the scope of every function is global
    # Can't this to work but it's not the replace that's breaking it. It doesn't like my format or something
    # Complains about parameters not having closing parenthesis ")"
    #$FunctionDefinition = $Content -replace '^\s*function\s+((?!global[:]|local[:]|script[:]|private[:])[\w-]+)','function Global:$1'
    #[ScriptBlock]::Create($Content)
    
    # For now making all functions globally scoped

    # Execute each function script
    # This works interactively but not when called from a function due to scoping
    . $Function
}

# Get list of production Modules in the repo and import them
$ModulesPath = "$Repo\Production\Modules"
$Modules = Get-ChildItem $ModulesPath
ForEach ($Module in $Modules) {
    $Name = $Module.Name
    Import-Module "$ModulesPath\$Name"
}




<#
##### Keep all code for prod above this line.
### When we're ready to publish, separate this out for dev machines and 
# Production machines. Since we might be working on functions that are already
in production. On dev machines we want the test functions and modules to be loaded
last so they can be quickly tested.
#>

# Dot Source specific files
. E:\Repo\Doyle\Testing\Catalyst\Rebuild-Catalyst.ps1
