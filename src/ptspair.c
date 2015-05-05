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

	if (pts->master != 0)
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

int ptspair_init(struct ptspair *ptspair)
{
	int ret;

	if (ptspair == NULL)
		return -EINVAL;

	ptspair->epollfd = epoll_create1(EPOLL_CLOEXEC);
	if (ptspair->epollfd == -1)
		return -errno;

	ret = init_pts(ptspair->pts);
	if (ret < 0)
		goto err;
	ret = init_pts(ptspair->pts + 1);
	if (ret < 0)
		goto err;

	return 0;
err:
	ptspair_clean(ptspair);

	return ret;
}

int ptspair_get_fd(struct ptspair *ptspair)
{
	if (ptspair == NULL)
		return -EINVAL;

	return ptspair->epollfd;
}

void ptspair_clean(struct ptspair *ptspair)
{
	if (ptspair == NULL)
		return;

	if (ptspair->epollfd != 0)
		close(ptspair->epollfd);
	clean_pts(ptspair->pts + 1);
	clean_pts(ptspair->pts);
	memset(ptspair, 0, sizeof(*ptspair));
}
