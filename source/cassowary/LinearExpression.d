import std.stdio;
import std.conv;

import AbstractVariable;
import Variable;
import Tableau;
import Cl;
import Error;

public class ClLinearExpression
{
	this(ClAbstractVariable clv, double value, double constant)
	{
		if (CL.fGC) writeln("new ClLinearExpression");

		_constant = constant;
		//  _terms = new typeof(_terms)();
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
		if (CL.fGC)
			writeln("clone ClLinearExpression");
		_constant = constant;
		_terms = terms.dup;
	}


	public ClLinearExpression multiplyMe(double x)
	{
		_constant *= x;

		foreach(ClAbstractVariable clv, ref val; _terms)
		{
			val *= x;
		}
		return this;
	}

	public final Object clone()
	{
		return new ClLinearExpression(_constant, _terms);
	}

	public final ClLinearExpression times(double x)
	{
		return (cast(ClLinearExpression) clone()).multiplyMe(x);
	}

	public final ClLinearExpression times(ClLinearExpression expr)
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

	public final ClLinearExpression plus(ClLinearExpression expr)
	{
		return (cast(ClLinearExpression) clone()).addExpression(expr, 1.0);
	}

	public final ClLinearExpression plus(ClVariable var)
	{
		return (cast(ClLinearExpression) clone()).addVariable(var, 1.0);
	}

	public final ClLinearExpression minus(ClLinearExpression expr)
	{
		return (cast(ClLinearExpression) clone()).addExpression(expr, -1.0);
	}

	public final ClLinearExpression minus(ClVariable var)
	{
		return (cast(ClLinearExpression) clone()).addVariable(var, -1.0);
	}


	public final ClLinearExpression divide(double x)
	{
		if (CL.approx(x, 0.0))
		{
			throw new ClErrorNonlinearExpression();
		}
		return times(1.0/x);
	}

	public final ClLinearExpression divide(ClLinearExpression expr)
	{
		if (!expr.isConstant())
		{
			throw new ClErrorNonlinearExpression();
		}
		return divide(expr._constant);
	}

	public final ClLinearExpression divFrom(ClLinearExpression expr)
	{
		if (!isConstant() || CL.approx(_constant, 0.0))
		{
			throw new ClErrorNonlinearExpression();
		}
		return expr.divide(_constant);
	}

	public final ClLinearExpression subtractFrom(ClLinearExpression expr)
	{
		return expr.minus( this);
	}

	// Add n*expr to this expression from another expression expr.
	// Notify the solver if a variable is added or deleted from this
	// expression.
	public final ClLinearExpression addExpression(ClLinearExpression expr, double n,
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
	public final ClLinearExpression addExpression(ClLinearExpression expr, double n)
	{
		incrementConstant(n * expr.constant());


		foreach(ClAbstractVariable clv, coeff; expr.terms())
		{
			addVariable(clv, coeff*n);
		}
		return this;
	}

	public final ClLinearExpression addExpression(ClLinearExpression expr)
	{
		return addExpression(expr, 1.0);
	}

	// Add a term c*v to this expression.  If the expression already
	// contains a term involving v, add c to the existing coefficient.
	// If the new coefficient is approximately 0, delete v.
	public final ClLinearExpression addVariable(ClAbstractVariable v, double c)
	{ // body largely duplicated below
		if (CL.fTraceOn) CL.fnenterprint("addVariable:" ~ v.toString() ~ ", " ~ c.to!string());

		double* coeff = v in _terms;
		if (coeff !is null)
		{
			double new_coefficient = *coeff + c;
			if (CL.approx(new_coefficient, 0.0))
			{
				_terms.remove(v);
			}
			else
			{
				*coeff = new_coefficient;
			}
		}
		else if (!CL.approx(c, 0.0))
		{
			_terms[v] = c;
		}
		return this;
	}

	public final ClLinearExpression addVariable(ClAbstractVariable v)
	{
		return addVariable(v, 1.0);
	}


	public final ClLinearExpression setVariable(ClAbstractVariable v, double c)
	{
		//assert(c != 0.0);
		_terms[v] = c;
		return this;
	}

	// Add a term c*v to this expression.  If the expression already
	// contains a term involving v, add c to the existing coefficient.
	// If the new coefficient is approximately 0, delete v.  Notify the
	// solver if v appears or disappears from this expression.
	public final ClLinearExpression addVariable(ClAbstractVariable v, double c,
												ClAbstractVariable subject, ClTableau solver)
	{  // body largely duplicated above
		if (CL.fTraceOn) CL.fnenterprint("addVariable:" ~ v.toString() ~ ", " ~ c.to!string() ~ ", " ~ subject.toString() ~ ", ...");

		double* coeff = v in _terms;
		if (coeff !is null)
		{
			double new_coefficient = *coeff + c;
			if (CL.approx(new_coefficient, 0.0))
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
			if (!CL.approx(c, 0.0))
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
	public final ClAbstractVariable anyPivotableVariable()
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
	public final void substituteOut(ClAbstractVariable var, ClLinearExpression expr,
									ClAbstractVariable subject, ClTableau solver)
	{
		if (CL.fTraceOn) CL.fnenterprint("CLE:substituteOut: " ~ var.toString() ~ ", " ~ expr.toString() ~ ", " ~ subject.toString() ~ ", ...");
		if (CL.fTraceOn) CL.traceprint("this = " ~ this.toString());

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
				if (CL.approx(newCoeff, 0.0))
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
		if (CL.fTraceOn) CL.traceprint("Now this is " ~ this.toString());
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
	public final void changeSubject(ClAbstractVariable old_subject, ClAbstractVariable new_subject)
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
	public final double newSubject(ClAbstractVariable subject)
	{
		if (CL.fTraceOn) CL.fnenterprint("newSubject:" ~ subject.toString());
		double coeff = _terms[subject];
		double reciprocal = 1.0 / coeff;
		multiplyMe(-reciprocal);
		return reciprocal;
	}

	// Return the coefficient corresponding to variable var, i.e.,
	// the 'ci' corresponding to the 'vi' that var is:
	//     v1*c1 + v2*c2 + .. + vn*cn + c
	public final double coefficientFor(ClAbstractVariable var)
	{
		double* coeff = var in _terms;
		return (coeff is null) ? 0.0 : *coeff;
	}

	public final double constant()
	{
		return _constant;
	}

	public final void set_constant(double c)
	{
		_constant = c;
	}

	public final auto terms()
	{
		return _terms;
	}

	public final void incrementConstant(double c)
	{
		_constant += c;
	}

	public final bool isConstant()
	{
		return _terms.length() == 0;
	}

	public override string toString()
	{
		string res = "";

		if (!CL.approx(_constant, 0.0) || _terms.length() == 0)
		{
			res ~= _constant.to!string();
		}
		else
		{
			if (_terms.length() == 0)
			{
				return res;
			}

			res ~= _terms.to!string();
		}
		return res;
	}

	public final static ClLinearExpression Plus(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.plus(e2);
	}

	public final static ClLinearExpression Minus(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.minus(e2);
	}

	public final static ClLinearExpression Times(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.times(e2);
	}

	public final static ClLinearExpression Divide(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1.divide(e2);
	}

	public final static bool FEquals(ClLinearExpression e1, ClLinearExpression e2)
	{
		return e1 == e2;
	}

	private double _constant;
	private double[ClAbstractVariable] _terms; // from ClVariable to ClDouble
}
