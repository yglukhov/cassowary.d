module cassowary.set;

import std.conv;

class Set(TKey = Object)
{
	bool opBinary(string op) (const TKey o) if (op == "in")
	{
		return (o in hash) !is null;
	}

	auto opOpAssign(string op) (ref TKey o) if (op == "~")
	{
		hash[o] = 1;
		return this;
	}

	void remove(TKey o)
	{
		hash.remove(o);
	}

	void clear()
	{
		hash = null;
	}

	@property auto length() const
	{
		return hash.length;
	}

	bool isEmpty() const
	{
		return length == 0;
	}

	@property auto anyElement()
	{
		return hash.byKey().front;
	}

	override string toString() const
	{
		return hash.keys().to!string();
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
