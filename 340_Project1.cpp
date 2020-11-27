#include <sys/types.h>
#include <stdio.h>
#include <unistd.h>
#include<sys/wait.h>
#include<fcntl.h>
#define SIZ 128

int func_cpfile(int argc, const char *argv[]){
	
         
	 int f1, f2;
	
	 // Do we have right number of arguments?
	
	 if (argc != 4){
	 printf("Wrong number of command line arguments\n");
	 
	 return 1;}
	 // Can we access thge source file?
	 if ((f1 = open(argv[1], O_RDONLY, 0)) == -1){
	 printf("Can't open %s \n", argv[1]);
	 return 2;}
	 // Can we create the target file?
	 if ((f2 = creat(argv[3], 0644)) == -1){
	 printf("Can't create %s \n", argv[3]);
	 return 3;}
	 // Copy source file contents to target file. 
	 char buf[SIZ];
	 int n;
	 while ((n = read( f1, buf, SIZ)) > 0)
	 if (write(f2, buf, n) != n){
	 printf("Can't write file" );
	 close(f1);close(f2);
	 return 4;
	 }
	 close(f1);
	
	 close(f2);
	 printf("Success!" );return 0;
	


}
//----------------MAIN METHOD----------------//
//
//has parameters:
//
//argc: number of arguments in command line (Integer).
//
//argv: each index contains an argument, in this case 
//      the names of files (Constant Character Array).

int main(int argc, const char *argv[]){

    //pid_t: Process Identification, represents process IDs
    pid_t pid;
    
    //Function call for func_cpfile()
    func_cpfile(argc, argv);
    
    pid = fork();

    //if fork fails, print error
    if(pid < 0){
        fprintf(stderr, "Fork Failed");
        return 1;
    }
    //if fork successful, create new process image, execute cpfile.exe using arguments 1 and 2.
    else if(pid == 0){
        execlp("./cpfile.exe", "cpfile.exe", argv[1], argv[2], NULL);
    }
    //if pid > 0
    else{
        wait(NULL);
        printf("Child Complete");
    }
    return 0;
}
