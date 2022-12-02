# Processamento de imagens com CUDA
Trabalho para a disciplina de "Programação Paralela e Concorrente II".

Enunciado: Usar CUDA para aplicar 5 filtros em uma imagem.

Grupo:
- Brenno de Carvalho
- Carlos Gabriel
- Isaque Almeida
- Luis Fernando

## Libs
Foi usado a biblioteca LodePNG criada por Lode Vandevenne.
Acesse a página do criador em: [Github](https://github.com/lvandeve/lodepng), [LodePNG](https://lodev.org/lodepng/).

## Instruções
É necessário ter os seguintes aplicativos instalados:
- G++ (4.8+)
- CUDA (NVCC)

> A imagem a ser processada é definida no arquivo `main.cpp` na linha `28`.

Use `make clean` para limpar as imagens e os arquivos .o antes de rodar o programa, após limpar compile o programa com o comando `make`.
Rode o programa com o comando `./main`.

Comando completo:
> `make clean && make && ./main`

