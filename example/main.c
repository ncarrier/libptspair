/**
 * @file main.c
 * @brief 
 *
 * @date 4 mai 2015
 * @author carrier.nicolas0@gmail.com
 */
#include <error.h>

#include <stdlib.h>

#include <ptspair.h>

int main(void)
{
	int ret;
	struct pts_pair pair;

	ret = init_pts_pair(&pair);
	if (ret < 0)
		error(EXIT_FAILURE, -ret, "init_pts_pair");

	clean_pts_pair(&pair);

	return EXIT_SUCCESS;
}



