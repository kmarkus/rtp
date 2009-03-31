#include <time.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/* helpers */

int clock_num_to_id(const char *name)
{
	if(!strcmp(name, "REALTIME"))
		return CLOCK_REALTIME;
	else if(!strcmp(name, "MONOTONIC"))
		return CLOCK_MONOTONIC;
	else if(!strcmp(name, "PROCESS_CPUTIME"))
		return CLOCK_PROCESS_CPUTIME_ID;
	else if(!strcmp(name, "THREAD_CPUTIME"))
		return CLOCK_THREAD_CPUTIME_ID;
	else
		return -1;
}

void setfield(lua_State *L, const char *index, int value)
{
	lua_pushinteger(L, value);
	lua_setfield(L, -2, index);
}


/* arg: <clock id>:
 *
 * REALTIME, MONOTONIC, PROCESS_CPUTIME_ID, THREAD_CPUTIME_ID
 */

static int gettime(lua_State *L)
{
	const char* clock;
	int clock_id;
	struct timespec res;

	clock = luaL_checkstring(L, 1);

	if((clock_id = clock_num_to_id(clock)) == -1)
		luaL_error(L, "invalid clock %s", clock);

	clock_gettime(clock_id, &res);

	lua_newtable(L);
	setfield(L, "sec", res.tv_sec);
	setfield(L, "nsec", res.tv_nsec);

	return 1;
}

/* arg: <clock id>:
 *
 * REALTIME, MONOTONIC, PROCESS_CPUTIME_ID, THREAD_CPUTIME_ID
 */
static int getres(lua_State *L)
{
	const char* clock;
	int clock_id;
	struct timespec res;

	clock = luaL_checkstring(L, 1);

	if((clock_id = clock_num_to_id(clock)) == -1)
		luaL_error(L, "invalid clock %s", clock);

	clock_getres(clock_id, &res);

	lua_newtable(L);
	setfield(L, "sec", res.tv_sec);
	setfield(L, "nsec", res.tv_nsec);

	return 1;
}

static const struct luaL_Reg rtposix [] = {
	{"gettime", gettime},
	{"getres", getres},
	{NULL, NULL}
};

int luaopen_rtposix(lua_State *L) {
	luaL_register(L, "rtposix", rtposix);
	return 1;
}
