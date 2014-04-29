module cassowary.ObjectiveVariable;

import cassowary.AbstractVariable;

class ClObjectiveVariable : ClAbstractVariable
{
	this(string name)
	{
		super(name);
	}

	this(long number, string prefix)
	{
		super(number, prefix);
	}

	override string toString()
	{
		return "[" ~ name ~ ":obj]";
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
		return false;
	}
}
