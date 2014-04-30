module cassowary.Constraint;

import std.conv;

import cassowary.Strength;
import cassowary.LinearExpression;

abstract class ClConstraint
{
	this(ClStrength strength, double weight)
	{
		_strength = strength;
		 _weight = weight;
	}

	this(ClStrength strength)
	{
		_strength = strength;
		 _weight = 1.0;
	}

	this()
	{
		_strength = ClStrength.required;
		 _weight = 1.0;
	}

	abstract ClLinearExpression expression();

	bool isEditConstraint() const
	{
		return false;
	}

	bool isInequality() const
	{
		return false;
	}

	bool isRequired() const
	{
		return _strength.isRequired();
	}

	bool isStayConstraint() const
	{
		return false;
	}

	ClStrength strength()
	{
		return _strength;
	}

	double weight() const
	{
		return _weight;
	}

	override string toString() const
	{
		return _strength.toString() ~
			   " {" ~ weight().to!string() ~ "} (" ~ (cast(ClConstraint)this).expression().toString();
	}

	private void setStrength(ClStrength strength)
	{
		_strength = strength;
	}

	private void setWeight(double weight)
	{
		_weight = weight;
	}

	Object attachedObject;

	private ClStrength _strength;
	private double _weight;
}
