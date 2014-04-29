public class ClError : Exception
{
	this()
	{
		super("(ExCLError) An error has occured in CL");
	}
}

public class ClErrorConstraintNotFound : ClError
{
	public string description()
	{
		return "(ExCLConstraintNotFound) Tried to remove a constraint never added to the tableu";
	}
}

public class ClErrorInternal : ClError
{
	this(string s)
	{
		description_ = s;
	}
	public string description()
	{
		return "(ClErrorInternal) " ~ description_;
	}

	private string description_;
}

public class ClErrorNonlinearExpression : ClError
{
	public string description()
	{
		return "(ExCLNonlinearExpression) The resulting expression would be nonlinear";
	}
}

public class ClErrorRequiredFailure : ClError
{
	public string description()
	{
		return "(ExCLRequiredFailure) A required constraint cannot be satisfied";
	}
}
