& (Join-Path $PSScriptRoot '_setup.ps1') 'matrix'

Describe 'Matrix class static methods' {
  It -Skip 'can create an NxN multi-dimensional array' {
    $N = 5
    $Matrix = [MatrixTest]::New($N)
    $Matrix.Rows.Count | Should -Be $N
    $Matrix.Rows[0].Count | Should -Be $N
  }
  It -Skip 'can create an MxN multi-dimensional array' {
    $M = 8
    $N = 6
    $Matrix = [MatrixTest]::New($M,$N)
    $Matrix.Rows.Count | Should -Be $M
    $Matrix.Rows[0].Count | Should -Be $N
  }
  It -Skip 'can create unit matrices' {
    $Unit = [MatrixTest]::Unit(1)
    $Unit.Size | Should -Be 1,1
    $Unit.Rows[0] | Should -Be 1
    $Unit = [MatrixTest]::Unit(2)
    $Unit.Size | Should -Be 2,2
    $Unit.Rows[0] | Should -Be 1,1
    $Unit.Rows[1] | Should -Be 1,1
    $Unit = [MatrixTest]::Unit(3)
    $Unit.Size | Should -Be 3,3
    $Unit.Rows[0] | Should -Be 1,1,1
    $Unit.Rows[1] | Should -Be 1,1,1
    $Unit.Rows[2] | Should -Be 1,1,1
  }
  It -Skip 'can create identity matrices' {
    $Identity = [MatrixTest]::Identity(2)
    $Identity.Size | Should -Be 2,2
    $Identity.Rows[0] | Should -Be 1,0
    $Identity.Rows[1] | Should -Be 0,1
    $Identity = [MatrixTest]::Identity(4)
    $Identity.Size | Should -Be 4,4
    $Identity.Rows[0] | Should -Be 1,0,0,0
    $Identity.Rows[1] | Should -Be 0,1,0,0
    $Identity.Rows[2] | Should -Be 0,0,1,0
    $Identity.Rows[3] | Should -Be 0,0,0,1
  }
  It -Skip 'can transpose matrices' {
    $A = [MatrixTest]::New(3)
    $A.Rows = (1..9)
    $Transposed = [MatrixTest]::Transpose($A)
    $Transposed.Rows[0] | Should -Be 1,4,7
    $Transposed.Rows[1] | Should -Be 2,5,8
    $Transposed.Rows[2] | Should -Be 3,6,9
    $Original = [MatrixTest]::Transpose($Transposed)
    $A | Test-Equal $Original | Should -BeTrue
    $A = [MatrixTest]::New(3,2)
    $A.Rows = (1..6)
    $T = [MatrixTest]::Transpose($A)
    $T.Rows[0] | Should -Be 1,3,5
    $T.Rows[1] | Should -Be 2,4,6
  }
  It -Skip 'can add two or more Matrices' {
    $A = [MatrixTest]::Identity(2)
    $Sum = [MatrixTest]::Add($A,$A)
    $Sum.Rows[0] | Should -Be 2,0
    $Sum.Rows[1] | Should -Be 0,2
    $Sum = [MatrixTest]::Add($A,$A,$A)
    $Sum.Rows[0] | Should -Be 3,0
    $Sum.Rows[1] | Should -Be 0,3
  }
  It -Skip 'can calculate the determinant for 2x2 matrices' {
    [MatrixTest]::Det([MatrixTest]::Unit(2)) | Should -Be 0
    [MatrixTest]::Det([MatrixTest]::Identity(2)) | Should -Be 1
    $A = [MatrixTest]::New(2)
    $A.Rows = (1..4)
    [MatrixTest]::Det($A) | Should -Be -2
  }
  It -Skip 'can calculate the determinant for 3x3 matrices' {
    [MatrixTest]::Det([MatrixTest]::Unit(3)) | Should -Be 0
    [MatrixTest]::Det([MatrixTest]::Identity(3)) | Should -Be 1
    $A = [MatrixTest]::New(3)
    $A.Rows[0] = 2,3,-4
    $A.Rows[1] = 0,-4,2
    $A.Rows[2] = 1,-1,5
    [MatrixTest]::Det($A) | Should -Be -46
    $A = [MatrixTest]::New(3)
    $A.Rows[0] = 1,2,3
    $A.Rows[1] = 4,-2,3
    $A.Rows[2] = 2,5,-1
    [MatrixTest]::Det($A) | Should -Be 79
  }
  It -Skip 'can calculate the determinant for 4x4 matrices' {
    [MatrixTest]::Det([MatrixTest]::Unit(4)) | Should -Be 0
    [MatrixTest]::Det([MatrixTest]::Identity(4)) | Should -Be 1
    $A = [MatrixTest]::New(4)
    $A.Rows[0] = 3,-2,-5,4
    $A.Rows[1] = -5,2,8,-5
    $A.Rows[2] = -2,4,7,-3
    $A.Rows[3] = 2,-3,-5,8
    [MatrixTest]::Det($A) | Should -Be -54
    $A = [MatrixTest]::New(4)
    $A.Rows[0] = 5,4,2,1
    $A.Rows[1] = 2,3,1,-2
    $A.Rows[2] = -5,-7,-3,9
    $A.Rows[3] = 1,-2,-1,4
    [MatrixTest]::Det($A) | Should -Be 38
  }
  It -Skip 'can calculate the determinant for matrices larger than 4x4' {
    [MatrixTest]::Det([MatrixTest]::Unit(10)) | Should -Be 0
    [MatrixTest]::Det([MatrixTest]::Identity(10)) | Should -Be 1
    $A = [MatrixTest]::New(6)
    $A.Rows[0] = 12,22,14,17,20,10
    $A.Rows[1] = 16,-4,7,1,-2,15
    $A.Rows[2] = 10,-3,-2,3,-2,8
    $A.Rows[3] = 7,12,8,9,11,6
    $A.Rows[4] = 11,2,4,-8,1,9
    $A.Rows[5] = 24,6,6,3,4,22
    [MatrixTest]::Det($A) | Should -Be 12228
  }
  It -Skip 'can produce the dot product of two matrices' {
    $Identity = [MatrixTest]::Identity(2)
    $A = $Identity.Clone()
    $A.Rows[1][1] = 0
    $B = $Identity.Clone()
    $B.Rows[0][0] = 0
    $Product = [MatrixTest]::Dot($A,$B)
    $Product.Size | Should -Be 2,2
    $Product.Rows[0] | Should -Be 0,0 -Because 'the dot product of orthogonal matrices should be zero'
    $Product.Rows[1] | Should -Be 0,0 -Because 'the dot product of orthogonal matrices should be zero'
    $A.Rows[0] = 1,2
    $A.Rows[1] = 3,4
    $B.Rows[0] = 1,1
    $B.Rows[1] = 0,2
    $Product = [MatrixTest]::Dot($A,$B)
    $Product.Rows[0] | Should -Be 1,5
    $Product.Rows[1] | Should -Be 3,11
    $Product = [MatrixTest]::Dot($B,$A)
    $Product.Rows[0] | Should -Be 4,6 -Because 'the dot product is not commutative'
    $Product.Rows[1] | Should -Be 6,8 -Because 'the dot product is not commutative'
    $A = [MatrixTest]::New(1,2)
    $A.Rows[0] = 2,1
    $B = [MatrixTest]::New(2,3)
    $B.Rows[0] = 1,-2,0
    $B.Rows[1] = 4,5,-3
    $Product = [MatrixTest]::Dot($A,$B)
    $Product.Size | Should -Be 1,3 -Because 'dot product supports matrices of different sizes'
    $Product.Rows[0] | Should -Be 6,1,-3
    $A = [MatrixTest]::New(2)
    $A.Rows[0] = 2,5
    $A.Rows[1] = 1,3
    $B = [MatrixTest]::New(2)
    $B.Rows[0] = 3,-5
    $B.Rows[1] = -1,2
    [MatrixTest]::Dot($A,$B) | Test-Equal $Identity | Should -BeTrue -Because '$A and $B are invertible'
  }
  It -Skip 'can multiply matrices by a scalar constant' {
    $A = [MatrixTest]::Identity(2)
    [MatrixTest]::Add($A,$A,$A) | Test-Equal ([MatrixTest]::Multiply($A,3)) | Should -BeTrue
    $Product = [MatrixTest]::Multiply($A,7)
    $Product.Rows[0] | Should -Be 7,0
    $Product.Rows[1] | Should -Be 0,7
  }
  It -Skip 'can calulate the inverse of a given matrix' {
    $A = [MatrixTest]::New(3);
    $A.Rows[0] = 1,2,3
    $A.Rows[1] = 2,3,4
    $A.Rows[2] = 1,5,7
    $Inverse = [MatrixTest]::Invert($A)
    $Inverse.Rows[0] | Should -Be 0.5,0.5,-0.5
    $Inverse.Rows[1] | Should -Be -5,2,1
    $Inverse.Rows[2] | Should -Be 3.5,-1.5,-0.5
    [MatrixTest]::Dot($A,$Inverse) | Test-Equal ([MatrixTest]::Identity(3)) | Should -BeTrue -Because 'the dot product of a matrix and its inverse is the identity matrix'
  }
  It 'can return the trace of a matrix' {
    $A = [MatrixTest]::New(3);
    $A.Rows = 1..9
    [MatrixTest]::Trace($A) | Should -Be 15
  }
}
Describe 'Matrix class instance' {
  It -Skip 'does not allow for setting matrix Size' {
    $A = [MatrixTest]::Identity(3)
    $A.Size | Should -Be 3,3
    { $A.Size = 2,2,2 } | Should -Throw
  }
  It -Skip 'will ensure row and column data adheres to restrictions of matrix size' {
    $A = [MatrixTest]::New(3)
    $A.Rows = (1..9)
    $A.Rows[0] | Should -Be 1,2,3
    $A.Rows[1] | Should -Be 4,5,6
    $A.Rows[2] | Should -Be 7,8,9
    $A = [MatrixTest]::New(2)
    $A.Rows = (1..9)
    $A.Rows[0] | Should -Be  1,2
    $A.Rows[1] | Should -Be  3,4 -Because 'row length will be maintained by truncating input'
    $A = [MatrixTest]::New(2)
    $A.Rows = 1,2,3
    $A.Rows[0] | Should -Be  1,2
    $A.Rows[1] | Should -Be  3,0
    $A = [MatrixTest]::New(2, 3)
    $A.Rows = (1..6)
    $A.Rows[0] | Should -Be  1,2,3
    $A.Rows[1] | Should -Be  4,5,6 -Because 'non-square sizes should be supported'
  }
  It -Skip 'provides iterator of index element index pairs' {
    $A = [MatrixTest]::New(3)
    $A.Indexes() | Should -HaveCount 9
  }
  It -Skip 'can create clones' {
    $A = [MatrixTest]::New(2)
    $A.Rows = (1..4)
    $Clone = $A.Clone()
    $Clone.Rows[0] | Should -Be 1,2
    $Clone.Rows[1] | Should -Be 3,4
  }
  It -Skip 'can remove rows' {
    $A = [MatrixTest]::New(3)
    $A.Rows = (1..9)
    $Edited = $A.RemoveRow(0)
    $Edited.Size | Should -Be 2,3
    $Edited.Rows[0] | Should -Be 4,5,6
    $Edited.Rows[1] | Should -Be 7,8,9
    $Edited = $A.RemoveRow(1)
    $Edited.Size | Should -Be 2,3
    $Edited.Rows[0] | Should -Be 1,2,3
    $Edited.Rows[1] | Should -Be 7,8,9
    $Edited = $A.RemoveRow(2)
    $Edited.Size | Should -Be 2,3
    $Edited.Rows[0] | Should -Be 1,2,3
    $Edited.Rows[1] | Should -Be 4,5,6
    $Edited = $A.RemoveRow(2).RemoveColumn(0)
  }
  It -Skip 'can remove columns' {
    $A = [MatrixTest]::New(3)
    $A.Rows = (1..9)
    $Edited = $A.RemoveColumn(0)
    $Edited.Size | Should -Be 3,2
    $Edited.Rows[0] | Should -Be 2,3
    $Edited.Rows[1] | Should -Be 5,6
    $Edited.Rows[2] | Should -Be 8,9
    $Edited = $A.RemoveColumn(1)
    $Edited.Size | Should -Be 3,2
    $Edited.Rows[0] | Should -Be 1,3
    $Edited.Rows[1] | Should -Be 4,6
    $Edited.Rows[2] | Should -Be 7,9
    $Edited = $A.RemoveColumn(2)
    $Edited.Size | Should -Be 3,2
    $Edited.Rows[0] | Should -Be 1,2
    $Edited.Rows[1] | Should -Be 4,5
    $Edited.Rows[2] | Should -Be 7,8
    $Edited = $A.RemoveColumn(0).RemoveRow(0)
    $Edited.Size | Should -Be 2,2
    $Edited.Rows[0] | Should -Be 5,6
    $Edited.Rows[1] | Should -Be 8,9
  }
  It -Skip 'can be converted to string output' {
    $A = [MatrixTest]::New(2)
    $A.Rows = (1..4)
    $A.ToString() | ConvertTo-Json | Should -Be '"1,2\r\n3,4"'
    [MatrixTest]::Unit(3).ToString() | ConvertTo-Json | Should -Be '"1,1,1\r\n1,1,1\r\n1,1,1"'
  }
}
Describe 'Matrix helper functions' {
  It 'can provide wrapper for matrix creation' {
    $A = 1..9 | New-Matrix 3,3
    $A.Size | Should -Be 3,3
    $A.Rows[0] | Should -Be 1,2,3
    $A.Rows[1] | Should -Be 4,5,6
    $A.Rows[2] | Should -Be 7,8,9
    $A = New-Matrix -Size 3,3 -Values (1..9)
    $A.Size | Should -Be 3,3
    $A.Rows[0] | Should -Be 1,2,3
    $A.Rows[1] | Should -Be 4,5,6
    $A.Rows[2] | Should -Be 7,8,9
    $A = New-Matrix
    $A.Size | Should -Be 2,2 -Because '2x2 is the default matrix size'
    $A.Rows[0] | Should -Be 0,0 -Because 'an empty matrix should be created by default'
    $A.Rows[1] | Should -Be 0,0 -Because 'an empty matrix should be created by default'
    $A = @(1,2,3,@(4,5,6)) | New-Matrix 2,3
    $A = 1..6 | New-Matrix 2,3
    $A.Rows[0] | Should -Be 1,2,3 -Because 'function accepts non-square sizes'
    $A.Rows[1] | Should -Be 4,5,6 -Because 'values array should be flattened'
  }
  It 'can create diagonal matrices' {
    $A = 1..3 | New-Matrix 3,3 -Diagonal
    $A.Size | Should -Be 3,3
    $A.Rows[0] | Should -Be 1,0,0
    $A.Rows[1] | Should -Be 0,2,0
    $A.Rows[2] | Should -Be 0,0,3
    $A = New-Matrix -Values (1..3) -Size 3,3 -Diagonal
    $A.Size | Should -Be 3,3
    $A.Rows[0] | Should -Be 1,0,0
    $A.Rows[1] | Should -Be 0,2,0
    $A.Rows[2] | Should -Be 0,0,3
  }
  It 'can test if a matrix is diagonal' {
    1,0,0,
    0,2,0,
    0,0,3 | New-matrix 3,3 | Test-DiagonalMatrix | Should -BeTrue
    1,0,0,
    2,2,0,
    3,0,3 | New-Matrix 3,3 | Test-DiagonalMatrix | Should -BeFalse -Because 'second and third rows have non-zero elements off the main diagonal'
    1,0,0,
    0,2,1,
    0,0,3 | New-Matrix 3,3 | Test-DiagonalMatrix | Should -BeFalse -Because 'second row has a non-zero element off the main diagonal'
    1,0,
    0,1 | New-Matrix | Test-DiagonalMatrix | Should -BeTrue
    1,0,0,
    0,2,0 | New-matrix 2,3 | Test-DiagonalMatrix | Should -BeFalse -Because 'only square matrices can be diagonal'
    1,0,2,
    0,2,2 | New-matrix 2,3 | Test-DiagonalMatrix | Should -BeFalse -Because 'only square matrices can be diagonal'
  }
  It 'can test if a matrix is square' {
    (1..4) | New-Matrix | Test-SquareMatrix | Should -BeTrue
    (1..9) | New-Matrix 3,3 | Test-SquareMatrix | Should -BeTrue
    (1..6) | New-Matrix 3,2 | Test-SquareMatrix | Should -BeFalse -Because 'the # of rows and # of columns are different'
  }
  It 'can test if a matrix is symmetric' {
    1,2,3,
    2,1,4,
    3,4,1 | New-Matrix 3,3 | Test-SymmetricMatrix | Should -BeTrue
    (1..9) | New-Matrix 3,3 | Test-SymmetricMatrix | Should -BeFalse -Because 'elements off main diagonal are not equal'
    1,1,1,1 | New-Matrix | Test-SymmetricMatrix | Should -BeTrue
    1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    0,0,0,1 | New-Matrix 4,4 | Test-SymmetricMatrix | Should -BeTrue -Because 'diagonal matrices are symmetric'
    1,0,0,
    2,2,0,
    3,0,3 | New-Matrix 3,3 | Test-SymmetricMatrix | Should -BeFalse
    1,0,0,
    0,2,1,
    0,0,3 | New-Matrix 2,3 | Test-SymmetricMatrix | Should -BeFalse
    1,0,0,
    0,0,3 | New-Matrix 2,3 | Test-SymmetricMatrix | Should -BeFalse -Because 'only square matrices can be symmetric'
  }
}