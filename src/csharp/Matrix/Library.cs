﻿using System;
using System.Collections.Generic;
using System.Linq;

public class Matrix {
    public int[] Size {
        get;
        private set;
    }
    private double[][] _Rows;
    public double[][] Rows {
        get {
            return _Rows;
        }
        set {
            int rows = this.Size[0], cols = this.Size[1];
            if (value.Length > rows) {
                var limit = Math.Min(value.Length, (rows * cols));
                for (var i = 0; i < limit; ++i) {
                    int row = (int)(Math.Floor((double)(i / cols)));
                    int col = i % cols;
                    _Rows[row][col] = value[i][0];
                }
            } else {
                double[][] temp = Matrix.Create(rows, cols);
                for (var row = 0; row < rows; ++row)
                    temp[row] = (double[])value[row].Take(cols).ToArray();
                _Rows = temp;
            }
        }
    }
    public Matrix(int n) {
        this.Size = new int[] { n, n };
        this.Rows = Matrix.Create(n, n);
    }
    public Matrix(int rows, int cols) {
        this.Size = new int[] { rows, cols };
        this.Rows = Matrix.Create(rows, cols);
    }
    public static double[][] Create(int rows, int cols) {
        double[][] result = new double[rows][];
        for (int i = 0; i < rows; ++i)
            result[i] = new double[cols];
        return result;
    }
    public static Matrix Unit(int n) {
        var temp = new Matrix(n);
        foreach (var index in temp.Indexes()) {
            int i = index[0], j = index[1];
            temp.Rows[i][j] = 1;
        }
        return temp;
    }
    public static Matrix Identity(int n) {
        var temp = new Matrix(n);
        for (int i = 0; i < n; ++i)
            temp.Rows[i][i] = 1;
        return temp;
    }
    public static Matrix Transpose(Matrix a) {
        var temp = new Matrix(a.Size[1], a.Size[0]);
        foreach (var index in a.Indexes()) {
            int i = index[0], j = index[1];
            temp.Rows[j][i] = a.Rows[i][j];
        }
        return temp;
    }
    public static Matrix Add(params Matrix[] addends) {
        var size = addends[0].Size;
        var sum = new Matrix(size[0], size[1]);
        foreach (Matrix matrix in addends)
            foreach (var index in matrix.Indexes()) {
                int i = index[0], j = index[1];
                sum.Rows[i][j] += matrix.Rows[i][j];
            }
        return sum;
    }
    public static Matrix Adj(Matrix a) {
        Matrix temp = a.Clone();
        foreach (var index in temp.Indexes()) {
            int i = index[0], j = index[1];
            temp.Rows[i][j] = a.Cofactor(i, j);
        }
        return Matrix.Transpose(temp);
    }
    public static double Det(Matrix a) {
        int rows = a.Size[0];
        switch (rows) {
            case 1:
                return a.Rows[0][0];
            case 2:
                return (a.Rows[0][0] * a.Rows[1][1]) - (a.Rows[0][1] * a.Rows[1][0]);
            default:
                double sum = 0;
                for (int i = 0; i < rows; ++i)
                    sum += (a.Rows[0][i] * a.Cofactor(0, i));
                return sum;
        }
    }
    public static Matrix Dot(Matrix a, Matrix b) {
        int m = a.Size[0], p = a.Size[1], n = b.Size[1];
        var product = new Matrix(m, n);
        foreach (var index in product.Indexes()) {
            int i = index[0], j = index[1];
            double sum = 0;
            for (int k = 0; k < p; ++k) {
                sum += (a.Rows[i][k] * b.Rows[k][j]);
            }
            product.Rows[i][j] = sum;
        }
        return product;
    }
    public static Matrix Invert(Matrix a) {
        Matrix adjugate = Matrix.Adj(a);
        double det = Matrix.Det(a);
        return Matrix.Multiply(adjugate, (1 / det));
    }
    public static Matrix Multiply(Matrix a, double k) {
        Matrix clone = a.Clone();
        foreach (var index in clone.Indexes()) {
            int i = index[0], j = index[1];
            clone.Rows[i][j] *= k;
        }
        return clone;
    }
    public static double Trace(Matrix a) {
        double trace = 0;
        foreach (var index in a.Indexes()) {
            int i = index[0], j = index[1];
            if (i == j) {
                trace += a.Rows[i][j];
            }
        }
        return trace;
    }
    public Matrix Clone() {
        Matrix
        original = this;
        int rows = original.Size[0], cols = original.Size[1];
        Matrix
        clone = new Matrix
        (rows, cols);
        foreach (var index in clone.Indexes()) {
            int i = index[0], j = index[1];
            clone.Rows[i][j] = original.Rows[i][j];
        }
        return clone;
    }
    public double Cofactor(int i = 0, int j = 0) {
        return (Math.Pow(-1, i + j) * Matrix.Det(this.RemoveRow(i).RemoveColumn(j)));
    }
    public List<int[]> Indexes(int offset = 0) {
        int rows = this.Size[0], cols = this.Size[1];
        List<int[]> pairs = new List<int[]>();
        for (var i = 0; i < rows; ++i)
            for (var j = 0; j < cols; ++j) {
                int[] pair = { i + offset, j + offset };
                pairs.Add(pair);
            }
        return pairs;
    }
    public Matrix RemoveColumn(int index) {
        Matrix
        original = this.Clone();
        int rows = original.Size[0], cols = original.Size[1];
        if (index < 0 || index >= cols) {
            return original;
        } else {
            var temp = new Matrix
            (rows, cols - 1);
            for (var i = 0; i < rows; ++i)
                for (var j = 0; j < index; ++j)
                    temp.Rows[i][j] = original.Rows[i][j];
            for (var i = 0; i < rows; ++i)
                for (var j = index; j < cols - 1; ++j)
                    temp.Rows[i][j] = original.Rows[i][j + 1];
            return temp;
        }
    }
    public Matrix RemoveRow(int index) {
        Matrix
        original = this.Clone();
        int rows = original.Size[0], cols = original.Size[1];
        if (index < 0 || index >= rows) {
            return original;
        } else {
            var temp = new Matrix
            (rows - 1, cols);
            for (var i = 0; i < index; ++i)
                for (var j = 0; j < cols; ++j)
                    temp.Rows[i][j] = original.Rows[i][j];
            for (var i = index; i < rows - 1; ++i)
                for (var j = 0; j < cols; ++j)
                    temp.Rows[i][j] = original.Rows[i + 1][j];
            return temp;
        }
    }
    public override string ToString() {
        Matrix
        matrix = this;
        int rank = matrix.Size[0];
        var rows = new string[rank];
        for (var i = 0; i < rank; ++i)
            rows[i] = string.Join(",", matrix.Rows[i]);
        return string.Join("\r\n", rows);
    }
}