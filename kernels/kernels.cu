#include <cmath>
#include "kernels.h"
#include "../main.h"

#define BLOCK_SIZE 32

__global__ void sepia(const unsigned char* data, unsigned char* out, int width, int height)
{
    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;

    int rgb_offset = y * width + x;

    if (x > width && y > height && rgb_offset > (width * height)) {
        return;
    }

    int r = (data[rgb_offset * 3] * 0.393f) + (data[rgb_offset * 3 + 1] * 0.769) + (data[rgb_offset * 3 + 2] * 0.189f);
    int g = (data[rgb_offset * 3] * 0.349f) + (data[rgb_offset * 3 + 1] * 0.686) + (data[rgb_offset * 3 + 2] * 0.168f);
    int b = (data[rgb_offset * 3] * 0.272f) + (data[rgb_offset * 3 + 1] * 0.534) + (data[rgb_offset * 3 + 2] * 0.131f);

    out[rgb_offset   *   3] = r > 255 ? 255 : r;
    out[rgb_offset * 3 + 1] = g > 255 ? 255 : g;
    out[rgb_offset * 3 + 2] = b > 255 ? 255 : b;
}

__global__ void negative(unsigned char* data, unsigned char* out, int width, int height)
{
    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;

    int rgb_offset = y * width + x;

    if (x > width && y > height && rgb_offset > (width * height)) {
        return;
    }

    out[rgb_offset   *   3] = 255 - data[rgb_offset   *   3];
    out[rgb_offset * 3 + 1] = 255 - data[rgb_offset * 3 + 1];
    out[rgb_offset * 3 + 2] = 255 - data[rgb_offset * 3 + 2];
}

__global__ void grayscale(unsigned char* data, unsigned char* out, int width, int height)
{
    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;

    int rgb_offset = y * width + x;

    if (x > width && y > height && rgb_offset > (width * height)) {
        return;
    }

    int gray = (data[rgb_offset * 3] * 0.2126f) + (data[rgb_offset * 3 + 1] * 0.7152f) + (data[rgb_offset * 3 + 2] * 0.0722f);
    out[rgb_offset   *   3] = gray;
    out[rgb_offset * 3 + 1] = gray;
    out[rgb_offset * 3 + 2] = gray;
}

__global__ void nashville(unsigned char* data, unsigned char* out, int width, int height)
{
    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;

    int rgb_offset = y * width + x;

    if (x > width && y > height && rgb_offset > (width * height)) {
        return;
    }

    // Funciona como o efeito Levels (em um Photoshop/GIMP)
    // Limita o valor do output das cores
    out[rgb_offset   *   3] = data[rgb_offset   *   3] < 19  ? 19  : data[rgb_offset   *   3];
    out[rgb_offset * 3 + 1] = data[rgb_offset * 3 + 1] < 39  ? 39  : data[rgb_offset * 3 + 1];
    out[rgb_offset * 3 + 2] = data[rgb_offset * 3 + 2] < 137 ? 137 : data[rgb_offset * 3 + 2];
}

__device__ inline unsigned char get_intensity(const unsigned char *image, int row, int col,
                                             int channel, int height, int width, int cpp)
{
    if (col < 0 || col >= width)
        return 0;
    if (row < 0 || row >= height)
        return 0;
    
    /* Retorna o valor do pixel */
    return image[(row * width + col) * cpp + channel];
}

__global__ void sharpen(const unsigned char *data, unsigned char *out, const int width, const int height, const int channels)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height)
    {
        for (int c = 0; c < channels; c++)
        {
            /*              x   y   z
             * Filtro = a | 0  -1   0 |
             *          b |-1   5  -1 |
             *          c | 0  -1   0 |
		     *
             * Fonte: https://setosa.io/ev/image-kernels/
             */

            unsigned char ay = get_intensity(data, y - 1, x, c, height, width, channels);
            unsigned char bx = get_intensity(data, y, x - 1, c, height, width, channels);
            unsigned char by = get_intensity(data, y, x, c, height, width, channels);
            unsigned char bz = get_intensity(data, y, x + 1, c, height, width, channels);
            unsigned char cy = get_intensity(data, y + 1, x, c, height, width, channels);

            short res = (5 * by - ay - bx - bz - cy);
            res = min(res, 255);
            res = max(res, 0);
            out[(y * width + x) * channels + c] = (unsigned char) res;
        }
    }
}

void run_kernels(const unsigned char* input_image, unsigned char* output_image, unsigned width, unsigned height)
{
	/* Cria as variáveis, para serem usadas na placa de video */
    unsigned char* dev_input;
    unsigned char* dev_output;

	/* Aloca as variáveis criadas anteriormente na GPU */
    cudaMalloc( (void**) &dev_input, width*height*3*sizeof(unsigned char));
    cudaMalloc( (void**) &dev_output, width*height*3*sizeof(unsigned char));

	/* Copia os dados da imagem original para a GPU */
    cudaMemcpy( dev_input, input_image, width*height*3*sizeof(unsigned char), cudaMemcpyHostToDevice );

	/* Calcula os blocos e as threads a serem usadas */
    const dim3 blockSize(BLOCK_SIZE, BLOCK_SIZE);
    const dim3 gridSize((width + blockSize.x - 1)/blockSize.x, (height + blockSize.y - 1)/blockSize.y);

	// Filtros:

    // // Grayscale
    grayscale<<<gridSize, blockSize>>>(dev_input, dev_output, width, height);
    cudaMemcpy(output_image, dev_output, width*height*3*sizeof(unsigned char), cudaMemcpyDeviceToHost);
    write_file("out/grayscale.png", output_image, width, height);

    // // Negative
    negative<<<gridSize, blockSize>>>(dev_input, dev_output, width, height);
    cudaMemcpy(output_image, dev_output, width*height*3*sizeof(unsigned char), cudaMemcpyDeviceToHost);
    write_file("out/negative.png", output_image, width, height);

    // // Sepia
    sepia<<<gridSize, blockSize>>>(dev_input, dev_output, width, height);
    cudaMemcpy(output_image, dev_output, width*height*3*sizeof(unsigned char), cudaMemcpyDeviceToHost);
    write_file("out/sepia.png", output_image, width, height);

    // // Nashville
    nashville<<<gridSize, blockSize>>>(dev_input, dev_output, width, height);
    cudaMemcpy(output_image, dev_output, width*height*3*sizeof(unsigned char), cudaMemcpyDeviceToHost);
    write_file("out/nashville.png", output_image, width, height);

    // Sharpen
    sharpen<<<gridSize, blockSize>>>(dev_input, dev_output, width, height, 3);
    cudaMemcpy(output_image, dev_output, width*height*3*sizeof(unsigned char), cudaMemcpyDeviceToHost);
    write_file("out/sharpen.png", output_image, width, height);

    cudaFree(dev_input);
    cudaFree(dev_output);
}

