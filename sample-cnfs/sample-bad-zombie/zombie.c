#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <errno.h>
 


int main(int argc, char ** argv) {
  sleep(20);
   /* main process */
  pid_t pid = fork();
   /* second process */
  if (pid == 0) {
    sleep(10);
    pid = fork();
     /* third process */
    if (pid == 0) {
      sleep(10);
      printf("got pid %d about to exit\n", pid);
      exit(0);
    }
    sleep(3);
    printf("got pid %d about to exit\n", pid);
    exit(0);
  }
  printf("got pid %d and exited\n", pid);
  sleep(100);
}
