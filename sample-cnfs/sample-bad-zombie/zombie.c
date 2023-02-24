#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <errno.h>
 
int main ()
{
  pid_t child_pid;
  int child_status;
 
  child_pid = fork ();
  if (child_pid > 0) {
    // parent process will sleep for 30 seconds and exit, without a call to wait()
    fprintf(stderr,"parent process - %d\n", getpid());    
    sleep(10000); 
    exit(0);
  }
  else if (child_pid == 0) {
    // child process will exit immediately
    fprintf(stderr,"child process - %d\n", getpid());
    exit(0);    
  }
  else if (child_pid == -1) {
    // fork() error
    perror("fork() call failed");    
    exit (-1);
  }
  else {
    // this should not happen
    fprintf(stderr, "unknown return value of %d from fork() call", child_pid);
    exit (-2);
  }
  return 0;
}
