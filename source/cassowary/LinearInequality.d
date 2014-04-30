module cassowary.LinearInequality;

import cassowary.LinearConstraint;
import cassowary.LinearExpression;
import cassowary.Strength;
import cassowary.Variable;
import cassowary.AbstractVariable;
import cassowary.Error;

enum InequalityType
{
	GEQ,
	LEQ
}

class ClLinearInequality : ClLinearConstraint
{
	this(ClLinearExpression cle, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super(cle, strength, weight);
	}

	this(ClVariable clv1, InequalityType op, ClVariable clv2, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super(new ClLinearExpression(clv2), strength, weight);
		if (op == InequalityType.GEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addVariable(clv1);
		}
		else if (op == InequalityType.LEQ)
		{
			_expression.addVariable(clv1, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}

	this(ClVariable clv, InequalityType op, double val, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super(new ClLinearExpression(val), strength, weight);
		if (op == InequalityType.GEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addVariable(clv);
		}
		else if (op == InequalityType.LEQ)
		{
			_expression.addVariable(clv, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}

	this(ClLinearExpression cle1, InequalityType op, ClLinearExpression cle2, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super((cast(ClLinearExpression) cle2.clone()), strength, weight);
		if (op == InequalityType.GEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addExpression(cle1);
		}
		else if (op == InequalityType.LEQ)
		{
			_expression.addExpression(cle1, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}

	this(ClAbstractVariable clv, InequalityType op, ClLinearExpression cle, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super((cast(ClLinearExpression) cle.clone()), strength, weight);
		if (op == InequalityType.GEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addVariable(clv);
		}
		else if (op == InequalityType.LEQ)
		{
			_expression.addVariable(clv, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}

	this(ClLinearExpression cle, InequalityType op, ClAbstractVariable clv, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super((cast(ClLinearExpression) cle.clone()), strength, weight);
		if (op == InequalityType.LEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addVariable(clv);
		}
		else if (op == InequalityType.GEQ)
		{
			_expression.addVariable(clv, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}

	override bool isInequality() const
	{
		return true;
	}

	override string toString() const
	{
		return super.toString() ~ " >= 0 )";
	}
}
