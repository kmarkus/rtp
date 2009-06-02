#include <unistd.h>
#include <pthread.h>
#include <errno.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int luaopen_pthreads(lua_State *L);

#define MALLOC malloc
#define ERRBUF_LEN	30

struct pthreads_info {
	pthread_t thread;
	lua_State *L;
	const char *init_str;
};


int cur = 0;
struct pthreads_info info[100000];

static void* startup(void *data)
{
	struct pthreads_info *inf = (struct pthreads_info*) data;
	printf("from C: spawned tid #%ld!\n", inf->thread);

	/* startup */
	inf->L = lua_open();
	lua_gc(inf->L, LUA_GCSTOP, 0);
	luaL_openlibs(inf->L);
	lua_gc(inf->L, LUA_GCSTOP, 0);

	lua_pushinteger(inf->L, (unsigned int) inf->thread);
	lua_setglobal(inf->L, "self");

	if(luaL_dostring(inf->L, inf->init_str) != 0)
		goto out;
 out:
	lua_close(inf->L);
	pthread_exit(NULL);
}

static int lua_spawn(lua_State *L)
{
	int rc = 0;
	char errbuf[ERRBUF_LEN];

	if((info[cur].init_str = luaL_checkstring(L, 1)) == NULL) {
		luaL_error(L, "no lua code string passed");
		goto fail;
	}

	rc = pthread_create(&info[cur].thread, NULL, startup, (void *) &info[cur]);

	if (rc) {
		strerror_r(errno, errbuf, ERRBUF_LEN);
		luaL_error(L, errbuf);
	} else {
		lua_pushinteger(L, (unsigned int) info[cur].thread);
	}

	cur++;

	return 1;
 fail:
	return 1;
}

static int lua_wait(lua_State *L)
{
	return sleep(10);
}

static const struct luaL_Reg pthreads_ops [] = {
	{"spawn", lua_spawn},
	{"wait", lua_wait},
	{NULL, NULL}
};

int luaopen_pthreads(lua_State *L) {
	luaL_register(L, "pthreads", pthreads_ops);
	return 1;
}
