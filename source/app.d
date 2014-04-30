#!/usr/bin/env rdmd -debug -unittest -main

import std.stdio;
import cassowary.d;

unittest
{
	auto a = new ClVariable(5);
	auto b = new ClVariable(6);
	auto constraint = new ClLinearEquation(a + b, new ClLinearExpression(10));
	auto solver = new ClSimplexSolver();
	solver.addConstraint(constraint);

	assert(a.value() + b.value() == 10);
}

unittest
{
	auto x = new ClVariable(123);
	auto y = new ClVariable(30);
	auto solver = new ClSimplexSolver();

	auto eq = new ClLinearEquation(x, y / 3 - 5.0);
	solver.addStay(y);
	solver.addConstraint(eq);

	assert(x.value() == y.value() / 3 - 5.0);
	assert(x.value() == 5);
}
