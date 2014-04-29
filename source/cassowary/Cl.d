module cassowary.Cl;

import std.stdio;

class CL
{
	enum fDebugOn = false;
	enum fTraceOn = false;

	static void debugprint(string s)
	{
		writeln(s);
	}

	static void traceprint(string s)
	{
		writeln(s);
	}

	static void fnenterprint(string s)
	{
		writeln("* " ~ s);
	}

	static void fnexitprint(string s)
	{
		writeln("- " ~ s);
	}
}
