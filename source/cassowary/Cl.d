import std.stdio;
import std.math;

import LinearExpression;
import Variable;

public class CL
{
	final static bool fDebugOn = false;
	final static bool fTraceOn = false;
	final static bool fGC = false;

	static void debugprint(string s)
	{
		writeln(s);
	}

	static void traceprint(string s)
	{
		writeln(s);
	}

	static void fnenterprint(string s)
	{
		writeln("* " ~ s);
	}

	static void fnexitprint(string s)
	{
		writeln("- " ~ s);
	}

	public static final byte GEQ = 1;
	public static final byte LEQ = 2;

	public static ClLinearExpression Plus(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.plus(e2);
	}

	public static ClLinearExpression Plus(ClLinearExpression e1, double e2)
	{
		return e1.plus(new ClLinearExpression(e2));
	}

	public static ClLinearExpression Plus(double e1, ClLinearExpression e2)
	{
		return (new ClLinearExpression(e1)).plus(e2);
	}

	public static ClLinearExpression Plus(ClVariable e1, ClLinearExpression e2)
	{
		return (new ClLinearExpression(e1)).plus(e2);
	}

	public static ClLinearExpression Plus(ClLinearExpression e1, ClVariable e2)
	{
		return e1.plus(new ClLinearExpression(e2));
	}

	public static ClLinearExpression Plus(ClVariable e1, double e2)
	{
		return (new ClLinearExpression(e1)).plus(new ClLinearExpression(e2));
	}

	public static ClLinearExpression Plus(double e1, ClVariable e2)
	{
		return (new ClLinearExpression(e1)).plus(new ClLinearExpression(e2));
	}


	public static ClLinearExpression Minus(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.minus(e2);
	}

	public static ClLinearExpression Minus(double e1, ClLinearExpression e2)
	{
		return (new ClLinearExpression(e1)).minus(e2);
	}

	public static ClLinearExpression Minus(ClLinearExpression e1, double e2)
	{
		return e1.minus(new ClLinearExpression(e2));
	}

	public static ClLinearExpression Times(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.times(e2);
	}

	public static ClLinearExpression Times(ClLinearExpression e1, ClVariable e2)
	{
		return e1.times(new ClLinearExpression(e2));
	}

	public static ClLinearExpression Times(ClVariable e1, ClLinearExpression e2)
	{
		return (new ClLinearExpression(e1)).times(e2);
	}

	public static ClLinearExpression Times(ClLinearExpression e1, double e2)
	{
		return e1.times(new ClLinearExpression(e2));
	}

	public static ClLinearExpression Times(double e1, ClLinearExpression e2)
	{
		return (new ClLinearExpression(e1)).times(e2);
	}

	public static ClLinearExpression Times(double n, ClVariable clv)
	{
		return (new ClLinearExpression(clv, n));
	}

	public static ClLinearExpression Times( ClVariable clv, double n)
	{
		return (new ClLinearExpression(clv, n));
	}

	public static ClLinearExpression Divide(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.divide(e2);
	}

	public static bool approx(double a, double b)
	{
		double epsilon = 1.0e-8;
		if (a == 0.0)
		{
			return (abs(b) < epsilon);
		}
		else if (b == 0.0)
		{
			return (abs(a) < epsilon);
		}
		else
		{
			return (abs(a-b) < abs(a) * epsilon);
		}
	}

	public static bool approx(ClVariable clv, double b)
	{
		return approx(clv.value(), b);
	}

	static bool approx(double a, ClVariable clv)
	{
		return approx(a, clv.value());
	}
}
