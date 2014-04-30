module cassowary.Strength;

import cassowary.SymbolicWeight;

class ClStrength
{
	this(string theName, const ClSymbolicWeight weight) pure @safe nothrow
	{
		name = theName;
		symbolicWeight = weight;
	}

	this(string theName, double w1, double w2, double w3) pure @safe nothrow immutable
	{
		name = theName;
		symbolicWeight = new immutable ClSymbolicWeight(w1, w2, w3);
	}

	bool isRequired() const
	{
		return (required == this);
	}

	override string toString() const
	{
		return name ~ (!isRequired() ? (":" ~ symbolicWeight.toString()) : "");
	}

	string name;
	const ClSymbolicWeight symbolicWeight;

	immutable shared static ClStrength required = new immutable ClStrength("<Required>", 1000, 1000, 1000);
	immutable shared static ClStrength strong = new immutable ClStrength("strong", 1.0, 0.0, 0.0);
	immutable shared static ClStrength medium = new immutable ClStrength("medium", 0.0, 1.0, 0.0);
	immutable shared static ClStrength weak = new immutable ClStrength("weak", 0.0, 0.0, 1.0);
}
