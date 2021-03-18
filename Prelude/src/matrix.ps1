﻿function Format-ComplexValue {
    <#
    .SYNOPSIS
    Utility method for rendering readable output for complex numbers
    .PARAMETER WithColor
    When -WithColor is used, the output will include color templates to add color (see Write-Label)
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [Complex] $Value,
        [Switch] $WithColor
    )
    $Real = $Value.Real
    $Imaginary = $Value.Imaginary
    $Re = if ($Real -eq 0) { '' } else { $Real }
    $Sign = if ([Math]::Sign($Imaginary) -lt 0) { '-' } else { '+' }
    $Op = if ($Re.Length -gt 0 -and $Im.Length -gt 0) { " $Sign " } else { '' }
    $Minus = if ($Imaginary -lt 0 -and $Re.Length -eq 0) { '-' } else { '' }
    $Im = if ($Imaginary -eq 0) { '' } else { [Math]::Abs($Imaginary) }
    $I = if ($WithColor) { '{{#cyan i}}' } else { 'i' }
    "${Re}${Op}${Minus}${Im}${I}"
}
function New-ComplexValue {
    <#
    .SYNOPSIS
    Utility method for creating complex values
    #>
    [CmdletBinding()]
    [Alias('complex')]
    [OutputType([System.Numerics.Complex])]
    Param(
        [Parameter(Position = 0)]
        [Alias('Re')]
        [Int] $Real = 0,
        [Parameter(Position = 1)]
        [Alias('Im')]
        [Int] $Imaginary = 0
    )
    [System.Numerics.Complex]::New($Real, $Imaginary)
}
function New-Matrix {
    <#
    .SYNOPSIS
    Utility wrapper function for creating matrices
    .DESCRIPTION
    New-Matrix is a wrapper function for the [Matrix] class and is intended to reduce the effort required to create [Matrix] objects.

    Use "New-Matrix | Get-Member" to see available methods:

    Adj: Return matrix adjugate ("classical adjoint")
    > Note: Available as a class method - [Matrix]::Adj

    Det: Return matrix determinant (even matrices larger than 3x3
    > Note: Available as a class method - [Matrix]::Det

    Dot: Return dot product between matrix and one other matrix (with compatible size)
    > Note: Available as a class method - [Matrix]::Dot

    Clone: Return new matrix with identical values as original matrix

    Cofactor: Return cofactor for given row and column index pair
    > Example: $Matrix.Cofactor(0, 1)

    Indexes: Return list of "ij" pairs (useful for iterating through matrix values)
    > Example: (New-Matrix).Indexes() | ForEach-Object { "(i,j) = ($($_[0]),$($_[1]))" }

    Inverse: Return matrix inverse (Note: Det() must return non-zero value)
    > Note: Available as a class method - [Matrix]::Invert

    Multiply: Return result of multiplying matrix by scalar value (ex: 42)
    > Note: Available as a class method - [Matrix]::Multiply

    RemoveColumn: Return matrix with selected column removed

    RemoveRow: Return matrix with selected column removed

    Transpose: Return matrix transpose
    > Note: Available as a class method - [Matrix]::Transpose

    Trace: Return matrix trace (sum of diagonal elements)
    > Note: Available as a class method - [Matrix]::Trace

    *** All methods that return a [Matrix] object provide a "fluent" interface and can be chained ***

    *** All methods are "non destructive" and will return a clone of the original matrix (when applicable) ***

    .PARAMETER Size
    Size = @(number of rows, number of columns)
    .PARAMETER Diagonal
    Add values to matrix along diagonal
    .PARAMETER Unit
    Create unit matrix with size, -Size
    .EXAMPLE
    $Matrix = 1..9 | matrix 3,3
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
    [CmdletBinding()]
    [Alias('matrix')]
    [OutputType([Matrix])]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        [Array] $Values,
        [Parameter(Position = 0)]
        [Array] $Size = @(2, 2),
        [Switch] $Diagonal,
        [Switch] $Identity,
        [Switch] $Unit,
        [Switch] $Custom
    )
    Begin {
        function Update-Matrix {
            Param(
                [Matrix] $Matrix,
                [String] $MatrixType,
                [Array] $Values
            )
            switch ($MatrixType) {
                'Diagonal' {
                    $Values = $Values | Invoke-Flatten
                    $Index = 0
                    foreach ($Pair in $Matrix.Indexes()) {
                        $Row, $Column = $Pair
                        if ($Row -eq $Column) {
                            $Matrix[$Row][$Column] = $Values[$Index]
                            $Index++
                        }
                    }
                    break
                }
                'Custom' {
                    $Matrix.Rows = $Values | Invoke-Flatten
                }
                Default {
                    # Do nothing
                }
            }
        }
        $M, $N = $Size
        $Matrix = New-Object 'Matrix' @($M, $N)
        $MatrixType = Find-FirstTrueVariable 'Custom', 'Diagonal', 'Identity', 'Unit'
        if ($Values.Count -gt 0) {
            Update-Matrix -Values $Values -Matrix $Matrix -MatrixType $MatrixType
        }
    }
    End {
        $Values = $Input
        if ($Values.Count -gt 0) {
            Update-Matrix -Values $Values -Matrix $Matrix -MatrixType $MatrixType
        } else {
            switch ($MatrixType) {
                'Unit' {
                    $Matrix = [Matrix]::Unit($M, $N)
                    break
                }
                'Identity' {
                    $Matrix = [Matrix]::Identity($M)
                    break
                }
                Default {
                    # Do nothing
                }
            }
        }
        $Matrix
    }
}
function Test-Matrix {
    <#
    .SYNOPSIS
    Test if a matrix is one or more of the following:
      - Diagonal
      - Square
      - Symmetric
    .EXAMPLE
    $A = 1..4 | New-Matrix 2,2
    $A | Test-Matrix -Square
    # Returns True
    .EXAMPLE
    $A = 1..4 | New-Matrix 2,2
    $A | Test-Matrix -Square -Diagonal
    # Returns False
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        $Value,
        [Switch] $Diagonal,
        [Switch] $Square,
        [Switch] $Symmetric
    )
    if ($Value.GetType().Name -eq 'Matrix') {
        $Result = $True
        if ($Diagonal) {
            $Result = $Result -and $Value.IsDiagonal()
        }
        if ($Square) {
            $Result = $Result -and $Value.IsSquare()
        }
        if ($Symmetric) {
            $Result = $Result -and $Value.IsSymmetric()
        }
        return $Result
    }
    $False
}