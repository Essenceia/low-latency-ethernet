ifndef debug
#debug :=
endif

FLAGS = -Wall -Wextra -Wconversion -Wshadow -Wundef -fno-common  -Wno-unused-parameter -Wno-type-limits
CC = cc $(if $(debug),-DDEBUG -g)
LD = cc

64b66b : main.o
	$(LD) -o 64b66b -g main.o

main.o : main.c
	$(CC) -c main.c $(FLAGS)

clean :
	rm -f 64b66b *.o
