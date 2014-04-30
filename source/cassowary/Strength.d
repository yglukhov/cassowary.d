module cassowary.Strength;

import cassowary.SymbolicWeight;

class ClStrength
{
	this(string name, ClSymbolicWeight symbolicWeight) pure @safe nothrow
	{
		_name = name;
		_symbolicWeight = symbolicWeight;
	}

	this(string name, double w1, double w2, double w3) pure @safe nothrow
	{
		_name = name;
		_symbolicWeight = new ClSymbolicWeight(w1, w2, w3);
	}

	bool isRequired() const
	{
		return (required == this);
	}

	override string toString() const
	{
		return name () ~(!isRequired() ? (":" ~ _symbolicWeight.toString()) : "");
	}

	ClSymbolicWeight symbolicWeight()
	{
		return _symbolicWeight;
	}

	string name() const
	{
		return _name;
	}

	void set_name(string name)
	{
		_name = name;
	}

	void set_symbolicWeight(ClSymbolicWeight symbolicWeight)
	{
		_symbolicWeight = symbolicWeight;
	}

	static ClStrength required;

	static ClStrength strong;

	static ClStrength medium;

	static ClStrength weak;

	static this()
	{
		required = new ClStrength("<Required>", 1000, 1000, 1000);
		strong = new ClStrength("strong", 1.0, 0.0, 0.0);
		medium = new ClStrength("medium", 0.0, 1.0, 0.0);
		weak = new ClStrength("weak", 0.0, 0.0, 1.0);
	}

	private string _name;

	private ClSymbolicWeight _symbolicWeight;
}
