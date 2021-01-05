using Xunit;
using FsCheck;
using FsCheck.Xunit;
using System;
using Prelude;

namespace MatrixTests {
    public class UnitTests {
        [Property]
        public Property NxN_Matrix_Has_N_Rows_and_N_Columns(PositiveInt n) {
            var size = n.Get;
            var matrix = new Matrix(size);
            return (matrix.Size[0] == matrix.Size[1]).Label("NxN matrix has square shape")
                .And(matrix.Rows.Length == matrix.Rows[0].Length).Label("NxN matrix has same number of rows and columns")
                .And(matrix.Size[0] == matrix.Rows.Length).Label("NxN is characterized by N rows and N columns");
        }
        [Property]
        public Property MxN_Matrix_Has_M_Rows_and_N_Columns(PositiveInt m, PositiveInt n) {
            var rows = m.Get;
            var cols = n.Get;
            var matrix = new Matrix(rows, cols);
            return (matrix.Size[0] == rows && (matrix.Rows.Length == rows)).Label("MxN matrix has M rows")
                .And(matrix.Size[1] == cols && (matrix.Rows[0].Length == cols)).Label("MxN matrix has N columns");
        }
        [Property]
        public Property Identity_Matrix_is_Square(PositiveInt n) {
            var size = n.Get;
            var matrix = new Matrix(size);
            var rows = matrix.Size[0];
            var cols = matrix.Size[1];
            return (rows == size && rows == cols).Label("Identity matrix has same number of rows and columns");
        }
        [Property]
        [Trait("Category", "Determinant")]
        public Property Multiplying_Row_By_K_Multiplies_Det_By_K(PositiveInt k, PositiveInt a, PositiveInt b, PositiveInt c, PositiveInt d) {
            var A = new Matrix(2);
            var B = new Matrix(2);
            A.Rows[0] = new double[] { a.Get, b.Get };
            A.Rows[1] = new double[] { c.Get, d.Get };
            B.Rows[0] = new double[] { (k.Get * a.Get), (k.Get * b.Get) };
            B.Rows[1] = new double[] { c.Get, d.Get };
            return (Matrix.Det(B) == (k.Get * Matrix.Det(A))).Label("Multiply row in A by k ==> k * Det(A)");
        }
        [Property]
        [Trait("Category", "Determinant")]
        public Property Determinants_Are_Invariant_Under_Matrix_Transposition(PositiveInt a, PositiveInt b, PositiveInt c, PositiveInt d) {
            var A = new Matrix(2);
            A.Rows[0] = new double[] { a.Get, b.Get };
            A.Rows[1] = new double[] { c.Get, d.Get };
            return (Matrix.Det(A) == Matrix.Det(Matrix.Transpose(A))).Label("Determinant is invariant under matrix transpose");
        }
        [Property]
        [Trait("Category", "Determinant")]
        public Property Two_Identical_Rows_Makes_Determinant_Zero(PositiveInt a, PositiveInt b, PositiveInt c, PositiveInt d, PositiveInt e, PositiveInt f) {
            var A = new Matrix(3);
            A.Rows[0] = new double[] { a.Get, b.Get, c.Get };
            A.Rows[1] = new double[] { d.Get, e.Get, f.Get };
            A.Rows[2] = new double[] { a.Get, b.Get, c.Get };
            return (Matrix.Det(A) == 0).Label("A has two identical rows ==> Det(A) == 0");
        }
        [Theory]
        [InlineData(1)]
        [InlineData(2)]
        [InlineData(3)]
        public void Can_Create_Unit_Matrix(int N) {
            var unit = Matrix.Unit(N);
            Assert.Equal(new int[] { N, N }, unit.Size);
            var expected = new double[N];
            Array.Fill(expected, 1);
            foreach (double[] Row in unit.Rows) {
                Assert.Equal(expected, Row);
            }
        }
        [Fact]
        public void Can_Create_Identity_Matrix() {
            var identity2 = Matrix.Identity(2);
            Assert.Equal(new double[] { 1, 0 }, identity2.Rows[0]);
            Assert.Equal(new double[] { 0, 1 }, identity2.Rows[1]);
            var identity4 = Matrix.Identity(4);
            Assert.Equal(new double[] { 1, 0, 0, 0 }, identity4.Rows[0]);
            Assert.Equal(new double[] { 0, 1, 0, 0 }, identity4.Rows[1]);
            Assert.Equal(new double[] { 0, 0, 1, 0 }, identity4.Rows[2]);
            Assert.Equal(new double[] { 0, 0, 0, 1 }, identity4.Rows[3]);
        }
        [Fact]
        public void Can_Transpose_NxN_Matrices() {
            var A = new Matrix(3);
            double[,] rows = new double[3, 3] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            var T = Matrix.Transpose(A);
            Assert.Equal(new double[] { 1, 4, 7 }, T.Rows[0]);
            Assert.Equal(new double[] { 2, 5, 8 }, T.Rows[1]);
            Assert.Equal(new double[] { 3, 6, 9 }, T.Rows[2]);
            var B = Matrix.Transpose(T);
            Assert.Equal(new double[] { 1, 2, 3 }, B.Rows[0]);
            Assert.Equal(new double[] { 4, 5, 6 }, B.Rows[1]);
            Assert.Equal(new double[] { 7, 8, 9 }, B.Rows[2]);
        }
        [Fact]
        public void Can_Transpose_MxN_Matrices() {
            var A = new Matrix(2, 3);
            double[,] rows = new double[2, 3] {
                { 1, 2, 3 },
                { 4, 5, 6 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i,j];
            }
            var T = Matrix.Transpose(A);
            Assert.Equal(new double[] { 1, 4 }, T.Rows[0]);
            Assert.Equal(new double[] { 2, 5 }, T.Rows[1]);
            Assert.Equal(new double[] { 3, 6 }, T.Rows[2]);
            var B = Matrix.Transpose(T);
            Assert.Equal(new double[] { 1, 2, 3 }, B.Rows[0]);
            Assert.Equal(new double[] { 4, 5, 6 }, B.Rows[1]);
        }
        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        public void Can_Add_Matrices(int N) {
            var sum = new Matrix(N);
            var unit = Matrix.Unit(N);
            for (int i = 0; i < N; ++i) {
                sum = Matrix.Add(sum, unit);
            }
            var expected = new double[N];
            Array.Fill(expected,N);
            foreach (var Row in sum.Rows)
                Assert.Equal(expected, Row);
        }
        [Fact]
        public void Can_Calculate_Dot_Product_of_Two_NxN_Matrices() {
            var A = Matrix.Identity(2);
            A.Rows[1][1] = 0;
            var B = Matrix.Identity(2);
            B.Rows[0][0] = 0;
            var product = Matrix.Dot(A, B);
            Assert.Equal(new int[] { 2, 2 }, product.Size);
            Assert.Equal(new double[] { 0, 0 }, product.Rows[0]);
            Assert.Equal(new double[] { 0, 0 }, product.Rows[1]);
            double[,] rows = new double[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            rows = new double[,] {
                { 1, 1 },
                { 0, 2 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B.Rows[i][j] = rows[i, j];
            }
            product = Matrix.Dot(A, B);
            Assert.Equal(new double[] { 1, 5 }, product.Rows[0]);
            Assert.Equal(new double[] { 3, 11 }, product.Rows[1]);
            product = Matrix.Dot(B, A);
            Assert.Equal(new double[] { 4, 6 }, product.Rows[0]);
            Assert.Equal(new double[] { 6, 8 }, product.Rows[1]);
        }
        [Fact]
        public void Can_Calculate_Dot_Product_of_Two_MxN_Matrices() {
            var A = new Matrix(1, 2);
            var B = new Matrix(2, 3);
            double[,] rowsA = new double[,] {
                { 2, 1 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rowsA[i, j];
            }
            double[,] rowsB = new double[,] {
                { 1, -2, 0 },
                { 4, 5, -3 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B.Rows[i][j] = rowsB[i, j];
            }
            var product = Matrix.Dot(A, B);
            Assert.Equal(new int[] { 1, 3 }, product.Size);
            Assert.Equal(new double[] { 6, 1, -3 }, product.Rows[0]);
        }
        [Fact]
        public void Can_Verify_the_Dot_Product_of_a_Matrix_and_its_Inverse() {
            var A = new Matrix(2);
            var B = new Matrix(2);
            double[,] rowsA = new double[,] {
                { 2, 5 },
                { 1, 3 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rowsA[i, j];
            }
            double[,] rowsB = new double[,] {
                { 3, -5 },
                { -1, 2 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B.Rows[i][j] = rowsB[i,j];
            }
            var product = Matrix.Dot(A, B);
            Assert.Equal(new int[] { 2, 2 }, product.Size);
            Assert.Equal(Matrix.Identity(2).Rows, product.Rows);
        }
        [Theory]
        [InlineData(1)]
        [InlineData(7)]
        public void Can_Multiply_Matrix_by_Scalar_Constant(int k) {
            var sum = new Matrix(2);
            var identity = Matrix.Identity(2);
            for (int i = 0; i < k; ++i) {
                sum = Matrix.Add(sum,identity);
            }
            var A = Matrix.Identity(2);
            var product = Matrix.Multiply(A, k);
            Assert.Equal(sum.Rows, product.Rows);
            Assert.Equal(new double[] { k, 0 }, product.Rows[0]);
            Assert.Equal(new double[] { 0, k }, product.Rows[1]);
        }
        [Fact]
        public void Can_Calculate_the_Inverse_of_a_Matrix() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 2, 3, 4 },
                { 1, 5, 7 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i,j];
            }
            var inverse = Matrix.Invert(A);
            Assert.Equal(new double[] { 0.5, 0.5, -0.5 }, inverse.Rows[0]);
            Assert.Equal(new double[] { -5, 2, 1 }, inverse.Rows[1]);
            Assert.Equal(new double[] { 3.5, -1.5, -0.5 }, inverse.Rows[2]);
            Assert.Equal(Matrix.Identity(3).Rows, Matrix.Dot(A, inverse).Rows);
        }
        [Fact]
        public void Can_Calculate_Matrix_Trace() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            Assert.Equal(15, Matrix.Trace(A));
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_Create_Clones() {
            var A = new Matrix(2);
            double[,] rows = new double[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i,j];
            }
            var B = A.Clone();
            Assert.Equal(new double[] { 1, 2 }, B.Rows[0]);
            Assert.Equal(new double[] { 3, 4 }, B.Rows[1]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_Remove_Rows() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            var edited = A.RemoveRow(0);
            Assert.Equal(new int[] { 2, 3 }, edited.Size);
            Assert.Equal(new double[] { 4, 5, 6 }, edited.Rows[0]);
            Assert.Equal(new double[] { 7, 8, 9 }, edited.Rows[1]);
            edited = A.RemoveRow(1);
            Assert.Equal(new int[] { 2, 3 }, edited.Size);
            Assert.Equal(new double[] { 1, 2, 3 }, edited.Rows[0]);
            Assert.Equal(new double[] { 7, 8, 9 }, edited.Rows[1]);
            edited = A.RemoveRow(2);
            Assert.Equal(new int[] { 2, 3 }, edited.Size);
            Assert.Equal(new double[] { 1, 2, 3 }, edited.Rows[0]);
            Assert.Equal(new double[] { 4, 5, 6 }, edited.Rows[1]);
            edited = A.RemoveRow(2).RemoveColumn(0);
            Assert.Equal(new int[] { 2, 2 }, edited.Size);
            Assert.Equal(new double[] { 2, 3 }, edited.Rows[0]);
            Assert.Equal(new double[] { 5, 6 }, edited.Rows[1]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_Remove_Columns() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            var edited = A.RemoveColumn(0);
            Assert.Equal(new int[] { 3, 2 }, edited.Size);
            Assert.Equal(new double[] { 2, 3 }, edited.Rows[0]);
            Assert.Equal(new double[] { 5, 6 }, edited.Rows[1]);
            Assert.Equal(new double[] { 8, 9 }, edited.Rows[2]);
            edited = A.RemoveColumn(1);
            Assert.Equal(new int[] { 3, 2 }, edited.Size);
            Assert.Equal(new double[] { 1, 3 }, edited.Rows[0]);
            Assert.Equal(new double[] { 4, 6 }, edited.Rows[1]);
            Assert.Equal(new double[] { 7, 9 }, edited.Rows[2]);
            edited = A.RemoveColumn(2);
            Assert.Equal(new int[] { 3, 2 }, edited.Size);
            Assert.Equal(new double[] { 1, 2 }, edited.Rows[0]);
            Assert.Equal(new double[] { 4, 5 }, edited.Rows[1]);
            Assert.Equal(new double[] { 7, 8 }, edited.Rows[2]);
            edited = A.RemoveColumn(0).RemoveRow(0);
            Assert.Equal(new int[] { 2, 2 }, edited.Size);
            Assert.Equal(new double[] { 5, 6 }, edited.Rows[0]);
            Assert.Equal(new double[] { 8, 9 }, edited.Rows[1]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_Be_Converted_to_String() {
            var A = new Matrix(2);
            double[,] rows = new double[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            string output = A.ToString();
            Assert.Equal("1,2\r\n3,4", output);
        }
        [Fact]
        [Trait("Category", "Determinant")]
        public void Can_Calculate_Determinant_for_2x2_Matrices() {
            Assert.Equal(0, Matrix.Det(Matrix.Unit(2)));
            var A = new Matrix(2);
            double[,] rows = new double[2, 2] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            Assert.Equal(-2, Matrix.Det(A));
        }
        [Theory]
        [InlineData(3)]
        [Trait("Category", "Determinant")]
        public void Can_Calculate_Determinant_for_3x3_Matrices(int N) {
            Assert.Equal(0, Matrix.Det(Matrix.Unit(N)));
            Assert.Equal(1, Matrix.Det(Matrix.Identity(N)));
            var A = new Matrix(N);
            double[,] rows = new double[,] {
                { 2, 3, -4 },
                { 0, -4, 2 },
                { 1, -1, 5 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            Assert.Equal(-46, Matrix.Det(A));
            A = new Matrix(N);
            rows = new double[,] {
                { 1, 2, 3 },
                { 4, -2, 3 },
                { 2, 5, -1 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            Assert.Equal(79, Matrix.Det(A));
        }
        [Theory]
        [InlineData(4)]
        [Trait("Category", "Determinant")]
        public void Can_Calculate_Determinant_for_4x4_Matrices(int N) {
            Assert.Equal(0, Matrix.Det(Matrix.Unit(N)));
            Assert.Equal(1, Matrix.Det(Matrix.Identity(N)));
            var A = new Matrix(N);
            double[,] rows = new double[,] {
                { 3, -2, -5, 4 },
                { -5, 2, 8, -5 },
                { -2, 4, 7, -3 },
                { 2, -3, -5, 8 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            Assert.Equal(-54, Matrix.Det(A));
            A = new Matrix(N);
            rows = new double[,] {
                { 5, 4, 2, 1 },
                { 2, 3, 1, -2 },
                { -5, -7, -3, 9 },
                { 1, -2, -1, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            Assert.Equal(38, Matrix.Det(A));
        }
        [Theory]
        [InlineData(6)]
        [Trait("Category", "Determinant")]
        [Trait("Category", "LongDuration")]
        public void Can_Calculate_Determinant_for_Matrices_Larger_than_4x4(int N) {
            Assert.Equal(0, Matrix.Det(Matrix.Unit(10)));
            Assert.Equal(1, Matrix.Det(Matrix.Identity(10)));
            var A = new Matrix(N);
            double[,] rows = new double[,] {
                { 12, 22, 14, 17, 20, 10 },
                { 16, -4, 7, 1,-2, 15 },
                { 10, -3, -2, 3, -2, 8 },
                { 7, 12, 8, 9, 11, 6 },
                { 11, 2, 4, -8, 1, 9 },
                { 24, 6, 6, 3, 4, 22 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            Assert.Equal(12228, Matrix.Det(A));
        }
    }
}