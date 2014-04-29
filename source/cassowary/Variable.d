import std.conv;
import AbstractVariable;

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

	public override bool isDummy()
	{
		return false;
	}

	public override bool isExternal()
	{
		return true;
	}

	public override bool isPivotable()
	{
		return false;
	}

	public override bool isRestricted()
	{
		return false;
	}

	public override string toString()
	{
		return "[" ~ name ~ ":" ~ _value.to!string() ~ "]";
	}

	// change the value held -- should *not* use this if the variable is
	// in a solver -- instead use addEditVar() and suggestValue() interface
	public final double value()
	{
		return _value;
	}

	public final void set_value(double value)
	{
		_value = value;
	}

	// permit overriding in subclasses in case something needs to be
	// done when the value is changed by the solver
	// may be called when the value hasn't actually changed -- just
	// means the solver is setting the external variable
	public void change_value(double value)
	{
		_value = value;
	}

	Object attachedObject;

	static ClVariable[string] varMap;

	private double _value;
}
