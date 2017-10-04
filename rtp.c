/*
 * (C) 2010,2011 Markus Klotzbuecher, markus.klotzbuecher@mech.kuleuven.be,
 * Department of Mechanical Engineering, Katholieke Universiteit
 * Leuven, Belgium.
 *
 * You may redistribute this software and/or modify it under either
 * the terms of the GNU Lesser General Public License version 2.1
 * (LGPLv2.1 <http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>)
 * or (at your discretion) of the Modified BSD License: Redistribution
 * and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *    1. Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *    2. Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *    3. The name of the author may not be used to endorse or promote
 *       products derived from this software without specific prior
 *       written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <time.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>		/* mlockall etc. */
#include <sched.h>		/* sched_setscheduler, sched_getscheduler */
#include <pthread.h>

#ifdef __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int luaopen_rtp(lua_State *L);

#ifdef __cplusplus
}
#endif

#undef DEBUG

#ifdef DEBUG
# define DBG(fmt, args...) printf("%s: " fmt "\n", __FUNCTION__, ##args)
#else
# define DBG(fmt, args...) do { } while(0);
#endif


/*
 * clock functions
 */

static const int clock_nums[] =
	{CLOCK_REALTIME, CLOCK_MONOTONIC,
	 CLOCK_PROCESS_CPUTIME_ID, CLOCK_THREAD_CPUTIME_ID};

static const char *const clock_ids[] =
	{"CLOCK_REALTIME", "CLOCK_MONOTONIC",
	 "CLOCK_PROCESS_CPUTIME_ID", "CLOCK_THREAD_CPUTIME_ID", NULL};

static clockid_t check_clockid(lua_State *L, int idx)
{
	int pos = luaL_checkoption(L, idx, NULL, clock_ids);
	return clock_nums[pos];
}

static int pushtimespec(lua_State *L, struct timespec *ts)
{
	lua_pushnumber(L, ts->tv_sec);
	lua_pushnumber(L, ts->tv_nsec);
	return 2;
}

/* arg: <clock id>:
 *
 * REALTIME, MONOTONIC, PROCESS_CPUTIME_ID, THREAD_CPUTIME_ID
 */
static int rtp_clock_getres(lua_State *L)
{
	clockid_t clockid;
	struct timespec res;

	clockid = check_clockid(L, 1);
	clock_getres(clockid, &res);
	return pushtimespec(L, &res);
}

/* arg: <clock id>:
 *
 * REALTIME, MONOTONIC, PROCESS_CPUTIME_ID, THREAD_CPUTIME_ID
 */

static int rtp_clock_gettime(lua_State *L)
{
	clockid_t clockid;
	struct timespec res;

	clockid = check_clockid(L, 1);
	clock_gettime(clockid, &res);
	return pushtimespec(L, &res);
}

/* tbd: clock_settime */
/* args: clock_id, flags (rel|abs), sec, nsec */
static int rtp_clock_nanosleep(lua_State *L)
{
	clockid_t clockid;
	const char *flag;
	int flag_id, ret;
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

	DBG("clockid=%d, flagid=%d, sec=%lu, nsec=%lu", clockid, flag_id, req.tv_sec, req.tv_nsec);

	ret = clock_nanosleep(clockid, flag_id, &req, NULL);

	if(ret)
		luaL_error(L, "clock_nanosleep failed: %s", strerror(ret));
	else
		lua_pushboolean(L, 1);

	return 1;
}

static const struct luaL_Reg rtp_clock [] = {
	{"gettime", rtp_clock_gettime},
	{"getres", rtp_clock_getres},
	{"nanosleep", rtp_clock_nanosleep},
	{NULL, NULL}
};


/*
 * pthread
 */

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
static int rtp_pthread_setschedparam(lua_State *L)
{
	int policy;
	pthread_t tid;
	struct sched_param param;

	memset(&param, 0, sizeof(struct sched_param));

	tid = luaL_checknumber(L, 1);
	tid = (tid != 0) ? tid : pthread_self();
	policy = check_schedpol(L, 2);

	param.sched_priority = (policy == SCHED_OTHER) ? 0 : luaL_checknumber(L, 3);

	DBG("pid=%lu, policy=%s, prio=%d", tid, schedpol_ids[policy], param.sched_priority);

	if(pthread_setschedparam(tid, policy, &param))
		luaL_error(L, "pthread_setschedparam failed: %s", strerror(errno));

	lua_pushboolean(L, 1);
	return 1;
}

static const struct luaL_Reg rtp_pthread [] = {
	{"setschedparam", rtp_pthread_setschedparam},
	{NULL, NULL}
};

/*
 * misc toplevel
 */

/* mlockall
 *
 * args: flag MCL_CURRENT | MCL_FUTURE
 */
static int rtp_mlockall(lua_State *L)
{
	const char *str_flag;
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

	if(ret < 0)
		luaL_error(L, "mlockall (%s) failed: %s", str_flag, strerror(errno));

	lua_pushboolean(L, 1);
	return 1;
}

static int rtp_munlockall(lua_State *L)
{
	int ret;

	DBG("");
	ret = munlockall();

	if(ret < 0)
		luaL_error(L, "munlockall failed: %s", strerror(ret));

	lua_pushboolean(L, 1);
	return 1;
}

static int rtp_sysinfo(lua_State *L)
{
#ifdef __XENO__
	lua_pushstring(L, "xenomai");
#else
	lua_pushstring(L, "gnulinux");
#endif
	return 1;
}

static const struct luaL_Reg rtp [] = {
	{"mlockall", rtp_mlockall},
	{"munlockall", rtp_munlockall},
	{"sysinfo", rtp_sysinfo},
	{NULL, NULL}
};

int luaopen_rtp(lua_State *L) {

#if LUA_VERSION_NUM >= 502
	luaL_newlib(L, rtp);

	lua_pushstring(L, "clock");
	luaL_newlib(L, rtp_clock);
	lua_settable(L, -3);

	lua_pushstring(L, "pthread");
	luaL_newlib(L, rtp_pthread);
	lua_settable(L, -3);

#else
	luaL_register(L, "rtp.clock", rtp_clock);
	luaL_register(L, "rtp.pthread", rtp_pthread);
	luaL_register(L, "rtp", rtp);
#endif
	return 1;
}
