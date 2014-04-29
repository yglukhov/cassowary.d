import std.conv;

import Strength;
import LinearExpression;

public abstract class ClConstraint
{
	this(ClStrength strength, double weight)
	{
		_strength = strength; _weight = weight;
	}

	this(ClStrength strength)
	{
		_strength = strength; _weight = 1.0;
	}

	this()
	{
		_strength = ClStrength.required; _weight = 1.0;
	}

	public abstract ClLinearExpression expression();

	public bool isEditConstraint()
	{
		return false;
	}

	public bool isInequality()
	{
		return false;
	}

	public bool isRequired()
	{
		return _strength.isRequired();
	}

	public bool isStayConstraint()
	{
		return false;
	}

	public ClStrength strength()
	{
		return _strength;
	}

	public double weight()
	{
		return _weight;
	}

	public override string toString()
	{
		return _strength.toString() ~
			   " {" ~ weight().to!string() ~ "} (" ~ expression().toString();
	}

	public void setAttachedObject(Object o)
	{
		_attachedObject = o;
	}

	public Object getAttachedObject()
	{
		return _attachedObject;
	}

	private void setStrength(ClStrength strength)
	{
		_strength = strength;
	}

	private void setWeight(double weight)
	{
		_weight = weight;
	}

	private ClStrength _strength;
	private double _weight;

	private Object _attachedObject;
}
