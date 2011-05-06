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
#undef DEBUG

#ifdef DEBUG
# define DBG(fmt, args...) printf("%s: " fmt "\n", __FUNCTION__, ##args)
#else
# define DBG(fmt, args...) do { } while(0);
#endif

/*
 * helpers
 */

static const int clock_nums[] = {CLOCK_REALTIME,
				 CLOCK_MONOTONIC,
				 CLOCK_PROCESS_CPUTIME_ID,
				 CLOCK_THREAD_CPUTIME_ID};

static const char *const clock_ids[] = {"CLOCK_REALTIME",
					"CLOCK_MONOTONIC",
					"CLOCK_PROCESS_CPUTIME_ID",
					"CLOCK_THREAD_CPUTIME_ID",
					NULL};

static clockid_t check_clockid(lua_State *L, int idx)
{
	int pos = luaL_checkoption(L, idx, NULL, clock_ids);
	return clock_nums[pos];
}

static int lua_pushtimespec(lua_State *L, struct timespec *ts)
{
	lua_pushnumber(L, ts->tv_sec);
	lua_pushnumber(L, ts->tv_nsec);
	return 2;
}

/* arg: <clock id>:
 *
 * REALTIME, MONOTONIC, PROCESS_CPUTIME_ID, THREAD_CPUTIME_ID
 */
static int lua_getres(lua_State *L)
{
	clockid_t clockid;
	struct timespec res;

	clockid = check_clockid(L, 1);
	clock_getres(clockid, &res);
	return lua_pushtimespec(L, &res);
}

/* arg: <clock id>:
 *
 * REALTIME, MONOTONIC, PROCESS_CPUTIME_ID, THREAD_CPUTIME_ID
 */

static int lua_gettime(lua_State *L)
{
	clockid_t clockid;
	struct timespec res;

	clockid = check_clockid(L, 1);
	clock_gettime(clockid, &res);
	return lua_pushtimespec(L, &res);
}

/* tbd: clock_settime */

/* args: clock_id, flags (rel|abs), sec, nsec */
static int lua_nanosleep(lua_State *L)
{
	clockid_t clockid;
	const char *flag;
	int flag_id;
	struct timespec req;

	clockid = check_clockid(L, 1);

	flag = luaL_checkstring(L, 2);
	if(!strcmp(flag, "rel"))
		flag_id = 0;
	else if(!strcmp(flag, "abs"))
		flag_id = TIMER_ABSTIME;
	else
		luaL_error(L, "invalid flag %s", flag);

	req.tv_sec = luaL_checkinteger(L, 3);
	req.tv_nsec = luaL_checkinteger(L, 4);

	if(!clock_nanosleep(clockid, flag_id, &req, NULL))
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

static const int schedpol_num[] = {
	SCHED_OTHER, SCHED_FIFO, SCHED_RR
};
static const char *const schedpol_ids[] = {
	"SCHED_OTHER", "SCHED_FIFO", "SCHED_RR", NULL
};

static int check_schedpol(lua_State *L, int idx)
{
	int pos = luaL_checkoption(L, idx, NULL, schedpol_ids);
	return schedpol_num[pos];
}

/* args: pid, policy, prio */
static int lua_sched_setscheduler(lua_State *L)
{
	int pid, policy;

	char errbuf[ERRBUF_LEN];
	struct sched_param schedp;

	memset(&schedp, 0, sizeof(schedp));

	pid = luaL_checknumber(L, 1);
	policy = check_schedpol(L, 2);
	
	schedp.sched_priority = (policy == SCHED_OTHER) ? 0 : luaL_checknumber(L, 3);

	DBG("pid=%d, policy=%s, prio=%d", pid, schedp.sched_policy, prio);

	
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
