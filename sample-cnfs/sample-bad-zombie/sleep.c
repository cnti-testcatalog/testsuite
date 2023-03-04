#include <stdio.h>
#include <unistd.h>

int main()
{
    int seconds = 5;

    printf("Sleeping for %d seconds...\n", seconds);
    sleep(seconds);
    printf("Done sleeping!\n");

    return 0;
}
