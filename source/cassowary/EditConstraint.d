import EditOrStayConstraint;
import Strength;
import Variable;

public class ClEditConstraint : ClEditOrStayConstraint
{
	this(ClVariable clv, ClStrength strength, double weight)
	{
		super(clv, strength, weight);
	}

	this(ClVariable clv, ClStrength strength)
	{
		super(clv, strength);
	}

	this(ClVariable clv)
	{
		super(clv);
	}

	override bool isEditConstraint()
	{
		return true;
	}

	override string toString()
	{
		return "edit" ~ super.toString();
	}
}