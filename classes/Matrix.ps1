# Need to parameterize class with "id" in order to re-load class during testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude') { 'Test' } else { '' }
if ("Matrix${Id}" -as [Type]) {
  return
}
Add-Type -TypeDefinition @"
    using System;

    public class Matrix${Id} {

        public int[] Order;
        public double[][] Values;

        public Matrix${Id}(int n) {
            this.Order = new int[2];
            this.Order[0] = n;
            this.Order[1] = n;
            this.Values = Matrix${Id}.Create(n,n);
        }
        public Matrix${Id}(int m, int n) {
            this.Order = new int[2];
            this.Order[0] = m;
            this.Order[1] = n;
            this.Values = Matrix${Id}.Create(m,n);
        }
        public static double[][] Create(int m, int n) {
            double[][] result = new double[m][];
            for (var i = 0; i < m; ++i)
                result[i] = new double[n];
            return result;
        }
        public static Matrix${Id} Unit(int size) {
            var temp = new Matrix${Id}(size,size);
            for (var i = 0; i < temp.Order[0]; ++i)
                temp.Values[i][i] = 1;
            return temp;
        }
        public static Matrix${Id} Transpose(Matrix${Id} a) {
            var m = a.Order[0];
            var n = a.Order[1];
            var temp = new Matrix${Id}(n,m);
            for (var row = 0; row < m; ++row)
                for (var col = 0; col < n; ++col)
                    temp.Values[row][col] = a.Values[col][row];
            return temp;
        }
        public Matrix${Id} Add(Matrix${Id} a, Matrix${Id} b) {
            return a;
        }
        public Matrix${Id} Multiply(Matrix${Id} a, Matrix${Id} b) {
            return a;
        }
    }
"@