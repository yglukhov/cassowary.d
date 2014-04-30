module cassowary.SlackVariable;

import cassowary.AbstractVariable;

class ClSlackVariable : ClAbstractVariable
{
	// friend ClTableau;
	// friend ClSimplexSolver;

	this(string theName)
	{
		super(theName);
	}

	this()
	{  }

	this(long number, string prefix)
	{
		super(number, prefix);
	}

	override string toString() const
	{
		return "[" ~ name ~ ":slack]";
	}

	override bool isExternal() const
	{
		return false;
	}

	override bool isPivotable() const
	{
		return true;
	}

	override bool isRestricted() const
	{
		return true;
	}
}
