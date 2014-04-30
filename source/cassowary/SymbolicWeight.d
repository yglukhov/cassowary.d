module cassowary.SymbolicWeight;

import std.conv;
import std.algorithm;
import std.array;

class ClSymbolicWeight
{
	this(int cLevels) pure @safe nothrow
	{
		_values = new double[cLevels];
	}

	this(double w1, double w2, double w3) pure @safe nothrow
	{
		_values = [w1, w2, w3];
	}

	this(immutable double[] weights) pure @safe nothrow
	{
		_values = weights;
	}

	static immutable ClSymbolicWeight clsZero = new immutable ClSymbolicWeight(0.0, 0.0, 0.0);

	ClSymbolicWeight times(double n) const
	{
		return new ClSymbolicWeight(_values.map!(a => a * n)().array().idup);
	}

	ClSymbolicWeight divideBy(double n) const
	{
		return new ClSymbolicWeight(_values.map!(a => a / n)().array().idup);
	}

	ClSymbolicWeight add(ClSymbolicWeight cl) const
	{
		auto newValues = _values.dup;
		for (int i = 0; i < _values.length; i++)
		{
			newValues[i] += cl._values[i];
		}
		return new ClSymbolicWeight(newValues.idup);
	}

	ClSymbolicWeight subtract(ClSymbolicWeight cl) const
	{
		auto newValues = _values.dup;
		for (int i = 0; i < _values.length; i++)
		{
			newValues[i] -= cl._values[i];
		}
		return new ClSymbolicWeight(newValues.idup);
	}

	bool lessThan(const ClSymbolicWeight cl) const pure
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

	bool lessThanOrEqual(ClSymbolicWeight cl) const pure
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

	bool equal(ClSymbolicWeight cl) const pure @safe
	{
		for (int i = 0; i < _values.length; i++)
		{
			if (_values[i] != cl._values[i])
				return false;
		}
		return true; // they are equal
	}

	bool greaterThan(ClSymbolicWeight cl) const pure
	{
		return !this.lessThanOrEqual(cl);
	}

	bool greaterThanOrEqual(ClSymbolicWeight cl) const pure
	{
		return !this.lessThan(cl);
	}

	bool isNegative() const pure
	{
		return this.lessThan(clsZero);
	}

	double asDouble() const pure @safe
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

	override string toString() const
	{
		return _values.to!string();
	}

	ulong cLevels() const pure @safe nothrow
	{
		return _values.length;
	}

	private immutable double[] _values;
}
