module cassowary.Variable;

import std.conv;
import cassowary.AbstractVariable;
import cassowary.LinearExpression;

class ClVariable : ClAbstractVariable
{
	this(string name, double value)
	{
		super(name);
		_value = value;
		if (varMap !is null)
		{
			varMap[name] = this;
		}
	}

	this(string name)
	{
		this(name, 0.0);
	}

	this(double value)
	{
		_value = value;
	}

	this()
	{
		_value = 0.0;
	}

	this(long number, string prefix, double value)
	{
		super(number, prefix);
		_value = value;
	}

	this(long number, string prefix)
	{
		super(number, prefix);
		_value = 0.0;
	}

	override bool isDummy() const
	{
		return false;
	}

	override bool isExternal() const
	{
		return true;
	}

	override bool isPivotable() const
	{
		return false;
	}

	override bool isRestricted() const
	{
		return false;
	}

	override string toString() const
	{
		return "[" ~ name ~ ":" ~ _value.to!string() ~ "]";
	}

	// change the value held -- should *not* use this if the variable is
	// in a solver -- instead use addEditVar() and suggestValue() interface
	final double value() const
	{
		return _value;
	}

	final void set_value(double value)
	{
		_value = value;
	}

	// permit overriding in subclasses in case something needs to be
	// done when the value is changed by the solver
	// may be called when the value hasn't actually changed -- just
	// means the solver is setting the external variable
	void change_value(double value)
	{
		_value = value;
	}


	ClLinearExpression opBinary(string op) (double arg)
	{
		static if (op == "+")
			return new ClLinearExpression(this, 1, arg);
		else
			static if (op == "-")
				return new ClLinearExpression(this, 1, -arg);
			else
				static if (op == "*")
					return new ClLinearExpression(this, arg, 0);
				else
					static if (op == "/")
						return new ClLinearExpression(this, 1.0 / arg, 0);
	}

	ClLinearExpression opBinaryRight(string op) (double arg)
	{
		static if (op == "+")
			return new ClLinearExpression(this, 1, arg);
		else
			static if (op == "-")
				return new ClLinearExpression(this, -1, arg);
			else
				static if (op == "*")
					return new ClLinearExpression(this, arg, 0);
	}

	ClLinearExpression opBinary(string op) (ClVariable arg)
	{
		static if (op == "+")
			return (new ClLinearExpression(this)).plus(arg);
		else
			static if (op == "-")
				return (new ClLinearExpression(this)).minus(arg);
			else
				static if (op == "*")
					return new ClLinearExpression(this).times(arg);
				else
					static if (op == "/")
						return new ClLinearExpression(this).divide(arg);
	}

	Object attachedObject;
	static ClVariable[string] varMap;
	private double _value;
}
