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

	override string toString() const
	{
		return "[" ~ name ~ ":obj]";
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
		return false;
	}
}
