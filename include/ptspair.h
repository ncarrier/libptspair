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

#define BUFFER_SIZE 0x200

struct buffer {
	char buf[BUFFER_SIZE];
	int start;
	int end;
	bool full;
};

struct pts {
	char slave_path[PATH_MAX];
	struct buffer buf;
	int master;
};

struct pts_pair {
	struct pts pts[2];
	int epollfd;
};

int init_pts_pair(struct pts_pair *pts_pair);
void clean_pts_pair(struct pts_pair *pts_pair);

#endif /* PTSPAIR_H_ */
