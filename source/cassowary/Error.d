module cassowary.Error;

class ClError : Exception
{
	this()
	{
		super("(ClError) An error has occured in CL");
	}

	this(string description)
	{
		super(description);
	}
}

class ClErrorConstraintNotFound : ClError
{
	this()
	{
		super("(ClErrorConstraintNotFound) Tried to remove a constraint never added to the tableu");
	}
}

class ClErrorInternal : ClError
{
	this(string s)
	{
		super("(ClErrorInternal) " ~ s);
	}
}

class ClErrorNonlinearExpression : ClError
{
	this()
	{
		super("(ClErrorNonlinearExpression) The resulting expression would be nonlinear");
	}
}

class ClErrorRequiredFailure : ClError
{
	this()
	{
		super("(ClErrorRequiredFailure) A required constraint cannot be satisfied");
	}
}
