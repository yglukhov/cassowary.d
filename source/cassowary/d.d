#! /usr/bin/env rdmd -debug -unittest -main

import std.stdio;
public import SimplexSolver;
public import Variable;
public import LinearConstraint;
public import LinearEquation;
public import LinearExpression;


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
