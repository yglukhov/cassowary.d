module cassowary.SymbolicWeight;

import std.conv;

public class ClSymbolicWeight
{
	this(int cLevels)
	{
		_values = new double[cLevels];
		// FIXGJB: ok to assume these get initialized to 0?
		//       for (int i = 0; i < cLevels; i++) {
		//  _values[i] = 0;
		//       }
	}

	this(double w1, double w2, double w3)
	{
		_values = new double[3];
		_values[0] = w1;
		_values[1] = w2;
		_values[2] = w3;
	}

	this(double[] weights)
	{
		_values = weights.dup;
	}

	public static const ClSymbolicWeight clsZero = new ClSymbolicWeight(0.0, 0.0, 0.0);

	public Object clone()
	{
		return new ClSymbolicWeight(_values);
	}

	public ClSymbolicWeight times(double n)
	{
		ClSymbolicWeight clsw = cast(ClSymbolicWeight) clone();
		for (int i = 0; i < _values.length; i++)
		{
			clsw._values[i] *= n;
		}
		return clsw;
	}

	public ClSymbolicWeight divideBy(double n)
	{
		// assert(n != 0);
		ClSymbolicWeight clsw = cast(ClSymbolicWeight) clone();
		for (int i = 0; i < _values.length; i++)
		{
			clsw._values[i] /= n;
		}
		return clsw;
	}

	public ClSymbolicWeight add(ClSymbolicWeight cl)
	{
		// assert(cl.cLevels() == cLevels());

		ClSymbolicWeight clsw = cast(ClSymbolicWeight) clone();
		for (int i = 0; i < _values.length; i++)
		{
			clsw._values[i] += cl._values[i];
		}
		return clsw;
	}

	public ClSymbolicWeight subtract(ClSymbolicWeight cl)
	{
		// assert(cl.cLevels() == cLevels());

		ClSymbolicWeight clsw = cast(ClSymbolicWeight) clone();
		for (int i = 0; i < _values.length; i++)
		{
			clsw._values[i] -= cl._values[i];
		}
		return clsw;
	}

	public bool lessThan(const ClSymbolicWeight cl)
	{
		// assert cl.cLevels() == cLevels()
		for (int i = 0; i < _values.length; i++)
		{
			if (_values[i] < cl._values[i])
				return true;
			else if (_values[i] > cl._values[i])
				return false;
		}
		return false; // they are equal
	}

	public bool lessThanOrEqual(ClSymbolicWeight cl)
	{
		// assert cl.cLevels() == cLevels()
		for (int i = 0; i < _values.length; i++)
		{
			if (_values[i] < cl._values[i])
				return true;
			else if (_values[i] > cl._values[i])
				return false;
		}
		return true; // they are equal
	}

	public
	bool equal(ClSymbolicWeight cl)
	{
		for (int i = 0; i < _values.length; i++)
		{
			if (_values[i] != cl._values[i])
				return false;
		}
		return true; // they are equal
	}

	public bool greaterThan(ClSymbolicWeight cl)
	{
		return !this.lessThanOrEqual(cl);
	}

	public bool greaterThanOrEqual(ClSymbolicWeight cl)
	{
		return !this.lessThan(cl);
	}

	public bool isNegative()
	{
		return this.lessThan(clsZero);
	}

	public double asDouble()
	{
		double sum = 0;
		double factor = 1;
		double multiplier = 1000;
		foreach_reverse(i; _values)
		{
			sum += i * factor;
			factor *= multiplier;
		}
		return sum;
	}

	public override string toString()
	{
		string res = "[";

		for (ulong i = 0; i < _values.length-1; i++)
		{
			res ~= _values[i].to!string();
			res ~= ",";
		}
		res ~= _values[$-1].to!string();
		res ~= "]";
		return res;
	}

	public ulong cLevels()
	{
		return _values.length;
	}

	private double[] _values;
}
