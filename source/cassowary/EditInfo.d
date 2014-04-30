module cassowary.EditInfo;

import cassowary.Constraint;
import cassowary.SlackVariable;

protected class ClEditInfo
{
	this(ClConstraint cn_, ClSlackVariable eplus_, ClSlackVariable eminus_, double prevEditConstant_, size_t i_)
	{
		cn = cn_;
		clvEditPlus = eplus_;
		clvEditMinus = eminus_;
		prevEditConstant = prevEditConstant_;
		i = i_;
	}

	size_t Index() const
	{
		return i;
	}

	ClConstraint Constraint()
	{
		return cn;
	}

	ClSlackVariable ClvEditPlus()
	{
		return clvEditPlus;
	}

	ClSlackVariable ClvEditMinus()
	{
		return clvEditMinus;
	}

	double PrevEditConstant() const
	{
		return prevEditConstant;
	}

	void SetPrevEditConstant(double prevEditConstant_)
	{
		prevEditConstant = prevEditConstant_;
	}

	private ClConstraint cn;
	private ClSlackVariable clvEditPlus;
	private ClSlackVariable clvEditMinus;
	private double prevEditConstant;
	private size_t i;
}
