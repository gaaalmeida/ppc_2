all: main.o lodepng.o kernels.o
	nvcc main.o lodepng.o kernels.o -o main -O3

kernels.o:
	nvcc -c kernels/kernels.cu -O3

main.o:
	g++ -c main.cpp -Wall -Wextra --std=c++11 -O3

lodepng.o:
	g++ -c libs/lodepng/lodepng.cpp -Wall -Wextra -pedantic -ansi -O3

clean:
	rm -rf *.o main
