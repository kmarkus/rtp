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
	/* printf("from C: spawned tid #%ld!\n", inf->thread); */
	/* startup */
	inf->L = lua_open();
	lua_gc(inf->L, LUA_GCSTOP, 0);
	luaL_openlibs(inf->L);
	lua_gc(inf->L, LUA_GCRESTART, 0);

	lua_pushlightuserdata(inf->L, (void*) &inf->thread);
	lua_setglobal(inf->L, "self");

	if(luaL_dostring(inf->L, inf->init_str) != 0)
		fprintf(stderr, "Failed to execute lua code string\n");

	lua_close(inf->L);
	pthread_exit(NULL);
}

static int lua_spawn(lua_State *L)
{
	int rc = 0;
	char errbuf[ERRBUF_LEN];

	if((info[cur].init_str = luaL_checkstring(L, 1)) == NULL) {
		luaL_error(L, "no lua code string passed");
		/* does not return */
	}

	rc = pthread_create(&info[cur].thread, NULL, startup, (void *) &info[cur]);

	if (rc) {
		strerror_r(errno, errbuf, ERRBUF_LEN);
		luaL_error(L, errbuf);
		/* does not return */
	} else {
		lua_pushlightuserdata(L, &info[cur].thread);
	}

	cur++;
	return 1;
}

static int lua_join(lua_State *L)
{
	pthread_t *tid;
	char errbuf[ERRBUF_LEN];

	if(!lua_islightuserdata(L, -1))
		luaL_error(L, "no thread id passed");

	tid = (pthread_t*) lua_touserdata(L, -1);
	lua_pop(L, 1);

	if(pthread_join(*tid, NULL) != 0) {
		strerror_r(errno, errbuf, ERRBUF_LEN);
		luaL_error(L, errbuf);
		/* does not return */
	}

	return 0;
}

static const struct luaL_Reg pthreads_ops [] = {
	{"spawn", lua_spawn},
	{"join", lua_join},
	{NULL, NULL}
};

int luaopen_pthreads(lua_State *L) {
	luaL_register(L, "pthreads", pthreads_ops);
	return 1;
}
