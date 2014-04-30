module cassowary.LinearConstraint;

import cassowary.Constraint;
import cassowary.LinearExpression;
import cassowary.Strength;

class ClLinearConstraint : ClConstraint
{
	this(ClLinearExpression cle, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super(strength, weight);
		_expression = cle;
	}

	override ClLinearExpression expression()
	{
		return _expression;
	}

	protected void setExpression(ClLinearExpression expr)
	{
		_expression = expr;
	}

	protected ClLinearExpression _expression;
}
