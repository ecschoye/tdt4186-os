#include "kernel/types.h"
#include "user/user.h"

struct process_info {
	int pid;
	int status;
	char name[16];
};

int main(int argc, char *argv[])
{
    getprocessinfo();
    return 0;
}
