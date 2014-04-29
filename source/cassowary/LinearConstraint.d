import Constraint;
import LinearExpression;
import Strength;

class ClLinearConstraint : ClConstraint
{
	this(ClLinearExpression cle, ClStrength strength, double weight)
	{
		super(strength, weight);
		_expression = cle;
	}

	this(ClLinearExpression cle, ClStrength strength)
	{
		super(strength, 1.0);
		_expression = cle;
	}

	this(ClLinearExpression cle)
	{
		super(ClStrength.required, 1.0);
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
