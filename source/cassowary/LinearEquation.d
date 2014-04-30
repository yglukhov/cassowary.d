module cassowary.LinearEquation;

import cassowary.LinearConstraint;
import cassowary.LinearExpression;
import cassowary.Strength;
import cassowary.AbstractVariable;

class ClLinearEquation : ClLinearConstraint
{
	this(ClLinearExpression cle, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super(cle, strength, weight);
	}

	this(ClAbstractVariable clv, ClLinearExpression cle, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super(cle, strength, weight);
		_expression.addVariable(clv, -1.0);
	}

	this(ClAbstractVariable clv, double val, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super(new ClLinearExpression(val), strength, weight);
		_expression.addVariable(clv, -1.0);
	}

	this(ClLinearExpression cle, ClAbstractVariable clv, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super((cast(ClLinearExpression) cle.clone()), strength, weight);
		_expression.addVariable(clv, -1.0);
	}

	this(ClLinearExpression cle1, ClLinearExpression cle2, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super((cast(ClLinearExpression) cle1.clone()), strength, weight);
		_expression.addExpression(cle2, -1.0);
	}

	this(ClAbstractVariable clv1, ClAbstractVariable clv2, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		this(new ClLinearExpression(clv1), clv2, strength, weight);
	}

	override string toString() const
	{
		return super.toString() ~ " = 0 )";
	}
}
