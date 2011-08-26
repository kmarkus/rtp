#!/bin/sh

#
# usage: gc-test.lua <num_runs> <garbage_tabsize> <garbage_tabnum> <data_tabsize> <data_tabnum> <sleep_ns> <type> <quiet>
#

CMD="lua gc-test.lua"
NUM_RUNS=100000

SLEEP_NS=0
TYPE="collect"
QUIET="true"

# test effect of gc duration with different amounts of garbage for
# small tabsize

##			gts	gtn	dts	dtn	sleep	type	quiet
${CMD}	$NUM_RUNS	1	10	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	10	10	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	20	10	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	50	10	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	100	10	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	200	10	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	500	10	0	0	0	$TYPE	$QUIET
#${CMD}	$NUM_RUNS	1000	10	0	0	0	$TYPE	$QUIET

# test effect of gc duration with different amounts of garbage for
# different values of the spectrum gts * gtn = 1000
${CMD}	$NUM_RUNS	1	1000	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	2	500	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	10	100	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	20	50	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	32	32	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	50	20	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	100	10	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	5000	2	0	0	0	$TYPE	$QUIET
${CMD}	$NUM_RUNS	1000	1	0	0	0	$TYPE	$QUIET

# it would be nice to be able to run the test with params:
#	<tabsize*tabnum> <num_samples>

# test effect of different amounts of regular data
