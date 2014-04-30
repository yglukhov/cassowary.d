module cassowary.Tableau;

import std.conv;

import cassowary.AbstractVariable;
import cassowary.LinearExpression;
import cassowary.Variable;
import cassowary.set;
import cassowary.Cl;

class ClTableau : CL
{
	// ctr is protected, since this only supports an ADT for
	// the ClSimplexSolved class
	protected this()
	{
		_infeasibleRows = new typeof(_infeasibleRows)();
		_externalRows = new typeof(_externalRows)();
		_externalParametricVars = new typeof(_externalParametricVars)();
	}

	// Variable v has been removed from an expression.  If the
	// expression is in a tableau the corresponding basic variable is
	// subject (or if subject is nil then it's in the objective function).
	// Update the column cross-indices.
	final void noteRemovedVariable(ClAbstractVariable v, ClAbstractVariable subject)
	{
		fnenterprint("noteRemovedVariable: " ~ v.toString() ~ ", " ~ subject.toString());
		if (subject !is null)
		{
			_columns[v].remove(subject);
		}
	}

	// v has been added to the linear expression for subject
	// update column cross indices
	final void noteAddedVariable(ClAbstractVariable v, ClAbstractVariable subject)
	{
		fnenterprint("noteAddedVariable: " ~ v.toString() ~ ", " ~ subject.toString());
		if (subject !is null)
		{
			insertColVar(v, subject);
		}
	}

	// Originally from Michael Noth <noth@cs>
	string getInternalInfo()
	{
		string res = "Tableau Information:\n";
		res ~= "Rows: " ~ _rows.length.to!string();

		res ~= " (= " ~ (_rows.length - 1).to!string() ~ " constraints)";
		res ~= "\nColumns: " ~ _columns.length.to!string();
		res ~= "\nInfeasible Rows: " ~ _infeasibleRows.length.to!string();
		res ~= "\nExternal basic variables: " ~ _externalRows.length.to!string();
		res ~= "\nExternal parametric variables: ";
		res ~= _externalParametricVars.length.to!string();
		res ~= "\n";

		return res;
	}

	override string toString()
	{
		string res = "Tableau:\n";

		foreach(clv, expr; _rows)
		{
			res ~= clv.toString();

			res ~= " <==> ";
			res ~= expr.toString();
			res ~= "\n";
		}

		res ~= "\nColumns:\n";
		res ~= _columns.to!string();

		res ~= "\nInfeasible rows: ";
		res ~= _infeasibleRows.toString();

		res ~= "External basic variables: ";
		res ~= _externalRows.toString();

		res ~= "External parametric variables: ";
		res ~= _externalParametricVars.toString();

		return res;
	}

	// Convenience function to insert a variable into
	// the set of rows stored at _columns[param_var],
	// creating a new set if needed
	private final void insertColVar(ClAbstractVariable param_var, ClAbstractVariable rowvar)
	{
		auto rowset = _columns.get(param_var, null);
		if (rowset is null)
		{
			rowset = new typeof(rowset)();
			_columns[param_var] = rowset;
		}
		rowset.insert(rowvar);
	}

	// Add v=expr to the tableau, update column cross indices
	// v becomes a basic variable
	// expr is now owned by ClTableau class,
	// and ClTableauis responsible for deleting it
	// (also, expr better be allocated on the heap!)
	protected final void addRow(ClAbstractVariable var, ClLinearExpression expr)
	{
		fnenterprint("addRow: " ~ var.toString() ~ ", " ~ expr.toString());

		// for each variable in expr, add var to the set of rows which
		// have that variable in their expression
		_rows[var] = expr;

		foreach(ClAbstractVariable clv, val; expr.terms())
		{
			insertColVar(clv, var);
			if (clv.isExternal())
			{
				_externalParametricVars.insert(clv);
			}
		}

		if (var.isExternal())
		{
			_externalRows.insert(var);
		}
		traceprint(this.toString());
	}

	// Remove v from the tableau -- remove the column cross indices for v
	// and remove v from every expression in rows in which v occurs
	protected final void removeColumn(ClAbstractVariable var)
	{
		fnenterprint("removeColumn:" ~ var.toString());
		// remove the rows with the variables in varset

		auto rows = _columns.get(var, null);


		if (rows !is null)
		{
			_columns.remove(var);
			foreach(ClAbstractVariable clv; rows)
			{
				ClLinearExpression expr = _rows[clv];
				expr.terms().remove(var);
			}
		}
		else
		{
			debugprint("Could not find var " ~ var.toString() ~ " in _columns");
		}

		if (var.isExternal())
		{
			_externalRows.remove(var);
			_externalParametricVars.remove(var);
		}
	}

	// Remove the basic variable v from the tableau row v=expr
	// Then update column cross indices
	protected final ClLinearExpression removeRow(ClAbstractVariable var)
	{
		fnenterprint("removeRow:" ~ var.toString());

		ClLinearExpression expr = _rows.get(var, null);
		assert(expr !is null);

		// For each variable in this expression, update
		// the column mapping and remove the variable from the list
		// of rows it is known to be in
		foreach(ClAbstractVariable clv, val; expr.terms())
		{
			auto varset = _columns.get(clv, null);
			if (varset !is null)
			{
				debugprint("removing from varset " ~ var.toString());
				varset.remove(var);
			}
		}

		_infeasibleRows.remove(var);

		if (var.isExternal())
		{
			_externalRows.remove(var);
		}
		_rows.remove(var);
		fnexitprint("returning " ~ expr.toString());
		return expr;
	}

	// Replace all occurrences of oldVar with expr, and update column cross indices
	// oldVar should now be a basic variable
	protected final void substituteOut(ClAbstractVariable oldVar, ClLinearExpression expr)
	{
		fnenterprint("substituteOut:" ~ oldVar.toString() ~ ", " ~ expr.toString());
		traceprint(this.toString());

		auto varset = _columns[oldVar];
		foreach (ClAbstractVariable v; varset)
		{
			ClLinearExpression row = _rows[v];
			row.substituteOut(oldVar, expr, v, this);
			if (v.isRestricted() && row.constant() < 0.0)
			{
				_infeasibleRows.insert(v);
			}
		}

		if (oldVar.isExternal())
		{
			_externalRows.insert(oldVar);
			_externalParametricVars.remove(oldVar);
		}
		_columns.remove(oldVar);
	}

	protected final auto columns()
	{
		return _columns;
	}

	protected final auto rows()
	{
		return _rows;
	}

	// return true iff the variable subject is in the columns keys
	protected final bool columnsHasKey(ClAbstractVariable subject)
	{
		return (subject in _columns) !is null;
	}

	protected final ClLinearExpression rowExpression(ClAbstractVariable v)
	{
		// fnenterprint("rowExpression:" + v);
		return _rows.get(v, null);
	}

	// _columns is a mapping from variables which occur in expressions to the
	// set of basic variables whose expressions contain them
	// i.e., it's a mapping from variables in expressions (a column) to the
	// set of rows that contain them
	protected Set!(ClAbstractVariable)[ClAbstractVariable] _columns; // From ClAbstractVariable to Set of variables

	// _rows maps basic variables to the expressions for that row in the tableau
	protected ClLinearExpression[ClAbstractVariable] _rows;  // From ClAbstractVariable to ClLinearExpression

	// the collection of basic variables that have infeasible rows
	// (used when reoptimizing)
	protected Set!(ClAbstractVariable) _infeasibleRows; // Set of ClAbstractVariable-s

	// the set of rows where the basic variable is external
	// this was added to the Java/C++ versions to reduce time in setExternalVariables()
	protected Set!(ClAbstractVariable) _externalRows; // Set of ClVariable-s

	// the set of external variables which are parametric
	// this was added to the Java/C++ versions to reduce time in setExternalVariables()
	protected Set!(ClAbstractVariable) _externalParametricVars; // Set of ClVariable-s
}
