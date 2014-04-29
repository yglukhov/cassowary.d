import EditOrStayConstraint;
import Variable;
import Strength;

public class ClStayConstraint : ClEditOrStayConstraint
{
	this(ClVariable var, ClStrength strength, double weight)
	{ super(var, strength, weight); }

	this(ClVariable var, ClStrength strength)
	{ super(var, strength, 1.0); }

	this(ClVariable var)
	{ super(var, ClStrength.weak, 1.0); }

	override bool isStayConstraint()
	{
		return true;
	}

	override string toString()
	{
		return "stay " ~ super.toString();
	}
}
