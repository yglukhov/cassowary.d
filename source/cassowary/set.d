import std.conv;

class Set(TKey = Object)
{
	public bool containsKey(TKey o)
	{
		return (o in hash) !is null;
	}

	public void insert(TKey o)
	{
		hash[o] = 1;
	}

	public void remove(TKey o)
	{
		hash.remove(o);
	}

	public void clear()
	{
		hash.clear();
	}

	public auto size()
	{
		return hash.length();
	}

	public bool isEmpty()
	{
		return hash.length() == 0;
	}

	public Object clone()
	{
		auto result = new typeof(this)();
		result.hash = hash.dup;
		return result;
	}

	public auto elements()
	{
		return hash.keys;
	}

	public override string toString()
	{
		return to!string(hash.keys());
	}

	private byte[TKey] hash;
}
