﻿using Xunit;
using Prelude;

namespace NodeTests {
    public class UnitTests {
        [Fact]
        public void Node_can_be_assigned_a_label() {
            Node n = new Node();
            Assert.Equal(36, n.Id.ToString().Length);
            Assert.Equal("node", n.Label);
            Node m = new Node("test");
            Assert.Equal(36, m.Id.ToString().Length);
            Assert.Equal("test", m.Label);
        }
        [Fact]
        public void Node_will_be_assigned_Id_automatically() {
            var n = new Node();
            Assert.Equal(36, n.Id.ToString().Length);
        }
    }
}