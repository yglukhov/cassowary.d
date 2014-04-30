module cassowary.EditConstraint;

import cassowary.EditOrStayConstraint;
import cassowary.Strength;
import cassowary.Variable;

public class ClEditConstraint : ClEditOrStayConstraint
{
	this(ClVariable clv, const ClStrength strength = ClStrength.required, double weight = 1)
	{
		super(clv, strength, weight);
	}

	override bool isEditConstraint() const
	{
		return true;
	}

	override string toString() const
	{
		return "edit" ~ super.toString();
	}
}
