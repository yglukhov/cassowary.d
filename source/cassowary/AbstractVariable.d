import std.conv;

import LinearExpression;

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

	bool isDummy()
	{
		return false;
	}

	abstract bool isExternal();

	abstract bool isPivotable();

	abstract bool isRestricted();

	abstract override string toString();

	static int numCreated()
	{
		return iVariableNumber;
	}

	string name;

	private static int iVariableNumber;
}
