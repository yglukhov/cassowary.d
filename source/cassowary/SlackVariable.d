module cassowary.SlackVariable;

import cassowary.AbstractVariable;

class ClSlackVariable : ClAbstractVariable
{
	// friend ClTableau;
	// friend ClSimplexSolver;

	this(string theName)
	{  super(theName); }

	this()
	{  }

	this(long number, string prefix)
	{ super(number, prefix); }

	override string toString()
	{
		return "[" ~ name ~ ":slack]";
	}

	override bool isExternal()
	{
		return false;
	}

	override bool isPivotable()
	{
		return true;
	}

	override bool isRestricted()
	{
		return true;
	}
}
