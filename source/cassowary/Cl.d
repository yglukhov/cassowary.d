module cassowary.Cl;

import std.stdio;

enum fDebugOn = false;
enum fTraceOn = false;

static void debugprint(lazy string s)
{
	static if (fTraceOn) writeln(s);
}

static void traceprint(lazy string s)
{
	static if (fTraceOn) writeln(s);
}

static void fnenterprint(lazy string s)
{
	static if (fTraceOn) writeln("* " ~ s);
}

static void fnexitprint(lazy string s)
{
	static if (fTraceOn) writeln("- " ~ s);
}
