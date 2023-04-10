#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

int main()
{
    pid_t pid = fork();  // create a child process

    if (pid == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (pid == 0) {  // child process
        execl("/sleep", "sleep", NULL);  // run sleep command for 10 seconds
        perror("exec");
        exit(EXIT_FAILURE);
    }

    // parent process
    printf("Sleeping...\n");

    return 0;
}
