module cassowary.Constraint;

import std.conv;
import std.typecons;

import cassowary.Strength;
import cassowary.LinearExpression;

abstract class ClConstraint
{
	this(const ClStrength strength = ClStrength.required, double weight = 1)
	{
		_strength = strength;
		_weight = weight;
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

	const(ClStrength) strength()
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

	private Rebindable!(const ClStrength) _strength;
	private double _weight;
}
