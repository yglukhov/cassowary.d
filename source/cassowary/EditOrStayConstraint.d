module cassowary.EditOrStayConstraint;

import cassowary.Constraint;
import cassowary.Variable;
import cassowary.Strength;
import cassowary.LinearExpression;

abstract class ClEditOrStayConstraint : ClConstraint
{
	this(ClVariable var, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super(strength, weight);
		_variable = var;
		_expression = new ClLinearExpression(_variable, -1.0, _variable.value());
	}

	ClVariable variable()
	{
		return _variable;
	}

	override ClLinearExpression expression()
	{
		return _expression;
	}

	private ClVariable _variable;
	// cache the expresion
	private ClLinearExpression _expression;
}
