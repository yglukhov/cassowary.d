import std.conv;
import Variable;

public class ClPoint
{
	this(double x, double y)
	{
		_clv_x = new ClVariable(x);
		_clv_y = new ClVariable(y);
	}

	this(double x, double y, int a)
	{
		_clv_x = new ClVariable("x" ~ a.to!string(), x);
		_clv_y = new ClVariable("y" ~ a.to!string(), y);
	}

	this(ClVariable clv_x, ClVariable clv_y)
	{ _clv_x = clv_x; _clv_y = clv_y; }

	public ClVariable X()
	{
		return _clv_x;
	}

	public ClVariable Y()
	{
		return _clv_y;
	}

	// use only before adding into the solver
	public void SetXY(double x, double y)
	{
		_clv_x.set_value(x); _clv_y.set_value(y);
	}

	public void SetXY(ClVariable clv_x, ClVariable clv_y)
	{
		_clv_x = clv_x; _clv_y = clv_y;
	}

	public double Xvalue()
	{
		return X().value();
	}

	public double Yvalue()
	{
		return Y().value();
	}

	public override string toString()
	{
		return "(" ~ _clv_x.toString() ~ ", " ~ _clv_y.toString() ~ ")";
	}

	private ClVariable _clv_x;

	private ClVariable _clv_y;
}
