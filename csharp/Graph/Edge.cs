﻿using System;

namespace Prelude {
    public class Edge : IComparable<Edge> {
        public Guid Id;
        public Node Source;
        public Node Destination;
        public double Weight = 1;
        public virtual bool IsDirected {
            get {
                return false;
            }
        }
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="source"></param>
        /// <param name="destination"></param>
        /// <param name="weight"></param>
        public Edge(Node source, Node destination, double weight = 1) {
            Id = Guid.NewGuid();
            Source = source;
            Destination = destination;
            Weight = weight;
        }
        /// <summary>
        /// Check if an edge contains a node (source or destination)
        /// </summary>
        /// <param name="node"></param>
        /// <returns></returns>
        public bool Contains(Node node) {
            return Source == node || Destination == node;
        }
        /// <summary>
        /// Allows edges to be ordered within lists
        /// </summary>
        /// <param name="other"></param>
        /// <returns>zero (equal) or 1 (not equal)</returns>
        public int CompareTo(Edge other) {
            if (other != null) {
                var sameSource = Source == other.Source;
                var sameDestination = Destination == other.Destination;
                if (sameSource && sameDestination) {
                    return Weight.CompareTo(other.Weight);
                } else {
                    return -1;
                }
            } else {
                throw new ArgumentException("Parameter is not an Edge");
            }
        }
    }
}