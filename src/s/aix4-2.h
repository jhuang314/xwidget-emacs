/* AIX 4.2 is missing alloca.  */

#include "aix4-1.h"

#ifndef __GNUC__
#undef HAVE_ALLOCA
#endif
