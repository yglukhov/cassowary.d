cassowary.d
===========

Cassowary constraint solving library for D language.

This is a port of Java version of http://www.cs.washington.edu/research/constraints/cassowary/

This is a work in progress. Syntax sugar like arithmetic operations for expressions is going to
be added later on.

Usage:
```d
import std.stdio;
import cassowary.d;

unittest
{
	auto a = new ClVariable(5);
	auto b = new ClVariable(6);
	auto exp = new ClLinearExpression(a);
	exp = exp.plus(b);
	auto constraint = new ClLinearEquation(exp, new ClLinearExpression(10));
	auto solver = new ClSimplexSolver();
	solver.addConstraint(constraint);
	solver.solve();
	writeln("A: ", a.value(), " B: ", b.value());
}
```
