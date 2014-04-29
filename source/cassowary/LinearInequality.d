import LinearConstraint;
import LinearExpression;
import Strength;
import Variable;
import AbstractVariable;
import Cl;
import Error;

public class ClLinearInequality : ClLinearConstraint
{
	this(ClLinearExpression cle,
		 ClStrength strength,
		 double weight)
	{
		super(cle, strength, weight);
	}

	this(ClLinearExpression cle,
		 ClStrength strength)
	{
		super(cle, strength);
	}

	this(ClLinearExpression cle)
	{
		super(cle);
	}

	this(ClVariable clv1,
		 byte op_enum,
		 ClVariable clv2,
		 ClStrength strength,
		 double weight)
	{
		super(new ClLinearExpression(clv2), strength, weight);
		if (op_enum == CL.GEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addVariable(clv1);
		}
		else if (op_enum == CL.LEQ)
		{
			_expression.addVariable(clv1, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}

	this(ClVariable clv1,
		 byte op_enum,
		 ClVariable clv2,
		 ClStrength strength)
	{
		this(clv1, op_enum, clv2, strength, 1.0);
	}

	this(ClVariable clv1,
		 byte op_enum,
		 ClVariable clv2)
	{
		this(clv1, op_enum, clv2, ClStrength.required, 1.0);
	}


	this(ClVariable clv,
		 byte op_enum,
		 double val,
		 ClStrength strength,
		 double weight)
	{
		super(new ClLinearExpression(val), strength, weight);
		if (op_enum == CL.GEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addVariable(clv);
		}
		else if (op_enum == CL.LEQ)
		{
			_expression.addVariable(clv, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}

	this(ClVariable clv,
		 byte op_enum,
		 double val,
		 ClStrength strength)
	{
		this(clv, op_enum, val, strength, 1.0);
	}

	this(ClVariable clv,
		 byte op_enum,
		 double val)
	{
		this(clv, op_enum, val, ClStrength.required, 1.0);
	}

	this(ClLinearExpression cle1,
		 byte op_enum,
		 ClLinearExpression cle2,
		 ClStrength strength,
		 double weight)
	{
		super((cast(ClLinearExpression) cle2.clone()), strength, weight);
		if (op_enum == CL.GEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addExpression(cle1);
		}
		else if (op_enum == CL.LEQ)
		{
			_expression.addExpression(cle1, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}

	this(ClLinearExpression cle1,
		 byte op_enum,
		 ClLinearExpression cle2,
		 ClStrength strength)
	{
		this(cle1, op_enum, cle2, strength, 1.0);
	}

	this(ClLinearExpression cle1,
		 byte op_enum,
		 ClLinearExpression cle2)
	{
		this(cle1, op_enum, cle2, ClStrength.required, 1.0);
	}


	this(ClAbstractVariable clv,
		 byte op_enum,
		 ClLinearExpression cle,
		 ClStrength strength,
		 double weight)
	{
		super((cast(ClLinearExpression) cle.clone()), strength, weight);
		if (op_enum == CL.GEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addVariable(clv);
		}
		else if (op_enum == CL.LEQ)
		{
			_expression.addVariable(clv, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}

	this(ClAbstractVariable clv,
		 byte op_enum,
		 ClLinearExpression cle,
		 ClStrength strength)
	{
		this(clv, op_enum, cle, strength, 1.0);
	}

	this(ClAbstractVariable clv,
		 byte op_enum,
		 ClLinearExpression cle)
	{
		this(clv, op_enum, cle, ClStrength.required, 1.0);
	}


	this(ClLinearExpression cle,
		 byte op_enum,
		 ClAbstractVariable clv,
		 ClStrength strength,
		 double weight)
	{
		super((cast(ClLinearExpression) cle.clone()), strength, weight);
		if (op_enum == CL.LEQ)
		{
			_expression.multiplyMe(-1.0);
			_expression.addVariable(clv);
		}
		else if (op_enum == CL.GEQ)
		{
			_expression.addVariable(clv, -1.0);
		}
		else // the operator was invalid
			throw new ClErrorInternal("Invalid operator in ClLinearInequality constructor");
	}


	this(ClLinearExpression cle,
		 byte op_enum,
		 ClAbstractVariable clv,
		 ClStrength strength)
	{
		this(cle, op_enum, clv, strength, 1.0);
	}

	this(ClLinearExpression cle,
		 byte op_enum,
		 ClAbstractVariable clv)
	{
		this(cle, op_enum, clv, ClStrength.required, 1.0);
	}


	override bool isInequality()
	{
		return true;
	}

	override string toString()
	{
		return super.toString() ~ " >= 0 )";
	}
}
