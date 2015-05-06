/**
 * @file ptspair.h
 * @brief 
 *
 * @date 5 mai 2015
 * @author carrier.nicolas0@gmail.com
 */
#ifndef PTSPAIR_H_
#define PTSPAIR_H_
#include <limits.h>
#include <stdbool.h>

#define PTSPAIR_BUFFER_SIZE 0x200

enum pts_index {
	PTSPAIR_FOO,
	PTSPAIR_BAR,
};

/* circular buffer */
struct buffer {
	char buf[PTSPAIR_BUFFER_SIZE];
	int start;
	int end;
	bool full;
};

struct pts {
	char slave_path[PATH_MAX];
	/*
	 * stores the data read from the other pts, ready to be written to the
	 * other
	 */
	struct buffer buf;
	int master;
};

struct ptspair {
	struct pts pts[2];
	int epollfd;
};

int ptspair_init(struct ptspair *ptspair);
const char *ptspair_get_path(struct ptspair *ptspair, enum pts_index pts_index);
int ptspair_get_fd(struct ptspair *ptspair);
int ptspair_process_events(struct ptspair *ptspair);
void ptspair_clean(struct ptspair *ptspair);

#endif /* PTSPAIR_H_ */
