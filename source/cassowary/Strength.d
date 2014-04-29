module cassowary.Strength;

import cassowary.SymbolicWeight;

public class ClStrength
{
	this(string name, ClSymbolicWeight symbolicWeight)
	{  _name = name;    _symbolicWeight = symbolicWeight; }

	this(string name, double w1, double w2, double w3)
	{
		_name = name;
		_symbolicWeight = new ClSymbolicWeight(w1, w2, w3);
	}

	public bool isRequired()
	{
		return (required == this);
	}

	public override string toString()
	{
		return name () ~(!isRequired() ? (":" ~ symbolicWeight().toString()) : "");
	}

	public ClSymbolicWeight symbolicWeight()
	{
		return _symbolicWeight;
	}

	public string name()
	{
		return _name;
	}

	public void set_name(string name)
	{
		_name = name;
	}

	public void set_symbolicWeight(ClSymbolicWeight symbolicWeight)
	{
		_symbolicWeight = symbolicWeight;
	}

	public static ClStrength required;

	public static ClStrength strong;

	public static ClStrength medium;

	public static ClStrength weak;

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
