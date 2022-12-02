#include <iostream>
#include <vector>
#include <string>
#include "libs/lodepng/lodepng.h"
#include "kernels/kernels.h"
#include "main.h"

void write_file(const std::string path, unsigned char* data, int width, int height)
{
    unsigned error = lodepng::encode(path, data, width, height, LCT_RGB);

    if (error) {
        std::cout << "ENCODE ERROR: " << error << ": "<< lodepng_error_text(error) << std::endl;
        exit(EXIT_FAILURE);
    }
}

int main() {
	// Caminho para a imagem em PNG
    // Foi testado com duas imagens:
    // 
    // cat.png -> 240x240px
    // | Fonte: https://www.nawpic.com/funny-cat-4/
    // 
    // landscape.png -> 5472x3648px
    // | Fonte: https://www.pexels.com/photo/brown-mountains-2559941/
    // | Roberto Nickson
    static const std::string default_image = "images/landscape.png";

    std::vector<unsigned char> readed;
    unsigned width;
    unsigned height;

    // Carrega a imagem
    unsigned error = lodepng::decode(readed, width, height, default_image, LCT_RGB);
    if (error) {
        std::cout << "DECODE ERROR: " << error << ": "<< lodepng_error_text(error) << std::endl;
        exit(EXIT_FAILURE);
    }
    
    // Prepara os dados
    unsigned char* input_image = &readed[0];
    unsigned char* output_image = (unsigned char*)malloc(sizeof(unsigned char) * readed.size() * 3);

    // Aplica os 5 filtros e salva cada um na pasta out/
    run_kernels(input_image, output_image, width, height); 

    return 0;
}