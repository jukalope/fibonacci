Fibonacci Webserver and Standalone Utility

Research
========
Wrote fib_classic() from scratch, supporting memoization for better efficiency.

Leveraged fib_closed() from:
    https://fabiandablander.com/r/Fibonacci.html

Leveraged FIFO netcat server logic from:
    https://dev.to/leandronsp/building-a-web-server-in-bash-part-ii-parsing-http-14kg

bash was very quick to prototype and prove memoization, but has its limitations. If time permitted, I would have re-written using python.

How to Run Webserver
====================
NOTE: MacOS + Linux. Not supported for Windows without installing MSYS, bc, nc, ...
Start the webserver.sh script in a terminal session, on an OS that has bash installed
  ./webserver.sh

How to Test Webserver
=====================
To acquire the 24th fibonacci number, for example:
  Visit http://127.0.0.1:3000/get?n=24
    OR
  curl http://127.0.0.1:3000/get?n=24

How to Run Stand-alone Fibonacci Utility
========================================
Run with no arguments to see full usage:
  ./fib.sh

Configuration and Dependencies
==============================
bash >= 4.2.X  to support shopt lastpipe, so that memoization works, but functionality works either way.
bc   >= 6.5.0  to properly scale fib_closed expression logic.
port 3000      If port conflicts on target system, just change its value in ws.cfg, then restart webserver.sh

Process
=======
I went through methods BAD, GOOD, BETTER, BEST, comparing time results for efficiency.

BAD
 - any recursive solution; their complexity, risk, and inefficiency are not worth any coding elegance.

GOOD
 - fib_closed()
 - close-form expression, pure mathematic approach with matrix-based formula, and no memory caching.
 - Not going to re-invent the wheel; I leveraged the formula from here and ported to bash: 
       https://fabiandablander.com/r/Fibonacci.html
 - CON: Does NOT work past the 78th fib number.

BETTER
 - fib_classic()
 - classic approach, storing the sequence known so-far in an array, and only re-calculating if not already known.
 - when running 1000 times with random requested indices, this method is 72X faster than the GOOD method.
 - Limit: on 64-bit OSs, the maximum integer value is (263 - 1), 9,223,372,036,854,775,807

                                         93rd fibonacci number  12,200,159,415,121,876,738 (not supported)
                                         92nd fibonacci number   7,540,113,804,746,346,429
                                         91st fibonacci number   4,660,046,610,375,530,309
BEST
 - If we know the range of desired indices (for ex., if we know we'll never be asked for n above 100), just
   pre-calculate them all and store.
 - Just pre-run fib_classic once with the max index. All values will be at the ready for subsequent calls.
 - Leverage Python - has better/faster number handling beyond 64-bit limitation.

API Improvement
===============
Consider an endpoint option to support a list of fibonacci indices in the request, to reduce chattiness. 
The bulk of the request time will be in the request/response traffic, NOT in the actually calculation.

Operational Considerations
==========================
For production-level operation consider all the following:

Containerization
 - Dockefile with ubuntu, and include layers to install monitoring agents (see section below), copy fibonacci 
   repo files, and launch, exposing port.

CI/CD with Github Actions:
 - Create a .github/workflows/pull-pipe.yml to run:
     lint, regression test, build docker image, upload to container registry (ECR)
 - Create a .github/workflows/push-pipe.yml to run:
     git tag, deploy to target host(s) and start.

Any monitoring/logging strategies you might apply:
 - Logs:    include a logging service to feed Datadog. Then, if scaling out, all logging will be centralized.
 - Metrics: include a metrics service to gather cpu, memory, network usage, and feed Datadog.
 - Alerts:  create monitors to alert usage above capacity thresholds. Send to PagerDuty (expensive), or OpsGenie.
 - Alerts:  create monitors for synthetic tests as well. Send alerts to PagerDuty (expensive), or OpsGenie.

How you would scale the service to handle a high number of requests:
 - Consider running multiple instances of the service, fed through a load balancer, spread across 2 availability zones for redundancy.
 - For VERY large demand, consider using Kubernetes (EKS in AWS) to host multiple pods on multiple nodes, with CAS (cluster autoscaling) and HPA (horizontal pod autoscaling) to keep costs down but flexible enough to meet demand. To further reduce cost, consider using a mix of on-demand instances plus SPOT instances (about 66% cheaper).

