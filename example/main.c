/**
 * @file main.c
 * @brief 
 *
 * @date 4 mai 2015
 * @author carrier.nicolas0@gmail.com
 */
#include <sys/epoll.h>

#include <unistd.h>
#include <signal.h>

#include <error.h>

#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include <ptspair.h>

static volatile bool loop = true;

static void sigint_handler(__attribute__((unused))int sig)
{
	loop = false;
	printf("Interrupted !\n");
}

int main(void)
{
	int ret;
	struct ptspair pair;
	struct epoll_event e;
	int efd;
	int fd;

	ret = ptspair_init(&pair);
	if (ret < 0)
		error(EXIT_FAILURE, -ret, "init_pts_pair");

	efd = epoll_create1(EPOLL_CLOEXEC);
	if (efd < 0)
		error(EXIT_FAILURE, errno, "epoll_create1");
	fd = ptspair_get_fd(&pair);
	memset(&e, 0, sizeof(e));
	e.events = EPOLLIN;
	ret = epoll_ctl(efd, EPOLL_CTL_ADD, fd, &e);
	if (ret < 0)
		error(EXIT_FAILURE, errno, "epoll_ctl");

	printf("foo pts: %s\n", ptspair_get_path(&pair, PTSPAIR_FOO));
	printf("bar pts: %s\n", ptspair_get_path(&pair, PTSPAIR_BAR));
	fflush(stdout);

	signal(SIGINT, sigint_handler);
	do {
		ret = epoll_wait(efd, &e, 1, -1);
		if (ret < 0 && errno != EINTR)
			error(EXIT_FAILURE, errno, "epoll_wait");
		if (ret == 1) {
			ret = ptspair_process_events(&pair);
			if (ret < 0 && ret != -EINTR)
				error(EXIT_FAILURE, -ret,
						"ptspair_process_events");
		}
	} while (loop);

	close(efd);
	ptspair_clean(&pair);

	return EXIT_SUCCESS;
}
