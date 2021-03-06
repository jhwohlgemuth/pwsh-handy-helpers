﻿function ConvertFrom-Pair {
    <#
    .SYNOPSIS
    Creates an object from an array of keys and an array of values. Key/Value pairs with higher index take precedence.
    .EXAMPLE
    @('a','b','c'),@(1,2,3) | fromPair
    # @{ a = 1; b = 2; c = 3 }
    #>
    [CmdletBinding()]
    [Alias('fromPair')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject
    )
    Begin {
        function Invoke-FromPair {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject
            )
            if ($InputObject.Count -gt 0) {
                $Callback = {
                    Param($Acc, $Item)
                    $Key, $Value = $Item
                    $Acc.$Key = $Value
                }
                Invoke-Reduce -Items ($InputObject | Invoke-Zip) -Callback $Callback -InitialValue @{}
            }
        }
        Invoke-FromPair $InputObject
    }
    End {
        Invoke-FromPair $Input
    }
}
function ConvertTo-Pair {
    <#
    .SYNOPSIS
    Converts an object into two arrays - keys and values.
    Note: The order of the output arrays are not guaranteed to be consistent with input object key/value pairs.
    .EXAMPLE
    @{ a = 1; b = 2; c = 3 } | toPair
    # @('c','b','a'),@(3,2,1)
    #>
    [CmdletBinding()]
    [Alias('toPair')]
    [OutputType([Array])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [PSObject] $InputObject
    )
    Process {
        switch ($InputObject.GetType().Name) {
            'PSCustomObject' {
                $Properties = $InputObject.PSObject.Properties
                $Keys = $Properties | Select-Object -ExpandProperty Name
                $Values = $Properties | Select-Object -ExpandProperty Value
                @($Keys, $Values)
            }
            'Hashtable' {
                $Keys = $InputObject.GetEnumerator() | Select-Object -ExpandProperty Name
                $Values = $InputObject.GetEnumerator() | Select-Object -ExpandProperty Value
                @($Keys, $Values)
            }
            Default { $InputObject }
        }
    }
}
function Deny-Empty {
    <#
    .SYNOPSIS
    Remove empty string values from pipeline chains
    .EXAMPLE
    'a','b','','d' | Deny-Empty
    # returns 'a','b','d'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [AllowNull()]
        [AllowEmptyString()]
        [Array] $InputObject
    )
    Begin {
        $IsNotEmptyString = { -not ($_ -is [String]) -or ($_.Length -gt 0) }
        if ($InputObject.Count -gt 0) {
            $InputObject | Where-Object $IsNotEmptyString
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Input | Where-Object $IsNotEmptyString
        }
    }
}
function Deny-Null {
    <#
    .SYNOPSIS
    Remove null values from pipeline chains
    .EXAMPLE
    1,2,$Null,4 | Deny-Null
    # returns 1,2,4
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [AllowNull()]
        [AllowEmptyString()]
        [Array] $InputObject
    )
    Begin {
        $IsNotNull = { $Null -ne $_ }
        if ($InputObject.Count -gt 0) {
            $InputObject | Where-Object $IsNotNull
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Input | Where-Object $IsNotNull
        }
    }
}
function Deny-Value {
    <#
    .SYNOPSIS
    Remove string values equal to -Value parameter
    .EXAMPLE
    'a','b','a','a' | Deny-Value -Value 'b'
    # returns 'a','a','a'
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Value')]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, Position = 1)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        $Value
    )
    Begin {
        $IsNotValue = { $_ -ne $Value }
        if ($InputObject.Count -gt 0) {
            $InputObject | Where-Object $IsNotValue
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Input | Where-Object $IsNotValue
        }
    }
}
function Find-FirstIndex {
    <#
    .SYNOPSIS
    Helper function to return index of first array item that returns true for a given predicate
    (default predicate returns true if value is $True)
    .EXAMPLE
    Find-FirstIndex -Values $False,$True,$False
    # Returns 1
    .EXAMPLE
    Find-FirstIndex -Values 1,1,1,2,1,1 -Predicate { $Args[0] -eq 2 }
    # Returns 3
    .EXAMPLE
    1,1,1,2,1,1 | Find-FirstIndex -Predicate { $Args[0] -eq 2 }
    # Returns 3

    Note the use of the unary comma operator
    .EXAMPLE
    1,1,1,2,1,1 | Find-FirstIndex -Predicate { $Args[0] -eq 2 }
    # Returns 3
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Predicate')]
    [CmdletBinding()]
    [OutputType([Int])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $Values,
        [ScriptBlock] $Predicate = { $Args[0] -eq $True }
    )
    End {
        if ($Input.Length -gt 0) {
            $Values = $Input
        }
        $Values | ForEach-Object { if (& $Predicate $_) { [Array]::IndexOf($Values, $_) } } | Select-Object -First 1
    }
}
function Get-Property {
    <#
    .SYNOPSIS
    Helper function intended to streamline getting property values within pipelines.
    .PARAMETER Name
    Property name (or array index). Also works with dot-separated paths for nested properties.
    For array-like inputs, $X,$Y | prop '0.1.2' is the same as $X[0][1][2],$Y[0][1][2] (see examples)
    .EXAMPLE
    'hello','world' | prop 'Length'
    # returns 5,5
    .EXAMPLE
    ,@(1,2,3,@(,4,5,6,@(7,8,9))) | prop '3.3.2'
    # returns 9
    #>
    [CmdletBinding()]
    [Alias('prop')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Position = 0)]
        [ValidatePattern('^-?[\w\.]+$')]
        [String] $Name
    )
    Begin {
        function Test-ArrayLike {
            Param(
                $Value
            )
            $Type = $Value.GetType().Name
            $Type -in 'Object[]', 'ArrayList'
        }
        function Test-NumberLike {
            Param(
                [String] $Value
            )
            $AsNumber = $Value -as [Int]
            $AsNumber -or ($AsNumber -eq 0)
        }
        function Get-PropertyMaybe {
            Param(
                [Parameter(Position = 0)]
                $InputObject,
                [Parameter(Position = 1)]
                [String] $Name
            )
            if ((Test-ArrayLike $InputObject) -and (Test-NumberLike $Name)) {
                $InputObject[$Name]
            } else {
                $InputObject.$Name
            }
        }
    }
    Process {
        if ($Name -match '\.') {
            $Result = $InputObject
            $Properties = $Name -split '\.'
            foreach ($Property in $Properties) {
                $Result = Get-PropertyMaybe $Result $Property
            }
            $Result
        } else {
            Get-PropertyMaybe $InputObject $Name
        }
    }
}
function Invoke-Chunk {
    <#
    .SYNOPSIS
    Creates an array of elements split into groups the length of Size. If array can't be split evenly, the final chunk will be the remaining elements.
    .EXAMPLE
    1..10 | chunk -s 3
    # @(1,2,3),@(4,5,6),@(7,8,9),@(10)
    #>
    [CmdletBinding()]
    [Alias('chunk')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Position = 1)]
        [Alias('s')]
        [Int] $Size = 0
    )
    Begin {
        function Invoke-Chunk_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject,
                [Parameter(Position = 1)]
                [Int] $Size = 0
            )
            $InputSize = $InputObject.Count
            if ($InputSize -gt 0) {
                if ($Size -gt 0 -and $Size -lt $InputSize) {
                    $Index = 0
                    $Arrays = New-Object 'System.Collections.ArrayList'
                    for ($Count = 1; $Count -le ([Math]::Ceiling($InputSize / $Size)); $Count++) {
                        [Void]$Arrays.Add($InputObject[$Index..($Index + $Size - 1)])
                        $Index += $Size
                    }
                    $Arrays
                } else {
                    $InputObject
                }
            }
        }
        Invoke-Chunk_ $InputObject $Size
    }
    End {
        Invoke-Chunk_ $Input $Size
    }
}
function Invoke-DropWhile {
    <#
    .SYNOPSIS
    Create slice of array excluding elements dropped from the beginning
    .PARAMETER Predicate
    Function that returns $True or $False
    .EXAMPLE
    1..10 | dropWhile { $Args[0] -lt 6 }
    # 6,7,8,9,10
    #>
    [CmdletBinding()]
    [Alias('dropwhile')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Predicate
    )
    Begin {
        function Invoke-DropWhile_ {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Predicate', Scope = 'Function')]
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject,
                [Parameter(Position = 1)]
                [ScriptBlock] $Predicate
            )
            if ($InputObject.Count -gt 0) {
                $Continue = $False
                $InputObject | ForEach-Object {
                    if (-not (& $Predicate $_) -or $Continue) {
                        $Continue = $True
                        $_
                    }
                }
            }
        }
        if ($InputObject.Count -eq 1 -and $InputObject[0].GetType().Name -eq 'String') {
            $Result = Invoke-DropWhile_ $InputObject[0].ToCharArray() $Predicate
            $Result -join ''
        } else {
            Invoke-DropWhile_ $InputObject $Predicate
        }
    }
    End {
        if ($Input.Count -eq 1 -and $Input[0].GetType().Name -eq 'String') {
            $Result = Invoke-DropWhile_ $Input.ToCharArray() $Predicate
            $Result -join ''
        } else {
            Invoke-DropWhile_ $Input $Predicate
        }
    }
}
function Invoke-Flatten {
    <#
    .SYNOPSIS
    Recursively flatten array
    .EXAMPLE
    @(1,@(2,3,@(4,5))) | flatten
    # 1,2,3,4,5
    #>
    [CmdletBinding()]
    [Alias('flatten')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $Values
    )
    Begin {
        function Invoke-Flat {
            Param(
                [Parameter(Position = 0)]
                [Array] $Values
            )
            if ($Values.Count -gt 0) {
                $MaxCount = $Values | ForEach-Object { $_.Count } | Get-Maximum
                if ($MaxCount -gt 1) {
                    Invoke-Flat ($Values | ForEach-Object { $_ } | Where-Object { $_ -ne $Null })
                } else {
                    $Values
                }
            }
        }
        Invoke-Flat $Values
    }
    End {
        Invoke-Flat $Input
    }
}
function Invoke-InsertString {
    <#
    .SYNOPSIS
    Easily insert strings within other strings
    .PARAMETER At
    Index
    .EXAMPLE
    'abce' | insert 'd' -At 3
    #>
    [CmdletBinding()]
    [Alias('insert')]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String] $To,
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Value,
        [Parameter(Mandatory = $True)]
        [Int] $At
    )
    Process {
        if ($At -le $To.Length -and $At -ge 0) {
            $To.Substring(0, $At) + $Value + $To.Substring($At, $To.length - $At)
        } else {
            $To
        }
    }
}
function Invoke-Method {
    <#
    .SYNOPSIS
    Invokes method with pased name of a given object. The next two positional arguments after the method name are provided to the invoked method.
    .EXAMPLE
    '  foo','  bar','  baz' | method 'TrimStart'
    # 'foo','bar','baz'
    .EXAMPLE
    1,2,3 | method 'CompareTo' 2
    # -1,0,1
    .EXAMPLE
    $Arguments = 'Substring',0,3
    'abcdef','123456','foobar' | method @Arguments
    # 'abc','123','foo'
    #>
    [CmdletBinding()]
    [Alias('method')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidatePattern('^-?\w+$')]
        [String] $Name,
        [Parameter(Position = 1)]
        $ArgumentOne,
        [Parameter(Position = 2)]
        $ArgumentTwo
    )
    Process {
        $Methods = $InputObject | Get-Member -MemberType Method | Select-Object -ExpandProperty Name
        $ScriptMethods = $InputObject | Get-Member -MemberType ScriptMethod | Select-Object -ExpandProperty Name
        $ParameterizedProperties = $InputObject | Get-Member -MemberType ParameterizedProperty | Select-Object -ExpandProperty Name
        if ($Name -in ($Methods + $ScriptMethods + $ParameterizedProperties)) {
            if ($Null -ne $ArgumentOne) {
                if ($Null -ne $ArgumentTwo) {
                    $InputObject.$Name($ArgumentOne, $ArgumentTwo)
                } else {
                    $InputObject.$Name($ArgumentOne)
                }
            } else {
                $InputObject.$Name()
            }
        } else {
            "==> $InputObject does not have a(n) `"$Name`" method" | Write-Verbose
            $InputObject
        }
    }
}
function Invoke-ObjectInvert {
    <#
    .SYNOPSIS
    Returns a new object with the keys of the given object as values, and the values of the given object, which are coerced to strings, as keys.
    Note: A duplicate value in the passed object will become a key in the inverted object with an array of keys that had the duplicate value as a value.
    .EXAMPLE
    @{ foo = 'bar' } | invert
    # @{ bar = 'foo' }
    .EXAMPLE
    @{ a = 1; b = 2; c = 1 } | invert
    # @{ '1' = 'a','c'; '2' = 'b' }
    #>
    [CmdletBinding()]
    [Alias('invert')]
    [OutputType([System.Collections.Hashtable])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [PSObject] $InputObject
    )
    Process {
        $Data = $InputObject
        $Keys, $Values = $Data | ConvertTo-Pair
        $GroupedData = @($Keys, $Values) | Invoke-Zip | Group-Object { $_[1] }
        if ($Keys.Count -gt 1) {
            $Callback = {
                Param($Acc, [String]$Key)
                $Acc.$Key = $GroupedData |
                    Where-Object { $_.Name -eq $Key } |
                    Select-Object -ExpandProperty Group |
                    ForEach-Object { $_[0] } |
                    Sort-Object
            }
            $GroupedData |
                Select-Object -ExpandProperty Name |
                Invoke-Reduce -Callback $Callback -InitialValue @{}
        } else {
            if ($Data.GetType().Name -eq 'PSCustomObject') {
                [PSCustomObject]@{ $Values = $Keys }
            } else {
                @{ $Values = $Keys }
            }
        }
    }
}
function Invoke-ObjectMerge {
    <#
    .SYNOPSIS
    Merge two or more hashtables or custom objects. The result will be of the same type as the first item passed.
    .EXAMPLE
    @{ a = 1 },@{ b = 2 },@{ c = 3 } | merge
    # @{ a = 1; b = 2; c = 3 }
    .EXAMPLE
    [PSCustomObject]@{ a = 1 },[PSCustomObject]@{ b = 2 } | merge
    # [PSCustomObject]@{ a = 1; b = 2 }
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Acc', Scope = 'Function')]
    [CmdletBinding()]
    [Alias('merge')]
    [OutputType([System.Collections.Hashtable])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject
    )
    Begin {
        function Invoke-Merge {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject
            )
            if ($Null -ne $InputObject) {
                $Result = if ($InputObject.Count -gt 1) {
                    $InputObject | Invoke-Reduce -InitialValue @{} -Callback {
                        Param($Acc, $Item)
                        $Item | ConvertTo-Pair | Invoke-Zip | ForEach-Object {
                            [String]$Key, $Value = $_
                            $Acc.$Key = $Value
                        }
                    }
                } else {
                    $InputObject
                }
                if ($InputObject[0].GetType().Name -eq 'PSCustomObject') {
                    [PSCustomObject]$Result
                } else {
                    $Result
                }
            }
        }
        Invoke-Merge $InputObject
    }
    End {
        Invoke-Merge $Input
    }
}
function Invoke-Once {
    <#
    .SYNOPSIS
    Higher-order function that takes a function and returns a function that can only be executed a certain number of times
    .PARAMETER Times
    Number of times passed function can be called (default is 1, hence the name - Once)
    .EXAMPLE
    $Function:test = Invoke-Once { 'Should only see this once' | Write-Color -Red }
    1..10 | ForEach-Object { test }
    .EXAMPLE
    $Function:greet = Invoke-Once { "Hello $($Args[0])" | Write-Color -Red }
    greet 'World'
    # no subsequent greet functions are executed
    greet 'Jim'
    greet 'Bob'

    Functions returned by Invoke-Once can accept arguments
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Function,
        [Int] $Times = 1
    )
    {
        if ($Script:Count -lt $Times) {
            & $Function @Args
            $Script:Count++
        }
    }.GetNewClosure()
}
function Invoke-Operator {
    <#
    .SYNOPSIS
    Helper function intended mainly for use within quick one-line pipeline chains
    .EXAMPLE
    @(1,2,3),@(4,5,6),@(7,8,9) | op join ''
    # returns '123','456','789'
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Scope = 'Function')]
    [CmdletBinding()]
    [Alias('op')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidatePattern('^-?[\w%\+-\/\*]+$')]
        [ValidateLength(1, 12)]
        [String] $Name,
        [Parameter(Mandatory = $True, Position = 1)]
        [Array] $Arguments
    )
    Process {
        try {
            if ($Arguments.Count -eq 1) {
                $Operand = if ([String]::IsNullOrEmpty($Arguments)) { "''" } else { "`"``$Arguments`"" }
                $Expression = "`$InputObject $(if ($Name.Length -eq 1) { '' } else { '-' })$Name $Operand"
                "==> Executing: $Expression" | Write-Verbose
                Invoke-Expression $Expression
            } else {
                $Arguments = $Arguments | ForEach-Object { "`"``$_`"" }
                $Expression = "`$InputObject -$Name $($Arguments -join ',')"
                "==> Executing: $Expression" | Write-Verbose
                Invoke-Expression $Expression
            }
        } catch {
            "==> $InputObject does not support the `"$Name`" operator" | Write-Verbose
            $InputObject
        }
    }
}
function Invoke-Partition {
    <#
    .SYNOPSIS
    Creates an array of elements split into two groups, the first of which contains elements that the predicate returns truthy for, the second of which contains elements that the predicate returns falsey for.
    The predicate is invoked with one argument (each element of the passed array)
    .EXAMPLE
    $IsEven = { Param($x) $x % 2 -eq 0 }
    1..10 | Invoke-Partition $IsEven
    # Returns @(@(2,4,6,8,10),@(1,3,5,7,9))
    #>
    [CmdletBinding()]
    [Alias('partition')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Predicate
    )
    Begin {
        function Invoke-Partition_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject,
                [Parameter(Position = 1)]
                [ScriptBlock] $Predicate
            )
            if ($InputObject.Count -gt 1) {
                $Left = @()
                $Right = @()
                foreach ($Item in $InputObject) {
                    $Condition = & $Predicate $Item
                    if ($Condition) {
                        $Left += $Item
                    } else {
                        $Right += $Item
                    }
                }
                @($Left, $Right)
            }
        }
        Invoke-Partition_ $InputObject $Predicate
    }
    End {
        Invoke-Partition_ $Input $Predicate
    }
}
function Invoke-Pick {
    <#
    .SYNOPSIS
    Create an object composed of the picked object properties
    .DESCRIPTION
    This function behaves very much like Select-Object, but with normalized behavior that works on hashtables and custom objects.
    .PARAMETER All
    Include non-existent properties. For non-existent properties, set value to -EmptyValue.
    .EXAMPLE
    @{ a = 1; b = 2; c = 3 } | pick 'a','c'
    # returns @{ a }
    #>
    [CmdletBinding()]
    [Alias('pick')]
    [OutputType([Hashtable])]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [PSObject] $From,
        [Parameter(Position = 0)]
        [Array] $Name,
        [Switch] $All,
        [AllowNull()]
        [AllowEmptyString()]
        $EmptyValue = $Null
    )
    Process {
        $Type = $From.GetType().Name
        switch ($Type) {
            'PSCustomObject' {
                $Result = [PSCustomObject]@{}
                $Keys = $From.PSObject.Properties.Name
                foreach ($Property in $Name.Where( { $_ -in $Keys })) {
                    $Result | Add-Member -MemberType NoteProperty -Name $Property -Value $From.$Property
                }
                if ($All) {
                    foreach ($Property in $Name.Where( { $_ -notin $Keys })) {
                        $Result | Add-Member -MemberType NoteProperty -Name $Property -Value $EmptyValue
                    }
                }
                $Result
            }
            'Hashtable' {
                $Result = @{}
                $Keys = $From.keys
                foreach ($Property in $Name.Where( { $_ -in $Keys })) {
                    $Result.$Property = $From.$Property
                }
                if ($All) {
                    foreach ($Property in $Name.Where( { $_ -notin $Keys })) {
                        $Result.$Property = $EmptyValue
                    }
                }
                $Result
            }
            Default {
                $Result = @{}
                if ($All) {
                    foreach ($Property in $Name) {
                        $Result.$Property = $EmptyValue
                    }
                }
                $Result
            }
        }
    }
}
function Invoke-PropertyTransform {
    <#
    .SYNOPSIS
    Helper function that can be used to rename object keys and transform values.
    .PARAMETER Transform
    The Transform function that can be a simple identity function or complex reducer (as used by Redux.js and React.js)
    The Transform function can use pipeline values or the automatice variables, $Name and $Value which represent the associated old key name and original value, respectively.
    A reducer that would transform the values with the keys, 'foo' or 'bar', migh look something like this:
    $Reducer = {
        Param($Name, $Value)
        switch ($Name) {
            'foo' { ... }
            'bar' { ... }
            Default { $Value }
        }
    }
    .PARAMETER Lookup
    Dictionary lookup object that will map old key names to new key names.
    Example:

    $Lookup = @{
        foobar = 'foo_bar'
        Name = 'first_name'
    }
    .EXAMPLE
    $Data = @{}
    $Data | Add-member -NotePropertyName 'fighter_power_level' -NotePropertyValue 90
    $Lookup = @{
        level = 'fighter_power_level'
    }
    $Reducer = {
        Param($Value)
        ($Value * 100) + 1
    }
    $Data | Invoke-PropertyTransform -Lookup $Lookup -Transform $Reducer
    .EXAMPLE
    $Data = @{
        fighter_power_level = 90
    }
    $Lookup = @{
        level = 'fighter_power_level'
    }
    $Reducer = {
        Param($Value)
        ($Value * 100) + 1
    }
    $Data | transform $Lookup $Reducer
    .EXAMPLE
    $Lookup = @{
        PIID = 'award_id_piid'
        Name = 'recipient_name'
        Program = 'major_program'
        Cost = 'total_dollars_obligated'
        Url = 'usaspending_permalink'
    }
    $Reducer = {
        Param($Name, $Value)
        switch ($Name) {
            'total_dollars_obligated' { ConvertTo-MoneyString $Value }
            Default { $Value }
        }
    }
    (Import-Csv -Path '.\contracts.csv') | Invoke-PropertyTransform -Lookup $Lookup -Transform $Reducer | Format-Table
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
    [CmdletBinding()]
    [Alias('transform')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [PSObject] $Lookup,
        [Parameter(Position = 1)]
        [ScriptBlock] $Transform = { Param($Value) $Value }
    )
    Begin {
        function New-PropertyExpression {
            Param(
                [Parameter(Mandatory = $True)]
                [String] $Name,
                [Parameter(Mandatory = $True)]
                [ScriptBlock] $Transform
            )
            {
                & $Transform -Name $Name -Value ($_.$Name)
            }.GetNewClosure()
        }
        $Property = $Lookup.GetEnumerator() | ForEach-Object {
            $OldName = $_.Value
            $NewName = $_.Name
            @{
                Name = $NewName
                Expression = (New-PropertyExpression -Name $OldName -Transform $Transform)
            }
        }
    }
    Process {
        $InputObject | Select-Object -Property $Property
    }
}
function Invoke-Reduce {
    <#
    .SYNOPSIS
    Functional helper function intended to approximate some of the capabilities of Reduce (as used in languages like JavaScript and F#)
    .PARAMETER InitialValue
    Starting value for reduce.
    The type of InitialValue will change the operation of Invoke-Reduce. If no InitialValue is passed, the first item will be used.
    Note: InitialValue must be passed when using "method" version of Invoke-Reduce. Example: (1..5).Reduce($Add, 0)
    .PARAMETER FileInfo
    The operation of combining many FileInfo objects into one object is common enough to deserve its own switch (see examples)
    .EXAMPLE
    1,2,3,4,5 | Invoke-Reduce -Callback { Param($a, $b) $a + $b }

    Compute sum of array of integers
    .EXAMPLE
    'a','b','c' | reduce { Param($a, $b) $a + $b }

    Concatenate array of strings
    .EXAMPLE
    1..10 | reduce -Add
    # 5050

    Invoke-Reduce has switches for common callbacks - Add, Every, and Some
    .EXAMPLE
    1..10 | reduce -Add ''
    # returns '12345678910'

    Change the InitialValue to change the Callback and output type
    .EXAMPLE
    Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart

    Combining directory contents into single object and visualize with Write-BarChart - in a single line!
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
    [CmdletBinding()]
    [Alias('reduce')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Array] $Items,
        [Parameter(Position = 0)]
        [ScriptBlock] $Callback = { Param($A) $A },
        [Parameter(Position = 1)]
        $InitialValue,
        [Switch] $Identity,
        [Switch] $Add,
        [Switch] $Multiply,
        [Switch] $Every,
        [Switch] $Some,
        [Switch] $FileInfo
    )
    Begin {
        function Invoke-Reduce_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $Items,
                [Parameter(Position = 1)]
                [ScriptBlock] $Callback,
                [Parameter(Position = 2)]
                $InitialValue
            )
            if ($FileInfo) {
                $InitialValue = @{}
            }
            if ($Null -eq $InitialValue) {
                $InitialValue = $Items | Select-Object -First 1
                $Items = $Items[1..($Items.Count - 1)]
            }
            $Index = 0
            $Result = $InitialValue
            $Callback = switch ((Find-FirstTrueVariable 'Identity', 'Add', 'Multiply', 'Every', 'Some', 'FileInfo')) {
                'Identity' { $Callback }
                'Add' { { Param($A, $B) $A + $B } }
                'Multiply' { { Param($A, $B) $A * $B } }
                'Every' { { Param($A, $B) $A -and $B } }
                'Some' { { Param($A, $B) $A -or $B } }
                'FileInfo' { { Param($Acc, $Item) $Acc[$Item.Name] = $Item.Length } }
                Default { $Callback }
            }
            foreach ($Item in $Items) {
                $ShouldSaveResult = ([Array], [Bool], [System.Numerics.Complex], [Int], [String] | ForEach-Object { $InitialValue -is $_ }) -contains $True
                if ($ShouldSaveResult) {
                    $Result = & $Callback $Result $Item $Index $Items
                } else {
                    & $Callback $Result $Item $Index $Items
                }
                $Index++
            }
            $Result
        }
        if ($Items.Count -gt 0) {
            Invoke-Reduce_ -Items $Items -Callback $Callback -InitialValue $InitialValue
        }
    }
    End {
        if ($Input.Count -gt 0) {
            Invoke-Reduce_ -Items $Input -Callback $Callback -InitialValue $InitialValue
        }
    }
}
function Invoke-Repeat {
    <#
    .SYNOPSIS
    Create an array with -Times number of items, all equal to $Value
    .EXAMPLE
    'a' | Invoke-Repeat -Times 3
    # returns 'a', 'a', 'a'
    .EXAMPLE
    1 | repeat -x 5
    # returns 1, 1, 1, 1, 1
    #>
    [CmdletBinding()]
    [Alias('repeat')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [AllowEmptyString()]
        $Value,
        [Parameter(Position = 1)]
        [Alias('x')]
        [Int] $Times = 1
    )
    Process {
        [System.Linq.Enumerable]::Repeat($Value, $Times)
    }
}
function Invoke-TakeWhile {
    <#
    .SYNOPSIS
    Create slice of array with elements taken from the beginning
    .EXAMPLE
    1..10 | takeWhile { $Args[0] -lt 6 }
    # 1,2,3,4,5
    #>
    [CmdletBinding()]
    [Alias('takeWhile')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Predicate
    )
    Begin {
        function Invoke-TakeWhile_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject,
                [Parameter(Position = 1)]
                [ScriptBlock] $Predicate
            )
            if ($InputObject.Count -gt 0) {
                $Result = [System.Collections.ArrayList]@{}
                $Index = 0
                while ((& $Predicate $InputObject[$Index]) -and ($Index -lt $InputObject.Count)) {
                    [Void]$Result.Add($InputObject[$Index])
                    $Index++
                }
                $Result
            }
        }
        if ($InputObject.Count -eq 1 -and $InputObject[0].GetType().Name -eq 'String') {
            $Result = Invoke-TakeWhile_ $InputObject.ToCharArray() $Predicate
            $Result -join ''
        } else {
            Invoke-TakeWhile_ $InputObject $Predicate
        }
    }
    End {
        if ($Input.Count -eq 1 -and $Input[0].GetType().Name -eq 'String') {
            $Result = Invoke-TakeWhile_ $Input.ToCharArray() $Predicate
            $Result -join ''
        } else {
            Invoke-TakeWhile_ $Input $Predicate
        }
    }
}
function Invoke-Tap {
    <#
    .SYNOPSIS
    Runs the passed function with the piped object, then returns the object.
    .DESCRIPTION
    Intercepts pipeline value, executes Callback with value as argument. If the Callback returns a non-null value, that value is returned; otherwise, the original value is passed thru the pipeline.
    The purpose of this function is to "tap into" a pipeline chain sequence in order to modify the results or view the intermediate values in the pipeline.
    This function is mostly meant for testing and development, but could also be used as a "map" function - a simpler alternative to ForEach-Object.
    .EXAMPLE
    1..10 | Invoke-Tap { $Args[0] | Write-Color -Green } | Invoke-Reduce -Add -InitialValue 0
    # Returns sum of first ten integers and writes each value to the terminal
    .EXAMPLE
    # Use Invoke-Tap as "map" function to add one to every value
    1..10 | Invoke-Tap { Param($x) $x + 1 }
    .EXAMPLE
    # Allows you to see the values as they are passed through the pipeline
    1..10 | Invoke-Tap -Verbose | Do-Something
    #>
    [CmdletBinding()]
    [Alias('tap')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Position = 0)]
        [ScriptBlock] $Callback
    )
    Process {
        if ($Callback -and $Callback -is [ScriptBlock]) {
            $CallbackResult = & $Callback $InputObject
            if ($Null -ne $CallbackResult) {
                $Result = $CallbackResult
            } else {
                $Result = $InputObject
            }
        } else {
            "[tap] `$PSItem = $InputObject" | Write-Verbose
            $Result = $InputObject
        }
        $Result
    }
}
function Invoke-Unzip {
    <#
    .SYNOPSIS
    The reverse of Invoke-Zip
    .EXAMPLE
    @(@(1,'a'),@(2,'b'),@(3,'c')) | unzip
    # @(1,2,3),@('a','b','c')
    #>
    [CmdletBinding()]
    [Alias('unzip')]
    [OutputType([Array])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject
    )
    Begin {
        function Invoke-Unzip_ {
            Param(
                [Array] $InputObject
            )
            if ($InputObject.Count -gt 0) {
                $Left = New-Object 'System.Collections.ArrayList'
                $Right = New-Object 'System.Collections.ArrayList'
                foreach ($Item in $InputObject) {
                    [Void]$Left.Add($Item[0])
                    [Void]$Right.Add($Item[1])
                }
                $Left, $Right
            }
        }
        Invoke-Unzip_ $InputObject
    }
    End {
        Invoke-Unzip_ $Input
    }
}
function Invoke-Zip {
    <#
    .SYNOPSIS
    Creates an array of grouped elements, the first of which contains the first elements of the given arrays, the second of which contains the second elements of the given arrays, and so on...
    .EXAMPLE
    @('a','a','a'),@('b','b','b'),@('c','c','c') | Invoke-Zip
    # Returns @('a','b','c'),@('a','b','c'),@('a','b','c')
    .EXAMPLE
    # EmptyValue is inserted when passed arrays of different orders
    @(1),@(2,2),@(3,3,3) | Invoke-Zip -EmptyValue 0
    # Returns @(1,2,3),@(0,2,3),@(0,0,3)
    @(3,3,3),@(2,2),@(1) | Invoke-Zip -EmptyValue 0
    # Returns @(3,2,1),@(3,2,0),@(3,0,0)
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'EmptyValue')]
    [CmdletBinding()]
    [Alias('zip')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [String] $EmptyValue = 'empty'
    )
    Begin {
        function Invoke-Zip_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject
            )
            if ($Null -ne $InputObject -and $InputObject.Count -gt 0) {
                $Data = $InputObject
                $Arrays = New-Object 'System.Collections.ArrayList'
                $MaxLength = $Data | ForEach-Object { $_.Count } | Get-Maximum
                foreach ($Item in $Data) {
                    $Initial = $Item
                    $Offset = $MaxLength - $Initial.Count
                    if ($Offset -gt 0) {
                        for ($Index = 1; $Index -le $Offset; $Index++) {
                            $Initial += $EmptyValue
                        }
                    }
                    [Void]$Arrays.Add($Initial)
                }
                $Result = New-Object 'System.Collections.ArrayList'
                for ($Index = 0; $Index -lt $MaxLength; $Index++) {
                    $Current = $Arrays | ForEach-Object { $_[$Index] }
                    [Void]$Result.Add($Current)
                }
                $Result
            }
        }
        Invoke-Zip_ $InputObject
    }
    End {
        Invoke-Zip_ $Input
    }
}
function Invoke-ZipWith {
    <#
    .SYNOPSIS
    Like Invoke-Zip except that it accepts -Iteratee to specify how grouped values should be combined (via Invoke-Reduce).
    .EXAMPLE
    @(1,1),@(2,2) | Invoke-ZipWith { Param($a,$b) $a + $b }
    # Returns @(3,3)
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Iteratee')]
    [CmdletBinding()]
    [Alias('zipWith')]
    Param(
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Iteratee,
        [String] $EmptyValue = ''
    )
    Begin {
        if ($InputObject.Count -gt 0) {
            Invoke-Zip $InputObject -EmptyValue $EmptyValue | ForEach-Object {
                $_[1..$_.Count] | Invoke-Reduce -Callback $Iteratee -InitialValue $_[0]
            }
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Input | Invoke-Zip -EmptyValue $EmptyValue | ForEach-Object {
                $_[1..$_.Count] | Invoke-Reduce -Callback $Iteratee -InitialValue $_[0]
            }
        }
    }
}
function Join-StringsWithGrammar {
    <#
    .SYNOPSIS
    Helper function that creates a string out of a list that properly employs commands and "and"
    .EXAMPLE
    Join-StringsWithGrammar @('a', 'b', 'c')
    Returns "a, b, and c"
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Delimiter')]
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String[]] $Items,
        [String] $Delimiter = ','
    )

    Begin {
        function Join-StringArray {
            Param(
                [Parameter(Mandatory = $True, Position = 0)]
                [AllowNull()]
                [AllowEmptyCollection()]
                [String[]] $Items
            )
            $NumberOfItems = $Items.Length
            if ($NumberOfItems -gt 0) {
                switch ($NumberOfItems) {
                    1 {
                        $Items -join ''
                    }
                    2 {
                        $Items -join ' and '
                    }
                    Default {
                        @(
                            ($Items[0..($NumberOfItems - 2)] -join ', ') + ','
                            'and'
                            $Items[$NumberOfItems - 1]
                        ) -join ' '
                    }
                }
            }
        }
        Join-StringArray $Items
    }
    End {
        Join-StringArray $Input
    }
}
function Remove-Character {
    <#
    .SYNOPSIS
    Remove character from -At index of string -Value
    .EXAMPLE
    'abcd' | remove -At 2
    # 'abd'
    .EXAMPLE
    'abcd' | remove -First
    # 'bcd'
    .EXAMPLE
    'abcd' | remove -Last
    # 'abc'
    #>
    [CmdletBinding()]
    [Alias('remove')]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String] $Value,
        [Int] $At,
        [Switch] $First,
        [Switch] $Last
    )
    Process {
        $At = if ($First) { 0 } elseif ($Last) { $Value.Length - 1 } else { $At }
        if ($At -lt $Value.Length -and $At -ge 0) {
            $Value.Substring(0, $At) + $Value.Substring($At + 1, $Value.length - $At - 1)
        } else {
            $Value
        }
    }
}
function Test-Equal {
    <#
    .SYNOPSIS
    Helper function meant to provide a more robust equality check (beyond just integers and strings)
    Works with numbers, booleans, strings, hashtables, custom objects, and arrays
    Note: Function has limited support for comparing $Null values
    .EXAMPLE
    # Test a list of items
    # ...with just pipeline parameters
    42,42,42,42 | equal
    # ...or with pipeline and one positional parameter
    'na','na','na','na','na','na','na','na' | equal 'batman'
    .EXAMPLE
    # Test a pair of items
    # ...with pipeline and positional parameters
    'foo' | equal 'bar'
    # ...or with just positional parameters
    equal 'foo' 'bar'
    .EXAMPLE
    # Limited support for $Null comparisons
    # Supported
    equal $Null $Null
    # NOT supported
    $Null | equal $Null
    $Null,$Null | equal
    #>
    [CmdletBinding()]
    [Alias('equal')]
    [OutputType([Bool])]
    Param(
        [Parameter(Position = 0)]
        $Left,
        [Parameter(Position = 1)]
        $Right,
        [Parameter(ValueFromPipeline = $True)]
        [Array] $InputObject
    )
    Begin {
        function Test-Equal_ {
            Param(
                $Left,
                $Right,
                [Array] $FromPipeline
            )
            $Compare = {
                Param($Left, $Right)
                $Type = $Left.GetType().Name
                switch -Wildcard ($Type) {
                    'Object`[`]' {
                        $Index = 0
                        $Left | ForEach-Object { Test-Equal $_ $Right[$Index]; $Index++ } | Invoke-Reduce -Every
                    }
                    'Int*`[`]' {
                        $Index = 0
                        $Left | ForEach-Object { Test-Equal $_ $Right[$Index]; $Index++ } | Invoke-Reduce -Every
                    }
                    'Double`[`]*' {
                        $Index = 0
                        $Left | ForEach-Object { Test-Equal $_ $Right[$Index]; $Index++ } | Invoke-Reduce -Every
                    }
                    'PSCustomObject' {
                        $Every = { $Args[0] -and $Args[1] }
                        $LeftKeys = $Left.PSObject.Properties.Name
                        $RightKeys = $Right.PSObject.Properties.Name
                        $LeftValues = $Left.PSObject.Properties.Value
                        $RightValues = $Right.PSObject.Properties.Value
                        $Index = 0
                        $HasSameKeys = $LeftKeys |
                            ForEach-Object { Test-Equal $_ $RightKeys[$Index]; $Index++ } |
                            Invoke-Reduce -Callback $Every -InitialValue $True
                        $Index = 0
                        $HasSameValues = $LeftValues |
                            ForEach-Object { Test-Equal $_ $RightValues[$Index]; $Index++ } |
                            Invoke-Reduce -Callback $Every -InitialValue $True
                        $HasSameKeys -and $HasSameValues
                    }
                    'Hashtable' {
                        $Every = { $Args[0] -and $Args[1] }
                        $Index = 0
                        $RightKeys = $Right.GetEnumerator() | Select-Object -ExpandProperty Name
                        $HasSameKeys = $Left.GetEnumerator() |
                            ForEach-Object { Test-Equal $_.Name $RightKeys[$Index]; $Index++ } |
                            Invoke-Reduce -Callback $Every -InitialValue $True
                        $Index = 0
                        $RightValues = $Right.GetEnumerator() | Select-Object -ExpandProperty Value
                        $HasSameValues = $Left.GetEnumerator() |
                            ForEach-Object { Test-Equal $_.Value $RightValues[$Index]; $Index++ } |
                            Invoke-Reduce -Callback $Every -InitialValue $True
                        $HasSameKeys -and $HasSameValues
                    }
                    Default { $Left -eq $Right }
                }
            }
            if ($FromPipeline.Count -gt 0) {
                $Items = $FromPipeline
                if ($PSBoundParameters.ContainsKey('Left')) {
                    $Items += $Left
                }
                $Count = $Items.Count
                if ($Count -gt 1) {
                    $Head = $Items[0]
                    $Rest = $Items[1..($Count - 1)]
                    @($Head), $Rest |
                        Invoke-Zip -EmptyValue $Head |
                        ForEach-Object { & $Compare $_[0] $_[1] } |
                        Invoke-Reduce -Every -InitialValue $True
                } else {
                    $True
                }
            } else {
                if ($Null -ne $Left) {
                    & $Compare $Left $Right
                } else {
                    Write-Verbose '==> Left value is null'
                    $Left -eq $Right
                }
            }
        }
        if ($PSBoundParameters.ContainsKey('Right')) {
            Test-Equal_ $Left $Right
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Parameters = @{
                FromPipeline = $Input
            }
            if ($PSBoundParameters.ContainsKey('Left')) {
                $Parameters.Left = $Left
            }
            Test-Equal_ @Parameters
        }
    }
}