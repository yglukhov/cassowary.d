module cassowary.EditInfo;

import cassowary.Constraint;
import cassowary.SlackVariable;

class ClEditInfo
{
	this(ClConstraint cn_,
		 ClSlackVariable eplus_, ClSlackVariable eminus_,
		 double prevEditConstant_, int i_)
	{
		cn = cn_; clvEditPlus = eplus_; clvEditMinus = eminus_;
		prevEditConstant = prevEditConstant_; i = i_;
	}

	public int Index()
	{
		return i;
	}

	public ClConstraint Constraint()
	{
		return cn;
	}

	public ClSlackVariable ClvEditPlus()
	{
		return clvEditPlus;
	}

	public ClSlackVariable ClvEditMinus()
	{
		return clvEditMinus;
	}

	public double PrevEditConstant()
	{
		return prevEditConstant;
	}

	public void SetPrevEditConstant(double prevEditConstant_ )
	{
		prevEditConstant = prevEditConstant_;
	}

	private ClConstraint cn;
	private ClSlackVariable clvEditPlus;
	private ClSlackVariable clvEditMinus;
	private double prevEditConstant;
	private int i;
}
