module cassowary.SimplexSolver;

import std.array;
import std.conv;
import std.stdio;
import std.math;

import cassowary.Tableau;
import cassowary.AbstractVariable;
import cassowary.Constraint;
import cassowary.Variable;
import cassowary.Strength;
import cassowary.Point;
import cassowary.LinearExpression;
import cassowary.LinearInequality;
import cassowary.ObjectiveVariable;
import cassowary.set;
import cassowary.EditInfo;
import cassowary.Cl;
import cassowary.Error;
import cassowary.EditConstraint;
import cassowary.StayConstraint;
import cassowary.SlackVariable;
import cassowary.DummyVariable;
import cassowary.SymbolicWeight;


class ClSimplexSolver : ClTableau
{
	// Ctr initializes the fields, and creates the objective row
	this()
	{
		_resolve_pair = [0, 0];
		_objective = new ClObjectiveVariable("Z");

		_slackCounter = 0;
		_artificialCounter = 0;
		_dummyCounter = 0;
		_epsilon = 1e-8;

		_fOptimizeAutomatically = true;
		_fNeedsSolving = false;

		ClLinearExpression e = new ClLinearExpression();
		_rows[_objective] = e;
		_stkCedcns = [0];

		traceprint("objective expr == " ~ rowExpression(_objective).toString());
	}

	// Convenience function for creating a linear inequality constraint
	final ClSimplexSolver addLowerBound(ClAbstractVariable v, double lower)
	{
		ClLinearInequality cn = new ClLinearInequality(v, InequalityType.GEQ, new ClLinearExpression(lower));
		return addConstraint(cn);
	}

	// Convenience function for creating a linear inequality constraint
	final ClSimplexSolver addUpperBound(ClAbstractVariable v, double upper)
	{
		ClLinearInequality cn = new ClLinearInequality(v, InequalityType.LEQ, new ClLinearExpression(upper));
		return addConstraint(cn);
	}

	// Convenience function for creating a pair of linear inequality constraint
	final ClSimplexSolver addBounds(ClAbstractVariable v, double lower, double upper)
	{
		addLowerBound(v, lower); addUpperBound(v, upper); return this;
	}

	// Add constraint "cn" to the solver
	final ClSimplexSolver addConstraint(ClConstraint cn)
	{
		fnenterprint("addConstraint: " ~ cn.toString());

		ClAbstractVariable[] eplus_eminus;
		double prevEConstant = 0;
		ClLinearExpression expr = newExpression(cn,         /* output to: */
												eplus_eminus, prevEConstant);
		bool fAddedOkDirectly = false;

		try
		{
			fAddedOkDirectly = tryAddingDirectly(expr);
			if (!fAddedOkDirectly)
			{
				// could not add directly
				addWithArtificialVariable(expr);
			}
		}
		catch (ClErrorRequiredFailure err)
		{
			///try {
			///        removeConstraint(cn); // FIXGJB
			//      } catch (ClErrorConstraintNotFound errNF) {
			// This should not possibly happen
			/// System.err.println("ERROR: could not find a constraint just added\n");
			///}
			throw err;
		}

		_fNeedsSolving = true;

		if (cn.isEditConstraint())
		{
			auto i = _editVarMap.length;
			ClEditConstraint cnEdit = cast(ClEditConstraint) cn;
			ClSlackVariable clvEplus = cast(ClSlackVariable) eplus_eminus[0];
			ClSlackVariable clvEminus = cast(ClSlackVariable) eplus_eminus[1];

			_editVarMap[cnEdit.variable()] = new ClEditInfo(cnEdit, clvEplus, clvEminus,
															prevEConstant,
															cast(int)i);
		}

		if (_fOptimizeAutomatically)
		{
			optimize(_objective);
			setExternalVariables();
		}

		return this;
	}

	// Same as addConstraint, except returns false if the constraint
	// resulted in an unsolvable system (instead of throwing an exception)
	final bool addConstraintNoException(ClConstraint cn)
	{
		fnenterprint("addConstraintNoException: " ~ cn.toString());

		try
		{
			addConstraint(cn);
			return true;
		}
		catch (ClErrorRequiredFailure e)
		{
			return false;
		}
	}

	// Add an edit constraint for "v" with given strength
	final ClSimplexSolver addEditVar(ClVariable v, ClStrength strength)
	{
		try
		{
			ClEditConstraint cnEdit = new ClEditConstraint(v, strength);
			return addConstraint(cnEdit);
		}
		catch (ClErrorRequiredFailure e)
		{
			// should not get this
			throw new ClErrorInternal("Required failure when adding an edit variable");
		}
	}

	// default to strength = strong
	final ClSimplexSolver addEditVar(ClVariable v)
	{
		return addEditVar(v, ClStrength.strong);
	}

	// Remove the edit constraint previously added for variable v
	final ClSimplexSolver removeEditVar(ClVariable v)
	{
		ClEditInfo cei = _editVarMap[v];
		ClConstraint cn = cei.Constraint();
		removeConstraint(cn);
		return this;
	}

	// beginEdit() should be called before sending
	// resolve() messages, after adding the appropriate edit variables
	final ClSimplexSolver beginEdit()
	{
		assert(_editVarMap.length > 0, "_editVarMap.length() > 0");
		// may later want to do more in here
		_infeasibleRows.clear();
		resetStayConstants();
		_stkCedcns ~= cast(int) _editVarMap.length;
		return this;
	}

	// endEdit should be called after editing has finished
	// for now, it just removes all edit variables
	final ClSimplexSolver endEdit()
	{
		assert(_editVarMap.length > 0, "_editVarMap.length() > 0");
		resolve();
		_stkCedcns.popBack();
		int n = _stkCedcns[$-1];
		removeEditVarsTo(n);
		// may later want to do more in here
		return this;
	}

	// removeAllEditVars() just eliminates all the edit constraints
	// that were added
	final ClSimplexSolver removeAllEditVars()
	{
		return removeEditVarsTo(0);
	}

	// remove the last added edit vars to leave only n edit vars left
	final ClSimplexSolver removeEditVarsTo(int n)
	{
		try
		{
			foreach(ClVariable v, ClEditInfo cei; _editVarMap)
			{
				if (cei.Index() >= n)
				{
					removeEditVar(v);
				}
			}
			assert(_editVarMap.length == n, "_editVarMap.length() == n");

			return this;
		}
		catch (ClErrorConstraintNotFound e)
		{
			// should not get this
			throw new ClErrorInternal("Constraint not found in removeEditVarsTo");
		}
	}

	// Add weak stays to the x and y parts of each point. These have
	// increasing weights so that the solver will try to satisfy the x
	// and y stays on the same point, rather than the x stay on one and
	// the y stay on another.
	final ClSimplexSolver addPointStays(ClPoint[] listOfPoints)
	{
		fnenterprint("addPointStays" ~ listOfPoints.to!string());
		double weight = 1.0;
		double multiplier = 2.0;
		foreach(p; listOfPoints)
		{
			addPointStay(p, weight);
			weight *= multiplier;
		}
		return this;
	}

	final ClSimplexSolver addPointStay(ClVariable vx, ClVariable vy, double weight)
	{
		addStay(vx, ClStrength.weak, weight);
		addStay(vy, ClStrength.weak, weight);
		return this;
	}

	final ClSimplexSolver addPointStay(ClVariable vx, ClVariable vy)
	{
		addPointStay(vx, vy, 1.0);
		return this;
	}

	final ClSimplexSolver addPointStay(ClPoint clp, double weight)
	{
		addStay(clp.X(), ClStrength.weak, weight);
		addStay(clp.Y(), ClStrength.weak, weight);
		return this;
	}

	final ClSimplexSolver addPointStay(ClPoint clp)
	{
		addPointStay(clp, 1.0);
		return this;
	}

	// Add a stay of the given strength (default to weak) of v to the tableau
	final ClSimplexSolver addStay(ClVariable v, ClStrength strength, double weight)
	{
		ClStayConstraint cn = new ClStayConstraint(v, strength, weight);
		return addConstraint(cn);
	}

	// default to weight == 1.0
	final ClSimplexSolver addStay(ClVariable v, ClStrength strength)
	{
		addStay(v, strength, 1.0);
		return this;
	}

	// default to strength = weak
	final ClSimplexSolver addStay(ClVariable v)
	{
		addStay(v, ClStrength.weak, 1.0);
		return this;
	}


	// Remove the constraint cn from the tableau
	// Also remove any error variable associated with cn
	final ClSimplexSolver removeConstraint(ClConstraint cn)
	{
		fnenterprint("removeConstraint: " ~ cn.toString());
		traceprint(this.toString());

		_fNeedsSolving = true;

		resetStayConstants();

		ClLinearExpression zRow = rowExpression(_objective);

		auto eVars = _errorVars.get(cn, null);
		traceprint("eVars == " ~ eVars.to!string());

		if (eVars !is null)
		{
			foreach(ClAbstractVariable clv; eVars)
			{
				ClLinearExpression expr = rowExpression(clv);
				if (expr is null )
				{
					zRow.addVariable(clv, -cn.weight() *
									 cn.strength().symbolicWeight().asDouble(),
									 _objective, this);
				}
				else                 // the error variable was in the basis
				{
					zRow.addExpression(expr, -cn.weight() *
									   cn.strength().symbolicWeight().asDouble(),
									   _objective, this);
				}
			}
		}

		ClAbstractVariable marker = _markerVars.get(cn, null);

		if (marker is null)
		{
			throw new ClErrorConstraintNotFound();
		}

		_markerVars.remove(cn);

		traceprint("Looking to remove var " ~ marker.toString());

		if (rowExpression(marker) is null )
		{
			// not in the basis, so need to do some work
			auto col = _columns[marker];

			traceprint("Must pivot -- columns are " ~ col.toString());

			ClAbstractVariable exitVar = null;
			double minRatio = 0.0;
			foreach(ClAbstractVariable v; col)
			{
				if (v.isRestricted() )
				{
					ClLinearExpression expr = rowExpression( v);
					double coeff = expr.coefficientFor(marker);
					traceprint("Marker " ~ marker.to!string() ~ "'s coefficient in " ~ expr.toString() ~ " is " ~ coeff.to!string());
					if (coeff < 0.0)
					{
						double r = -expr.constant() / coeff;
						if (exitVar is null || r < minRatio)
						{
							minRatio = r;
							exitVar = v;
						}
					}
				}
			}
			if (exitVar is null )
			{
				traceprint("exitVar is still null");
				foreach (ClAbstractVariable v; col)
				{
					if (v.isRestricted() )
					{
						ClLinearExpression expr = rowExpression(v);
						double coeff = expr.coefficientFor(marker);
						double r = expr.constant() / coeff;
						if (exitVar is null || r < minRatio)
						{
							minRatio = r;
							exitVar = v;
						}
					}
				}
			}

			if (exitVar is null)
			{
				// exitVar is still null
				if (col.length == 0)
				{
					removeColumn(marker);
				}
				else
				{
					exitVar = col.anyElement;
				}
			}

			if (exitVar !is null)
			{
				pivot(marker, exitVar);
			}
		}

		if (rowExpression(marker) !is null )
		{
			ClLinearExpression expr = removeRow(marker);
			expr = null;
		}

		if (eVars !is null)
		{
			foreach(ClAbstractVariable v; eVars)
			{
				// FIXGJBNOW != or equals?
				if ( v != marker )
				{
					removeColumn(v);
					v = null;
				}
			}
		}

		if (cn.isStayConstraint())
		{
			if (eVars !is null)
			{
				for (int i = 0; i < _stayPlusErrorVars.length; i++)
				{
					eVars.remove(_stayPlusErrorVars[i]);
					eVars.remove(_stayMinusErrorVars[i]);
				}
			}
		}
		else if (cn.isEditConstraint())
		{
			assert(eVars !is null, "eVars != null");
			ClEditConstraint cnEdit = cast(ClEditConstraint) cn;
			ClVariable clv = cnEdit.variable();
			ClEditInfo cei = _editVarMap[clv];
			ClSlackVariable clvEditMinus = cei.ClvEditMinus();
			//      ClSlackVariable clvEditPlus = cei.ClvEditPlus();
			// the clvEditPlus is a marker variable that is removed elsewhere
			removeColumn( clvEditMinus );
			_editVarMap.remove(clv);
		}

		// FIXGJB do the remove at top
		if (eVars !is null)
		{
			_errorVars.remove(cn);
		}
		marker = null;

		if (_fOptimizeAutomatically)
		{
			optimize(_objective);
			setExternalVariables();
		}

		return this;
	}

	// Re-initialize this solver from the original constraints, thus
	// getting rid of any accumulated numerical problems.  (Actually, we
	// haven't definitely observed any such problems yet)
	final void reset()
	{
		fnenterprint("reset");
		throw new ClErrorInternal("reset not implemented");
	}

	// Re-solve the current collection of constraints for new values for
	// the constants of the edit variables.
	// DEPRECATED:  use suggestValue(...) then resolve()
	// If you must use this, be sure to not use it if you
	// remove an edit variable (or edit constraint) from the middle
	// of a list of edits and then try to resolve with this function
	// (you'll get the wrong answer, because the indices will be wrong
	// in the ClEditInfo objects)
	final void resolve(double[] newEditConstants)
	{
		fnenterprint("resolve" ~ newEditConstants.to!string());
		foreach(ClVariable v, ClEditInfo cei; _editVarMap)
		{
			int i = cei.Index();
			try
			{
				if (i < newEditConstants.length)
					suggestValue(v, newEditConstants[i]);
			}
			catch (ClError err)
			{
				throw new ClErrorInternal("Error during resolve");
			}
		}
		resolve();
	}

	// Convenience function for resolve-s of two variables
	final void resolve(double x, double y)
	{
		_resolve_pair[0] = x;
		_resolve_pair[1] = y;
		resolve(_resolve_pair);
	}

	// Re-solve the cuurent collection of constraints, given the new
	// values for the edit variables that have already been
	// suggested (see suggestValue() method)
	final void resolve()
	{
		fnenterprint("resolve()");
		dualOptimize();
		setExternalVariables();
		_infeasibleRows.clear();
		resetStayConstants();
	}

	// Suggest a new value for an edit variable
	// the variable needs to be added as an edit variable
	// and beginEdit() needs to be called before this is called.
	// The tableau will not be solved completely until
	// after resolve() has been called
	final ClSimplexSolver suggestValue(ClVariable v, double x)
	{
		fnenterprint("suggestValue(" ~ v.toString() ~ ", " ~ x.to!string() ~ ")");
		ClEditInfo cei = _editVarMap.get(v, null);
		if (cei is null)
		{
			writeln("suggestValue for variable " ~ v.toString() ~ ", but var is not an edit variable\n");
			throw new ClError();
		}
		int i = cei.Index();
		ClSlackVariable clvEditPlus = cei.ClvEditPlus();
		ClSlackVariable clvEditMinus = cei.ClvEditMinus();
		double delta = x - cei.PrevEditConstant();
		cei.SetPrevEditConstant(x);
		deltaEditConstant(delta, clvEditPlus, clvEditMinus);
		return this;
	}

	// Control whether optimization and setting of external variables
	// is done automatically or not.  By default it is done
	// automatically and solve() never needs to be explicitly
	// called by client code; if setAutosolve is put to false,
	// then solve() needs to be invoked explicitly before using
	// variables' values
	// (Turning off autosolve while adding lots and lots of
	// constraints [ala the addDel test in ClTests] saved
	// about 20% in runtime, from 68sec to 54sec for 900 constraints,
	// with 126 failed adds)
	final ClSimplexSolver setAutosolve(bool f)
	{
		_fOptimizeAutomatically = f;
		return this;
	}

	// Tell whether we are autosolving
	final bool FIsAutosolving()
	{
		return _fOptimizeAutomatically;
	}

	// If autosolving has been turned off, client code needs
	// to explicitly call solve() before accessing variables
	// values
	final ClSimplexSolver solve()
	{
		if (_fNeedsSolving)
		{
			optimize(_objective);
			setExternalVariables();
		}
		return this;
	}

	ClSimplexSolver setEditedValue(ClVariable v, double n)
	{
		if (!FContainsVariable(v))
		{
			v.change_value(n);
			return this;
		}

		if (!approxEqual(n, v.value()))
		{
			addEditVar(v);
			beginEdit();
			try
			{
				suggestValue(v, n);
			}
			catch (ClError e)
			{
				// just added it above, so we shouldn't get an error
				throw new ClErrorInternal("Error in setEditedValue");
			}
			endEdit();
		}
		return this;
	}

	final bool FContainsVariable(ClVariable v)
	{
		return columnsHasKey(v) || (rowExpression(v) !is null);
	}

	ClSimplexSolver addVar(ClVariable v)
	{
		if (!FContainsVariable(v))
		{
			try
			{
				addStay(v);
			}
			catch (ClErrorRequiredFailure e)
			{
				// cannot have a required failure, since we add w/ weak
				throw new ClErrorInternal("Error in addVar -- required failure is impossible");
			}
			traceprint("added initial stay on " ~ v.toString());
		}
		return this;
	}

	// Originally from Michael Noth <noth@cs>
	override string getInternalInfo() {
		string res = super.getInternalInfo();
		res ~= ("\nSolver info:\n");
		res ~= ("Stay Error Variables: ");
		res ~= (_stayPlusErrorVars.length - _stayMinusErrorVars.length).to!string();
		res ~= (" (" ~ _stayPlusErrorVars.length.to!string() ~ " +, ");
		res ~= (_stayMinusErrorVars.length.to!string() ~ " -)\n");
		res ~= ("Edit Variables: " ~ _editVarMap.length.to!string());
		res ~= ("\n");
		return res;
	}

	final string getDebugInfo() {
		string res = toString();
		res ~= getInternalInfo();
		return res;
	}

	override string toString()
	{
		string res = super.toString();
		res ~= ("\n_stayPlusErrorVars: ");
		res ~= (_stayPlusErrorVars.to!string());
		res ~= ("\n_stayMinusErrorVars: ");
		res ~= (_stayMinusErrorVars.to!string());

		res ~= ("\n");
		return res;
	}

	auto getConstraintMap()
	{
		return _markerVars;
	}

	//// END PUBLIC INTERFACE

	// Add the constraint expr=0 to the inequality tableau using an
	// artificial variable.  To do this, create an artificial variable
	// av and add av=expr to the inequality tableau, then make av be 0.
	// (Raise an exception if we can't attain av=0.)
	protected final void addWithArtificialVariable(ClLinearExpression expr)
	{
		fnenterprint("addWithArtificialVariable: " ~ expr.toString());

		ClSlackVariable av = new ClSlackVariable(++_artificialCounter, "a");
		ClObjectiveVariable az = new ClObjectiveVariable("az");
		ClLinearExpression azRow = cast(ClLinearExpression) expr.clone();

		traceprint("before addRows:\n" ~ toString());

		addRow( az, azRow);
		addRow( av, expr);

		traceprint("after addRows:\n" ~ toString());
		optimize(az);

		ClLinearExpression azTableauRow = rowExpression(az);

		traceprint("azTableauRow.constant() == " ~ azTableauRow.constant().to!string());

		if (!approxEqual(azTableauRow.constant(), 0.0))
		{
			removeRow(az);
			removeColumn(av);
			throw new ClErrorRequiredFailure();
		}

		// See if av is a basic variable
		ClLinearExpression e = rowExpression(av);

		if (e !is null )
		{
			// find another variable in this row and pivot,
			// so that av becomes parametric
			if (e.isConstant())
			{
				// if there isn't another variable in the row
				// then the tableau contains the equation av=0 --
				// just delete av's row
				removeRow(av);
				removeRow(az);
				return;
			}
			ClAbstractVariable entryVar = e.anyPivotableVariable();
			pivot( entryVar, av);
		}
		assert(rowExpression(av) is null, "rowExpression(av) is null");
		removeColumn(av);
		removeRow(az);
	}

	// We are trying to add the constraint expr=0 to the appropriate
	// tableau.  Try to add expr directly to the tableax without
	// creating an artificial variable.  Return true if successful and
	// false if not.
	protected final bool tryAddingDirectly(ClLinearExpression expr)
	{
		fnenterprint("tryAddingDirectly: " ~ expr.toString() );
		ClAbstractVariable subject = chooseSubject(expr);
		if (subject is null )
		{
			fnexitprint("returning false");
			return false;
		}
		expr.newSubject( subject);
		if (columnsHasKey( subject))
		{
			substituteOut( subject, expr);
		}
		addRow( subject, expr);
		fnexitprint("returning true");
		return true;         // successfully added directly
	}

	// We are trying to add the constraint expr=0 to the tableaux.  Try
	// to choose a subject (a variable to become basic) from among the
	// current variables in expr.  If expr contains any unrestricted
	// variables, then we must choose an unrestricted variable as the
	// subject.  Also, if the subject is new to the solver we won't have
	// to do any substitutions, so we prefer new variables to ones that
	// are currently noted as parametric.  If expr contains only
	// restricted variables, if there is a restricted variable with a
	// negative coefficient that is new to the solver we can make that
	// the subject.  Otherwise we can't find a subject, so return nil.
	// (In this last case we have to add an artificial variable and use
	// that variable as the subject -- this is done outside this method
	// though.)
	//
	// Note: in checking for variables that are new to the solver, we
	// ignore whether a variable occurs in the objective function, since
	// new slack variables are added to the objective function by
	// 'newExpression:', which is called before this method.
	protected final ClAbstractVariable chooseSubject(ClLinearExpression expr)
	{
		fnenterprint("chooseSubject: " ~ expr.toString());
		ClAbstractVariable subject = null;         // the current best subject, if any

		bool foundUnrestricted = false;
		bool foundNewRestricted = false;

		auto terms = expr.terms();

		foreach(ClAbstractVariable v, double c; terms)
		{
			if (foundUnrestricted)
			{
				if (!v.isRestricted())
				{
					if (!columnsHasKey(v))
						return v;
				}
			}
			else
			{
				// we haven't found an restricted variable yet
				if (v.isRestricted())
				{
					if (!foundNewRestricted && !v.isDummy() && c < 0.0)
					{
						auto col = _columns.get(v, null);
						if (col is null ||
							(col.length == 1 && columnsHasKey(_objective) ) )
						{
							subject = v;
							foundNewRestricted = true;
						}
					}
				}
				else
				{
					subject = v;
					foundUnrestricted = true;
				}
			}
		}

		if (subject !is null)
			return subject;

		double coeff = 0.0;

		foreach(ClAbstractVariable v, double c; terms)
		{
			if (!v.isDummy())
				return null;                 // nope, no luck
			if (!columnsHasKey(v))
			{
				subject = v;
				coeff = c;
			}
		}

		if (!approxEqual(expr.constant(), 0.0))
		{
			throw new ClErrorRequiredFailure();
		}
		if (coeff > 0.0)
		{
			expr.multiplyMe(-1);
		}
		return subject;
	}

	// Each of the non-required edits will be represented by an equation
	// of the form
	//    v = c + eplus - eminus
	// where v is the variable with the edit, c is the previous edit
	// value, and eplus and eminus are slack variables that hold the
	// error in satisfying the edit constraint.  We are about to change
	// something, and we want to fix the constants in the equations
	// representing the edit constraints.  If one of eplus and eminus is
	// basic, the other must occur only in the expression for that basic
	// error variable.  (They can't both be basic.)  Fix the constant in
	// this expression.  Otherwise they are both nonbasic.  Find all of
	// the expressions in which they occur, and fix the constants in
	// those.  See the UIST paper for details.
	// (This comment was for resetEditConstants(), but that is now
	// gone since it was part of the screwey vector-based interface
	// to resolveing. --02/16/99 gjb)
	protected final void deltaEditConstant(double delta,
										   ClAbstractVariable plusErrorVar,
										   ClAbstractVariable minusErrorVar)
	{
		fnenterprint("deltaEditConstant :" ~ delta.to!string() ~ ", " ~ plusErrorVar.toString() ~ ", " ~ minusErrorVar.toString());
		ClLinearExpression exprPlus = rowExpression(plusErrorVar);
		if (exprPlus !is null )
		{
			exprPlus.incrementConstant(delta);

			if (exprPlus.constant() < 0.0)
			{
				_infeasibleRows.insert(plusErrorVar);
			}
			return;
		}

		ClLinearExpression exprMinus = rowExpression(minusErrorVar);
		if (exprMinus !is null)
		{
			exprMinus.incrementConstant(-delta);
			if (exprMinus.constant() < 0.0)
			{
				_infeasibleRows.insert(minusErrorVar);
			}
			return;
		}

		auto columnVars = _columns[minusErrorVar];

		foreach(ClAbstractVariable basicVar; columnVars)
		{
			ClLinearExpression expr = rowExpression(basicVar);
			//assert(expr != null, "expr != null" );
			double c = expr.coefficientFor(minusErrorVar);
			expr.incrementConstant(c * delta);
			if (basicVar.isRestricted() && expr.constant() < 0.0)
			{
				_infeasibleRows.insert(basicVar);
			}
		}
	}

	// We have set new values for the constants in the edit constraints.
	// Re-optimize using the dual simplex algorithm.
	protected final void dualOptimize()
	{
		fnenterprint("dualOptimize:");
		ClLinearExpression zRow = rowExpression(_objective);
		while (!_infeasibleRows.isEmpty())
		{
			ClAbstractVariable exitVar = _infeasibleRows.anyElement;
			_infeasibleRows.remove(exitVar);
			ClAbstractVariable entryVar = null;
			ClLinearExpression expr = rowExpression(exitVar);
			if (expr !is null )
			{
				if (expr.constant() < 0.0)
				{
					double ratio = double.max;
					double r;
					foreach(ClAbstractVariable v, double c; expr.terms())
					{
						if (c > 0.0 && v.isPivotable())
						{
							double zc = zRow.coefficientFor(v);
							r = zc/c;                             // FIXGJB r:= zc/c or zero, as ClSymbolicWeight-s
							if (r < ratio)
							{
								entryVar = v;
								ratio = r;
							}
						}
					}
					if (ratio == double.max)
					{
						throw new ClErrorInternal("ratio == nil (MAX_VALUE) in dualOptimize");
					}
					pivot( entryVar, exitVar);
				}
			}
		}
	}

	// Make a new linear expression representing the constraint cn,
	// replacing any basic variables with their defining expressions.
	// Normalize if necessary so that the constant is non-negative.  If
	// the constraint is non-required give its error variables an
	// appropriate weight in the objective function.
	protected final ClLinearExpression newExpression(ClConstraint cn,
													 ref ClAbstractVariable[] eplus_eminus,
													 ref double prevEConstant)
	{
		fnenterprint("newExpression: " ~ cn.toString());
		traceprint("cn.isInequality() == " ~ cn.isInequality().to!string());
		traceprint("cn.isRequired() == " ~ cn.isRequired().to!string());

		ClLinearExpression cnExpr = cn.expression();
		ClLinearExpression expr = new ClLinearExpression(cnExpr.constant());
		ClSlackVariable slackVar = new ClSlackVariable();
		ClDummyVariable dummyVar = new ClDummyVariable();
		ClSlackVariable eminus = new ClSlackVariable();
		ClSlackVariable eplus = new ClSlackVariable();
		foreach(ClAbstractVariable v, double c; cnExpr.terms())
		{
			ClLinearExpression e = rowExpression(v);
			if (e is null)
				expr.addVariable(v, c);
			else
				expr.addExpression(e, c);
		}

		import std.stdio;

		if (cn.isInequality())
		{
			++_slackCounter;
			slackVar = new ClSlackVariable (_slackCounter, "s");
			expr.setVariable(slackVar, -1);
			_markerVars[cn] = slackVar;
			if (!cn.isRequired())
			{
				++_slackCounter;
				eminus = new ClSlackVariable(_slackCounter, "em");
				expr.setVariable(eminus, 1.0);
				ClLinearExpression zRow = rowExpression(_objective);
				ClSymbolicWeight sw = cn.strength().symbolicWeight().times(cn.weight());
				zRow.setVariable( eminus, sw.asDouble());
				insertErrorVar(cn, eminus);
				noteAddedVariable(eminus, _objective);
			}
		}
		else
		{
			// cn is an equality
			if (cn.isRequired())
			{
				++_dummyCounter;
				dummyVar = new ClDummyVariable(_dummyCounter, "d");
				expr.setVariable(dummyVar, 1.0);
				_markerVars[cn] = dummyVar;
				traceprint("Adding dummyVar == d" ~ _dummyCounter.to!string());
			}
			else
			{
				++_slackCounter;

				eplus = new ClSlackVariable (_slackCounter, "ep");
				eminus = new ClSlackVariable (_slackCounter, "em");

				expr.setVariable( eplus, -1.0);
				expr.setVariable( eminus, 1.0);

				_markerVars[cn] = eplus;
				ClLinearExpression zRow = rowExpression(_objective);
				ClSymbolicWeight sw = cn.strength().symbolicWeight().times(cn.weight());
				double swCoeff = sw.asDouble();

				if (swCoeff == 0)
				{
					traceprint("sw == " ~ sw.to!string());
					traceprint("cn == " ~ cn.to!string());
					traceprint("adding " ~ eplus.to!string() ~ " and " ~ eminus.to!string() ~ " with swCoeff == " ~ swCoeff.to!string());
				}

				zRow.setVariable(eplus, swCoeff);
				noteAddedVariable(eplus, _objective);
				zRow.setVariable(eminus, swCoeff);

				noteAddedVariable(eminus, _objective);

				insertErrorVar(cn, eminus);

				insertErrorVar(cn, eplus);

				if (cn.isStayConstraint())
				{
					_stayPlusErrorVars ~= eplus;
					_stayMinusErrorVars ~= eminus;
				}
				else if (cn.isEditConstraint())
				{
					eplus_eminus ~= eplus;
					eplus_eminus ~= eminus;
					prevEConstant = cnExpr.constant();
				}
			}
		}

		if (expr.constant() < 0)
			expr.multiplyMe(-1);

		fnexitprint("returning " ~ expr.to!string());
		return expr;
	}

	// Minimize the value of the objective.  (The tableau should already
	// be feasible.)
	protected final void optimize(ClObjectiveVariable zVar)
	{
		fnenterprint("optimize: " ~ zVar.toString());
		traceprint(this.toString());

		ClLinearExpression zRow = rowExpression(zVar);
		assert(zRow !is null, "zRow != null");
		ClAbstractVariable entryVar = null;
		ClAbstractVariable exitVar = null;
		while (true)
		{
			double objectiveCoeff = 0;
			foreach(ClAbstractVariable v, double c; zRow.terms())
			{
				if (v.isPivotable() && c < objectiveCoeff)
				{
					objectiveCoeff = c;
					entryVar = v;
				}
			}
			if (objectiveCoeff >= -_epsilon || entryVar is null)
				return;
			traceprint("entryVar == " ~ entryVar.to!string() ~ ", objectiveCoeff == " ~ objectiveCoeff.to!string());

			double minRatio = double.max;
			double r = 0.0;
			foreach(ClAbstractVariable v; _columns[entryVar])
			{
				traceprint("Checking " ~ v.toString());
				if (v.isPivotable())
				{
					ClLinearExpression expr = rowExpression(v);
					double coeff = expr.coefficientFor(entryVar);
					traceprint("pivotable, coeff = " ~ coeff.to!string());
					if (coeff < 0.0)
					{
						r = -expr.constant() / coeff;
						if (r < minRatio)
						{
							traceprint("New minratio == " ~ r.to!string());
							minRatio = r;
							exitVar = v;
						}
					}
				}
			}
			if (minRatio == double.max)
			{
				throw new ClErrorInternal("Objective function is unbounded in optimize");
			}
			pivot(entryVar, exitVar);
			traceprint(this.toString());
		}
	}

	// Do a pivot.  Move entryVar into the basis (i.e. make it a basic variable),
	// and move exitVar out of the basis (i.e., make it a parametric variable)
	protected final void pivot(ClAbstractVariable entryVar,
							   ClAbstractVariable exitVar)
	{
		fnenterprint("pivot: " ~ entryVar.toString() ~ ", " ~ exitVar.toString());

		// the entryVar might be non-pivotable if we're doing a removeConstraint --
		// otherwise it should be a pivotable variable -- enforced at call sites,
		// hopefully

		ClLinearExpression pexpr = removeRow(exitVar);

		pexpr.changeSubject(exitVar, entryVar);
		substituteOut(entryVar, pexpr);
		addRow(entryVar, pexpr);
	}

	// Each of the non-required stays will be represented by an equation
	// of the form
	//     v = c + eplus - eminus
	// where v is the variable with the stay, c is the previous value of
	// v, and eplus and eminus are slack variables that hold the error
	// in satisfying the stay constraint.  We are about to change
	// something, and we want to fix the constants in the equations
	// representing the stays.  If both eplus and eminus are nonbasic
	// they have value 0 in the current solution, meaning the previous
	// stay was exactly satisfied.  In this case nothing needs to be
	// changed.  Otherwise one of them is basic, and the other must
	// occur only in the expression for that basic error variable.
	// Reset the constant in this expression to 0.
	protected final void resetStayConstants()
	{
		fnenterprint("resetStayConstants");

		for (int i = 0; i < _stayPlusErrorVars.length; i++)
		{
			ClLinearExpression expr = rowExpression(_stayPlusErrorVars[i]);
			if (expr is null )
				expr = rowExpression(_stayMinusErrorVars[i]);
			if (expr !is null)
				expr.set_constant(0.0);
		}
	}

	// Set the external variables known to this solver to their appropriate values.
	// Set each external basic variable to its value, and set each
	// external parametric variable to 0.  (It isn't clear that we will
	// ever have external parametric variables -- every external
	// variable should either have a stay on it, or have an equation
	// that defines it in terms of other external variables that do have
	// stays.  For the moment I'll put this in though.)  Variables that
	// are internal to the solver don't actually store values -- their
	// values are just implicit in the tableu -- so we don't need to set
	// them.
	protected final void setExternalVariables()
	{
		fnenterprint("setExternalVariables:");
		traceprint(this.toString());

		foreach(ClAbstractVariable v; _externalParametricVars)
		{
			if (rowExpression(v) !is null)
			{
				writeln("Error: variable" ~ v.toString() ~
						" in _externalParametricVars is basic");
				continue;
			}
			(cast(ClVariable)v).change_value(0.0);
		}

		foreach(ClAbstractVariable v; _externalRows)
		{
			ClLinearExpression expr = rowExpression(v);
			debugprint("v == " ~ v.toString());
			debugprint("expr == " ~ expr.toString());
			(cast(ClVariable)v).change_value(expr.constant());
		}

		_fNeedsSolving = false;
	}

	// Protected convenience function to insert an error variable into
	// the _errorVars set, creating the mapping with put as necessary
	protected final void insertErrorVar(ClConstraint cn, ClAbstractVariable var)
	{
		fnenterprint("insertErrorVar:" ~ cn.toString() ~ ", " ~ var.toString());

		auto cnset = _errorVars.get(cn, null);
		if (cnset is null)
		{
			cnset = new typeof(cnset)();
			_errorVars[cn] = cnset;
		}
		cnset.insert(var);
	}


	//// BEGIN PRIVATE INSTANCE FIELDS

	// the arrays of positive and negative error vars for the stay constraints
	// (need both positive and negative since they have only non-negative values)
	private ClAbstractVariable[] _stayMinusErrorVars;
	private ClAbstractVariable[] _stayPlusErrorVars;

	// give error variables for a non required constraint,
	// maps to ClSlackVariable-s
	private Set!ClAbstractVariable[ClConstraint] _errorVars;     // map ClConstraint to Set (of ClVariable)


	// Return a lookup table giving the marker variable for each
	// constraint (used when deleting a constraint).
	private ClAbstractVariable[ClConstraint] _markerVars;     // map ClConstraint to ClVariable

	private ClObjectiveVariable _objective;

	// Map edit variables to ClEditInfo-s.
	// ClEditInfo instances contain all the information for an
	// edit constraint (the edit plus/minus vars, the index [for old-style
	// resolve(Vector...) interface], and the previous value.
	// (ClEditInfo replaces the parallel vectors from the Smalltalk impl.)
	private ClEditInfo[ClVariable] _editVarMap;     // map ClVariable to a ClEditInfo

	private long _slackCounter;
	private long _artificialCounter;
	private long _dummyCounter;

	private double[] _resolve_pair;

	private double _epsilon;

	private bool _fOptimizeAutomatically;
	private bool _fNeedsSolving;

	private int[] _stkCedcns;
}
