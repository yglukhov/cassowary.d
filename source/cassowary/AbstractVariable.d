import std.conv;

public abstract class ClAbstractVariable
{
	this(string theName)
	{
		//hash_code = iVariableNumber;
		name = theName;
		iVariableNumber++;
	}

	public this()
	{
		//hash_code = iVariableNumber;
		name = "v" ~ iVariableNumber.to!string();
		iVariableNumber++;
	}

	public this(long varnumber, string prefix)
	{
		//hash_code = iVariableNumber;
		name = prefix ~ varnumber.to!string();
		iVariableNumber++;
	}

	public bool isDummy()
	{
		return false;
	}

	public abstract bool isExternal();

	public abstract bool isPivotable();

	public abstract bool isRestricted();

	public abstract override string toString();

	public static int numCreated()
	{
		return iVariableNumber;
	}

	// for debugging
	//  public final int hashCode() { return hash_code; }

	string name;

	// for debugging
	// private int hash_code;

	private static int iVariableNumber;
}
