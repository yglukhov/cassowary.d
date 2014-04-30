module cassowary.DummyVariable;

import cassowary.AbstractVariable;

class ClDummyVariable : ClAbstractVariable
{
	this(string name)
	{
		super(name);
	}

	this()
	{ }

	this(long number, string prefix)
	{
		super(number, prefix);
	}

	override string toString() const
	{
		return "[" ~ name ~ ":dummy]";
	}

	override bool isDummy() const
	{
		return true;
	}

	override bool isExternal() const
	{
		return false;
	}

	override bool isPivotable() const
	{
		return false;
	}

	override bool isRestricted() const
	{
		return true;
	}
}
