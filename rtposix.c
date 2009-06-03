#include <time.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>		/* mlockall etc. */
#include <sched.h>		/* sched_setscheduler, sched_getscheduler */

#ifdef __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

	int luaopen_rtposix(lua_State *L);

#ifdef __cplusplus
}
#endif


#define ERRBUF_LEN 30
#define DEBUG

#ifdef DEBUG
# define DBG(fmt, args...) printf("%s: " fmt "\n", __FUNCTION__, ##args)
#else
# define DBG(fmt, args...) do { } while(0);
#endif

/*
 * helpers
 */

static int clock_num_to_id(const char *name)
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

static void setfield(lua_State *L, const char *index, int value)
{
	lua_pushinteger(L, value);
	lua_setfield(L, -2, index);
}


/* arg: <clock id>:
 *
 * REALTIME, MONOTONIC, PROCESS_CPUTIME_ID, THREAD_CPUTIME_ID
 */

static int lua_gettime(lua_State *L)
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
static int lua_getres(lua_State *L)
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

/* args: clock_id, flags (rel|abs), sec, nsec */
static int lua_nanosleep(lua_State *L)
{
	const char *clock, *flag;
	int clock_id, flag_id;
	struct timespec req;


	clock = luaL_checkstring(L, 1);

	if((clock_id = clock_num_to_id(clock)) == -1)
		luaL_error(L, "invalid clock %s", clock);

	flag = luaL_checkstring(L, 2);

	if(!strcmp(flag, "rel"))
		flag_id = 0;
	else if(!strcmp(flag, "abs"))
		flag_id = TIMER_ABSTIME;
	else
		luaL_error(L, "invalid flag %s", flag);


	req.tv_sec = lua_tointeger(L, 3);
	req.tv_nsec = lua_tointeger(L, 4);

	if(!clock_nanosleep(clock_id, flag_id, &req, NULL))
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	return 1;
}

/*
 * mlockall
 *
 * args: flag MCL_CURRENT | MCL_FUTURE
 */

static int lua_mlockall(lua_State *L)
{
	const char *str_flag;
	char errbuf[ERRBUF_LEN];
	int flag, ret;

	str_flag = luaL_checkstring(L, 1);

	if(!strcmp(str_flag, "MCL_CURRENT")) {
		flag = MCL_CURRENT;
		DBG("MCL_CURRENT");
	}

	if(!strcmp(str_flag, "MCL_FUTURE")) {
		flag = MCL_FUTURE;
		DBG("MCL_FUTURE");
	}

	if(!strcmp(str_flag, "MCL_BOTH")) {
		flag = MCL_CURRENT | MCL_FUTURE;
		DBG("MCL_BOTH (MCL_CURRENT | MCL_FUTURE)");
	}

	ret = mlockall(flag);

	if(ret < 0) {
		strerror_r(errno, errbuf, ERRBUF_LEN);
		luaL_error(L, errbuf);
	}

	lua_pushboolean(L, 1);
	return 1;
}

static int lua_munlockall(lua_State *L)
{
	int ret;
	char errbuf[ERRBUF_LEN];

	DBG("");
	ret = munlockall();

	if(ret < 0) {
		strerror_r(errno, errbuf, ERRBUF_LEN);
		luaL_error(L, errbuf);
	}

	lua_pushboolean(L, 1);
	return 1;
}

static int lua_sched_setscheduler(lua_State *L)
{
	int prio, pid, policy;
	const char *str_policy;
	char errbuf[ERRBUF_LEN];
	struct sched_param schedp;

	memset(&schedp, 0, sizeof(schedp));

	pid = luaL_checknumber(L, 1);
	str_policy = luaL_checkstring(L, 2);
	prio = luaL_checknumber(L, 3);

	if(!strcmp(str_policy, "SCHED_FIFO")) {
		policy = SCHED_FIFO;
		schedp.sched_priority = prio;
	} else if (!strcmp(str_policy, "SCHED_RR")) {
		policy = SCHED_RR;
		schedp.sched_priority = prio;
	} else if (!strcmp(str_policy, "SCHED_OTHER")) {
		policy = SCHED_OTHER;
		schedp.sched_priority = 0;
	} else {
		luaL_error(L, "invalid scheduling policy: %s", str_policy);
	}

	DBG("pid=%d, policy=%s, prio=%d", pid, str_policy, prio);

	if(sched_setscheduler(pid, policy, &schedp)) {
		strerror_r(errno, errbuf, ERRBUF_LEN);
		luaL_error(L, errbuf);
	}

	lua_pushboolean(L, 1);
	return 1;
}

static const struct luaL_Reg rtposix [] = {
	{"gettime", lua_gettime},
	{"getres", lua_getres},
	{"nanosleep", lua_nanosleep},
	{"mlockall", lua_mlockall},
	{"munlockall", lua_munlockall},
	{"sched_setscheduler", lua_sched_setscheduler},
	{NULL, NULL}
};

int luaopen_rtposix(lua_State *L) {
	luaL_register(L, "rtposix", rtposix);
	return 1;
}
