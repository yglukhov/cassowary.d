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

	override string toString()
	{
		return "[" ~ name ~ ":dummy]";
	}

	override bool isDummy()
	{
		return true;
	}

	override bool isExternal()
	{
		return false;
	}

	override bool isPivotable()
	{
		return false;
	}

	override bool isRestricted()
	{
		return true;
	}
}
