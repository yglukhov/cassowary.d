module cassowary.EditOrStayConstraint;

import cassowary.Constraint;
import cassowary.Variable;
import cassowary.Strength;
import cassowary.LinearExpression;

abstract class ClEditOrStayConstraint : ClConstraint
{
	this(ClVariable var, ClStrength strength, double weight)
	{
		super(strength, weight);
		_variable = var;
		_expression = new ClLinearExpression(_variable, -1.0, _variable.value());
	}

	this(ClVariable var, ClStrength strength)
	{
		this(var, strength, 1.0);
	}

	this(ClVariable var)
	{
		this(var, ClStrength.required, 1.0);
		_variable = var;
	}

	public ClVariable variable()
	{
		return _variable;
	}

	override ClLinearExpression expression()
	{
		return _expression;
	}

	private void setVariable(ClVariable v)
	{
		_variable = v;
	}

	protected ClVariable _variable;
	// cache the expresion
	private ClLinearExpression _expression;
}
