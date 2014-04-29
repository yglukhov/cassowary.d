module cassowary.LinearEquation;

import cassowary.LinearConstraint;
import cassowary.LinearExpression;
import cassowary.Strength;
import cassowary.AbstractVariable;

class ClLinearEquation : ClLinearConstraint
{
	this(ClLinearExpression cle, ClStrength strength, double weight)
	{
		super(cle, strength, weight);
	}

	this(ClLinearExpression cle, ClStrength strength)
	{
		super(cle, strength);
	}

	this(ClLinearExpression cle)
	{
		super(cle);
	}

	this(ClAbstractVariable clv, ClLinearExpression cle, ClStrength strength, double weight)
	{
		super(cle, strength, weight);
		_expression.addVariable(clv, -1.0);
	}

	this(ClAbstractVariable clv, ClLinearExpression cle, ClStrength strength)
	{
		this(clv, cle, strength, 1.0);
	}

	this(ClAbstractVariable clv, ClLinearExpression cle)
	{
		this(clv, cle, ClStrength.required, 1.0);
	}

	this(ClAbstractVariable clv, double val, ClStrength strength, double weight)
	{
		super(new ClLinearExpression(val), strength, weight);
		_expression.addVariable(clv, -1.0);
	}

	this(ClAbstractVariable clv, double val, ClStrength strength)
	{
		this(clv, val, strength, 1.0);
	}

	this(ClAbstractVariable clv, double val)
	{
		this(clv, val, ClStrength.required, 1.0);
	}

	this(ClLinearExpression cle,
		 ClAbstractVariable clv,
		 ClStrength strength,
		 double weight)
	{
		super((cast(ClLinearExpression) cle.clone()), strength, weight);
		_expression.addVariable(clv, -1.0);
	}

	this(ClLinearExpression cle, ClAbstractVariable clv, ClStrength strength)
	{
		this(cle, clv, strength, 1.0);
	}

	this(ClLinearExpression cle, ClAbstractVariable clv)
	{
		this(cle, clv, ClStrength.required, 1.0);
	}

	this(ClLinearExpression cle1, ClLinearExpression cle2, ClStrength strength, double weight)
	{
		super((cast(ClLinearExpression) cle1.clone()), strength, weight);
		_expression.addExpression(cle2, -1.0);
	}

	this(ClLinearExpression cle1, ClLinearExpression cle2, ClStrength strength)
	{
		this(cle1, cle2, strength, 1.0);
	}

	this(ClLinearExpression cle1, ClLinearExpression cle2)
	{
		this(cle1, cle2, ClStrength.required, 1.0);
	}

	override string toString()
	{
		return super.toString() ~ " = 0 )";
	}
}
