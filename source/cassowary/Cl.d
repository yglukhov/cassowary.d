module cassowary.Cl;

import std.stdio;

class CL
{
	enum fDebugOn = false;
	enum fTraceOn = false;

	static void debugprint(lazy string s)
	{
		if (fTraceOn) writeln(s);
	}

	static void traceprint(lazy string s)
	{
		if (fTraceOn) writeln(s);
	}

	static void fnenterprint(lazy string s)
	{
		if (fTraceOn) writeln("* " ~ s);
	}

	static void fnexitprint(lazy string s)
	{
		if (fTraceOn) writeln("- " ~ s);
	}
}
