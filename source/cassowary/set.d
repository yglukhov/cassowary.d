module cassowary.set;

import std.conv;

class Set(TKey = Object)
{
	bool containsKey(TKey o)
	{
		return (o in hash) !is null;
	}

	void insert(TKey o)
	{
		hash[o] = 1;
	}

	void remove(TKey o)
	{
		hash.remove(o);
	}

	void clear()
	{
		hash = null;
	}

	@property auto length()
	{
		return hash.length;
	}

	bool isEmpty()
	{
		return length == 0;
	}

	@property auto anyElement()
	{
		return hash.byKey().front;
	}

	override string toString()
	{
		return to!string(hash.keys());
	}

	int opApply(int delegate(ref TKey) operations)
	{
		int res = 0;
		foreach(ref key; hash.byKey())
		{
			res = operations(key);
			if (res) break;
		}
		return res;
	}

	private byte[TKey] hash;
}
