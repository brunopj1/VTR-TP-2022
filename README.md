
# VTR-TP-2022

Este repositório contem o trabalho prático da unidade curricular de Visualização em Tempo Real.
O projeto consiste na implementação de uma aplicação gráfica onde seja feita a geração de terreno infinito.
Para a implementação deste projeto foi utilizada o motor gráfico **Nau3D**, desenvolvido pela Universidade do Minho, facilitando assim a criação de projetos em **OpenGL** e **GLSL**.

Este trabalho foi classificado com 20 valores.

# Funcionalidades implementadas
- Geração de terreno infinito (que acompanha o movimento da camara).
- Utilização de múltiplas camadas de ruído na geração do terreno.
- Atualizações discretas da posição dos chunks de forma a reduzir a *flickering*.
- Tesselação dinâmica baseada na distância à câmara e no tamanho dos triângulos.
- View Frustum Culling utilizado em cada chunk do terreno.
- Utilização de *Physically Based Rendering* para o desenho do terreno.
- Utilização de múltiplos materiais consoante a altura do terreno.
- 2 versões distintas, uma com um algoritmo de remoção de *tiling* nas texturas, e outra com *Triplanar Mapping*.
