/**
 * @file ptspair.c
 * @brief 
 *
 * @date 5 mai 2015
 * @author carrier.nicolas0@gmail.com
 */
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif /* _GNU_SOURCE */
#include <sys/epoll.h>

#include <fcntl.h>
#include <unistd.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include <errno.h>

#include "../include/ptspair.h"

static void clean_pts(struct pts *pts)
{
	if (pts == NULL)
		return;

	close(pts->master);
	memset(pts, 0, sizeof(*pts));
}

static int init_pts(struct pts *pts)
{
	int ret;

	memset(pts, 0, sizeof(*pts));
	pts->master = posix_openpt(O_RDWR | O_NOCTTY);
	if (pts->master < 0) {
		ret = -errno;
		goto err;
	}
	ret = grantpt(pts->master);
	if (ret < 0) {
		ret = -errno;
		goto err;
	}
	ret = unlockpt(pts->master);
	if (ret < 0) {
		ret = -errno;
		goto err;
	}
	ret = ptsname_r(pts->master, pts->slave_path, PATH_MAX);
	/* TODO how to check for truncature ? */
	if (ret < 0) {
		ret = -errno;
		goto err;
	}

	return 0;
err:
	clean_pts(pts);

	return ret;
}

int init_pts_pair(struct pts_pair *pts_pair)
{
	int ret;

	if (pts_pair == NULL)
		return -EINVAL;

	pts_pair->epollfd = epoll_create1(EPOLL_CLOEXEC);
	if (pts_pair->epollfd == -1)
		return -errno;

	ret = init_pts(pts_pair->pts);
	if (ret < 0)
		goto err;
	ret = init_pts(pts_pair->pts + 1);
	if (ret < 0)
		goto err;

	return 0;
err:
	clean_pts_pair(pts_pair);

	return ret;
}

void clean_pts_pair(struct pts_pair *pts_pair)
{
	if (pts_pair == NULL)
		return;

	close(pts_pair->epollfd);
	clean_pts(pts_pair->pts + 1);
	clean_pts(pts_pair->pts);
	memset(pts_pair, 0, sizeof(*pts_pair));
}
