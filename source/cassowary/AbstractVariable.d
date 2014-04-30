module cassowary.AbstractVariable;

import std.conv;
import cassowary.LinearExpression;

abstract class ClAbstractVariable
{
	this(string theName)
	{
		//hash_code = iVariableNumber;
		name = theName;
		iVariableNumber++;
	}

	this()
	{
		//hash_code = iVariableNumber;
		name = "v" ~ iVariableNumber.to!string();
		iVariableNumber++;
	}

	this(long varnumber, string prefix)
	{
		//hash_code = iVariableNumber;
		name = prefix ~ varnumber.to!string();
		iVariableNumber++;
	}

	bool isDummy() const
	{
		return false;
	}

	abstract bool isExternal() const;

	abstract bool isPivotable() const;

	abstract bool isRestricted() const;

	abstract override string toString() const;

	static int numCreated()
	{
		return iVariableNumber;
	}

	string name;

	private static int iVariableNumber;
}
