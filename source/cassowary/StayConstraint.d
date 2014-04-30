module cassowary.StayConstraint;

import cassowary.EditOrStayConstraint;
import cassowary.Variable;
import cassowary.Strength;

public class ClStayConstraint : ClEditOrStayConstraint
{
	this(ClVariable var, const ClStrength strength = ClStrength.weak, double weight = 1)
	{
		super(var, strength, weight);
	}

	override bool isStayConstraint() const
	{
		return true;
	}

	override string toString() const
	{
		return "stay " ~ super.toString();
	}
}
