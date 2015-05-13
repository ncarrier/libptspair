/**
 * @file ptspair.h
 * @brief creates a pair of connected pts.
 *
 * Structures must be considered as opaque and must be manipulated through API
 * functions only.<br />
 *
 * Negative values from functions returning an int indicate an error and are the
 * opposite of an errno value. Functions returning a pointer indicate an error
 * by returning NULL an setting errno.
 *
 * @date 5 mai 2015
 * @author carrier.nicolas0@gmail.com
 */
#ifndef PTSPAIR_H_
#define PTSPAIR_H_
#include <limits.h>
#include <stdbool.h>

#ifndef PTSPAIR_BUFFER_SIZE
#define PTSPAIR_BUFFER_SIZE 0x200
#endif /* PTSPAIR_BUFFER_SIZE */

#ifndef PTSPAIR_PATH_MAX
#define PTSPAIR_PATH_MAX 0x1000
#endif /* PTSPAIR_PATH_MAX */

enum pts_index {
	PTSPAIR_FOO,
	PTSPAIR_BAR,

	PTSPAIR_NB,
};

/* circular buffer */
struct buffer {
	char buf[PTSPAIR_BUFFER_SIZE];
	int start;
	int end;
	/* used to distinguish full / empty when start == end */
	bool full;
};

struct pts {
	char slave_path[PTSPAIR_PATH_MAX];
	/*
	 * stores the data read from the other pts, ready to be written to this
	 * pts
	 */
	struct buffer buf;
	int master;
	/*
	 * if one of the pts is closed, it's master fd will keep triggering
	 * EPOLLHUP events, having a fd opened WRONLY on the slave's end
	 * prevent this
	 */
	int writer;
};

struct ptspair {
	struct pts pts[PTSPAIR_NB];
	int epollfd;
};

__attribute__((visibility("default")))
int ptspair_init(struct ptspair *ptspair);
__attribute__((visibility("default")))
const char *ptspair_get_path(const struct ptspair *ptspair,
		enum pts_index pts_index);
__attribute__((visibility("default")))
/* returns the writer fd on the given pts, must NOT be closed */
int ptspair_get_writer_fd(const struct ptspair *ptspair,
		enum pts_index pts_index);
__attribute__((visibility("default")))
int ptspair_get_fd(const struct ptspair *ptspair);
__attribute__((visibility("default")))
int ptspair_process_events(struct ptspair *ptspair);
__attribute__((visibility("default")))
void ptspair_clean(struct ptspair *ptspair);

#endif /* PTSPAIR_H_ */
