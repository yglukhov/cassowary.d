cassowary.d
===========

Cassowary constraint solving library for D language.

This is a port of Java version of http://www.cs.washington.edu/research/constraints/cassowary/

Usage:
```d
import std.stdio;
import cassowary.d;

unittest
{
	auto x = new ClVariable(123);
	auto y = new ClVariable(30);
	auto solver = new ClSimplexSolver();

	auto eq = new ClLinearEquation(x, y / 3 - 5);
	solver.addStay(y);
	solver.addConstraint(eq);

	assert(x.value() == y.value() / 3 - 5);
	assert(x.value() == 5);
}
```
