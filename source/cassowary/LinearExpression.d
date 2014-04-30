module cassowary.LinearExpression;

import std.stdio;
import std.conv;
import std.math;

import cassowary.AbstractVariable;
import cassowary.Variable;
import cassowary.Tableau;
import cassowary.Cl;
import cassowary.Error;

class ClLinearExpression
{
	this(ClAbstractVariable clv, double value, double constant)
	{
		_constant = constant;
		if (clv !is null)
			_terms[clv] = value;
	}

	this(double num)
	{
		this(null, 0, num);
	}

	this()
	{
		this(0);
	}

	this(ClAbstractVariable clv, double value)
	{
		this(clv, value, 0.0);
	}

	this(ClAbstractVariable clv)
	{
		this(clv, 1, 0);
	}


	// for use by the clone method
	protected this(double constant, double[ClAbstractVariable] terms)
	{
		_constant = constant;
		_terms = terms.dup();
	}


	ClLinearExpression multiplyMe(double x)
	{
		_constant *= x;

		foreach(ClAbstractVariable clv, ref val; _terms)
		{
			val *= x;
		}
		return this;
	}

	final Object clone()
	{
		return new ClLinearExpression(_constant, _terms);
	}

	ClLinearExpression opBinary(string op, T) (T expr)
	{
		static if (op == "+")
			return plus(expr);
		else
			static if (op == "-")
				return minus(expr);
			else
				static if (op == "*")
					return times(expr);
				else
					static if (op == "/")
						return divide(expr);
	}

	final ClLinearExpression times(double x)
	{
		return (cast(ClLinearExpression) clone()).multiplyMe(x);
	}

	final ClLinearExpression times(ClLinearExpression expr)
	{
		if (isConstant())
		{
			return expr.times(_constant);
		}
		else if (!expr.isConstant())
		{
			throw new ClErrorNonlinearExpression();
		}
		return times(expr._constant);
	}

	final ClLinearExpression plus(double c)
	{
		ClLinearExpression result = cast(ClLinearExpression) clone();
		result._constant += c;
		return result;
	}

	final ClLinearExpression plus(ClLinearExpression expr)
	{
		return (cast(ClLinearExpression) clone()).addExpression(expr, 1.0);
	}

	final ClLinearExpression plus(ClVariable var)
	{
		return (cast(ClLinearExpression) clone()).addVariable(var, 1.0);
	}

	final ClLinearExpression minus(double c)
	{
		return plus(-c);
	}

	final ClLinearExpression minus(ClLinearExpression expr)
	{
		return (cast(ClLinearExpression) clone()).addExpression(expr, -1.0);
	}

	final ClLinearExpression minus(ClVariable var)
	{
		return (cast(ClLinearExpression) clone()).addVariable(var, -1.0);
	}


	final ClLinearExpression divide(double x)
	{
		if (approxEqual(x, 0.0))
		{
			throw new ClErrorNonlinearExpression();
		}
		return times(1.0/x);
	}

	final ClLinearExpression divide(ClLinearExpression expr)
	{
		if (!expr.isConstant())
		{
			throw new ClErrorNonlinearExpression();
		}
		return divide(expr._constant);
	}

	final ClLinearExpression divFrom(ClLinearExpression expr)
	{
		if (!isConstant() || approxEqual(_constant, 0.0))
		{
			throw new ClErrorNonlinearExpression();
		}
		return expr.divide(_constant);
	}

	final ClLinearExpression subtractFrom(ClLinearExpression expr)
	{
		return expr.minus( this);
	}

	// Add n*expr to this expression from another expression expr.
	// Notify the solver if a variable is added or deleted from this
	// expression.
	final ClLinearExpression addExpression(ClLinearExpression expr, double n,
										   ClAbstractVariable subject,
										   ClTableau solver)
	{
		incrementConstant(n * expr.constant());

		foreach(ClAbstractVariable clv, coeff; expr.terms())
		{
			addVariable(clv, coeff*n, subject, solver);
		}
		return this;
	}

	// Add n*expr to this expression from another expression expr.
	final ClLinearExpression addExpression(ClLinearExpression expr, double n)
	{
		incrementConstant(n * expr.constant());


		foreach(ClAbstractVariable clv, coeff; expr.terms())
		{
			addVariable(clv, coeff*n);
		}
		return this;
	}

	final ClLinearExpression addExpression(ClLinearExpression expr)
	{
		return addExpression(expr, 1.0);
	}

	// Add a term c*v to this expression.  If the expression already
	// contains a term involving v, add c to the existing coefficient.
	// If the new coefficient is approximately 0, delete v.
	final ClLinearExpression addVariable(ClAbstractVariable v, double c)
	{ // body largely duplicated below
		CL.fnenterprint("addVariable:" ~ v.toString() ~ ", " ~ c.to!string());

		double* coeff = v in _terms;
		if (coeff !is null)
		{
			double new_coefficient = *coeff + c;
			if (approxEqual(new_coefficient, 0.0))
			{
				_terms.remove(v);
			}
			else
			{
				*coeff = new_coefficient;
			}
		}
		else if (!approxEqual(c, 0.0))
		{
			_terms[v] = c;
		}
		return this;
	}

	final ClLinearExpression addVariable(ClAbstractVariable v)
	{
		return addVariable(v, 1.0);
	}


	final ClLinearExpression setVariable(ClAbstractVariable v, double c)
	{
		//assert(c != 0.0);
		_terms[v] = c;
		return this;
	}

	// Add a term c*v to this expression.  If the expression already
	// contains a term involving v, add c to the existing coefficient.
	// If the new coefficient is approximately 0, delete v.  Notify the
	// solver if v appears or disappears from this expression.
	final ClLinearExpression addVariable(ClAbstractVariable v, double c,
										 ClAbstractVariable subject, ClTableau solver)
	{  // body largely duplicated above
		CL.fnenterprint("addVariable:" ~ v.toString() ~ ", " ~ c.to!string() ~ ", " ~ subject.toString() ~ ", ...");

		double* coeff = v in _terms;
		if (coeff !is null)
		{
			double new_coefficient = *coeff + c;
			if (approxEqual(new_coefficient, 0.0))
			{
				solver.noteRemovedVariable(v, subject);
				_terms.remove(v);
			}
			else
			{
				*coeff = new_coefficient;
			}
		}
		else
		{
			if (!approxEqual(c, 0.0))
			{
				_terms[v] = c;
				solver.noteAddedVariable(v, subject);
			}
		}
		return this;
	}

	// Return a pivotable variable in this expression.  (It is an error
	// if this expression is constant -- signal ClErrorInternal in
	// that case).  Return null if no pivotable variables
	final ClAbstractVariable anyPivotableVariable()
	{
		if (isConstant())
		{
			throw new ClErrorInternal("anyPivotableVariable called on a constant");
		}

		foreach(ClAbstractVariable clv, val; _terms)
		{
			if (clv.isPivotable())
				return clv;
		}

		// No pivotable variables, so just return null, and let the caller
		// error if needed
		return null;
	}

	// Replace var with a symbolic expression expr that is equal to it.
	// If a variable has been added to this expression that wasn't there
	// before, or if a variable has been dropped from this expression
	// because it now has a coefficient of 0, inform the solver.
	// PRECONDITIONS:
	//   var occurs with a non-zero coefficient in this expression.
	final void substituteOut(ClAbstractVariable var, ClLinearExpression expr,
							 ClAbstractVariable subject, ClTableau solver)
	{
		CL.fnenterprint("CLE:substituteOut: " ~ var.toString() ~ ", " ~ expr.toString() ~ ", " ~ subject.toString() ~ ", ...");
		CL.traceprint("this = " ~ this.toString());

		double multiplier = _terms[var];
		_terms.remove(var);
		incrementConstant(multiplier * expr.constant());

		foreach(ClAbstractVariable clv, coeff; expr.terms())
		{
			double* d_old_coeff = clv in _terms;
			if (d_old_coeff !is null)
			{
				double old_coeff = *d_old_coeff;
				double newCoeff = old_coeff + multiplier * coeff;
				if (approxEqual(newCoeff, 0.0))
				{
					solver.noteRemovedVariable(clv, subject);
					_terms.remove(clv);
				}
				else
				{
					*d_old_coeff = newCoeff;
				}
			}
			else
			{
				// did not have that variable already
				_terms[clv] = multiplier * coeff;
				solver.noteAddedVariable(clv, subject);
			}
		}
		CL.traceprint("Now this is " ~ this.toString());
	}

	// This linear expression currently represents the equation
	// oldSubject=self.  Destructively modify it so that it represents
	// the equation newSubject=self.
	//
	// Precondition: newSubject currently has a nonzero coefficient in
	// this expression.
	//
	// NOTES
	//   Suppose this expression is c + a*newSubject + a1*v1 + ... + an*vn.
	//
	//   Then the current equation is
	//       oldSubject = c + a*newSubject + a1*v1 + ... + an*vn.
	//   The new equation will be
	//        newSubject = -c/a + oldSubject/a - (a1/a)*v1 - ... - (an/a)*vn.
	//   Note that the term involving newSubject has been dropped.
	final void changeSubject(ClAbstractVariable old_subject, ClAbstractVariable new_subject)
	{
		_terms[old_subject] = newSubject(new_subject);
	}

	// This linear expression currently represents the equation self=0.  Destructively modify it so
	// that subject=self represents an equivalent equation.
	//
	// Precondition: subject must be one of the variables in this expression.
	// NOTES
	//   Suppose this expression is
	//     c + a*subject + a1*v1 + ... + an*vn
	//   representing
	//     c + a*subject + a1*v1 + ... + an*vn = 0
	// The modified expression will be
	//    subject = -c/a - (a1/a)*v1 - ... - (an/a)*vn
	//   representing
	//    subject = -c/a - (a1/a)*v1 - ... - (an/a)*vn
	//
	// Note that the term involving subject has been dropped.
	// Returns the reciprocal, so changeSubject can use it, too
	final double newSubject(ClAbstractVariable subject)
	{
		CL.fnenterprint("newSubject:" ~ subject.toString());
		double coeff = _terms[subject];
		double reciprocal = 1.0 / coeff;
		multiplyMe(-reciprocal);
		return reciprocal;
	}

	// Return the coefficient corresponding to variable var, i.e.,
	// the 'ci' corresponding to the 'vi' that var is:
	//     v1*c1 + v2*c2 + .. + vn*cn + c
	final double coefficientFor(ClAbstractVariable var)
	{
		double* coeff = var in _terms;
		return (coeff is null) ? 0.0 : *coeff;
	}

	final double constant()
	{
		return _constant;
	}

	final void set_constant(double c)
	{
		_constant = c;
	}

	final auto terms()
	{
		return _terms;
	}

	final void incrementConstant(double c)
	{
		_constant += c;
	}

	final bool isConstant()
	{
		return _terms.length == 0;
	}

	override string toString()
	{
		string res = "";

		if (!approxEqual(_constant, 0.0) || _terms.length == 0)
		{
			res ~= _constant.to!string();
		}
		else
		{
			if (_terms.length == 0)
			{
				return res;
			}

			res ~= _terms.to!string();
		}
		return res;
	}

	final static ClLinearExpression Plus(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.plus(e2);
	}

	final static ClLinearExpression Minus(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.minus(e2);
	}

	final static ClLinearExpression Times(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.times(e2);
	}

	final static ClLinearExpression Divide(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.divide(e2);
	}

	final static bool FEquals(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1 == e2;
	}

	private double _constant;
	private double[ClAbstractVariable] _terms;
}
