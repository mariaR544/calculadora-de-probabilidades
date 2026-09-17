# Calculadora de Probabilidades y Líneas de Espera

Aplicación diseñada para el cálculo, análisis e interpretación de modelos probabilísticos y de teoría de colas (líneas de espera), orientada a facilitar el aprendizaje y la aplicación práctica de estos modelos mediante resultados numéricos, desgloses teóricos, interpretaciones y visualizaciones gráficas.

La aplicación está pensada como una herramienta **escalable**, organizada en módulos independientes accesibles desde una barra lateral desplegable, lo que permite incorporar nuevos modelos o funcionalidades a futuro sin afectar la estructura general.

##  Descripción general

La navegación principal se realiza mediante una **barra lateral desplegable**, dividida en los siguientes módulos:

1. Probabilidades (Poisson y Exponencial)
2. Líneas de espera (un servidor)
3. Multiservidor
4. Simulación de Monte Carlo

Cada módulo comparte, en la medida en que aplica, un conjunto de funciones comunes:

- **Desglose teórico y fórmulas**: se muestra la fórmula general utilizada y, debajo de ella, la misma fórmula con los valores ingresados por el usuario ya sustituidos.
- **Interpretación**: explicación en lenguaje simple del resultado final y del significado de cada estadístico o métrica obtenida.
- **Botón de fórmulas**: muestra las fórmulas teóricas/generales del modelo junto con una descripción del concepto y sus datos más relevantes.
- **Ventanas de procedimiento**: al seleccionar un resultado (estadístico o métrica), se despliega una ventana emergente con la fórmula asociada, la sustitución con los valores ingresados y el resultado obtenido.
- **Gráficas con leyenda**: visualización de los resultados mediante gráficas, con navegación entre ellas y leyenda de colores.
- **Impresión y exportación a PDF** del resultado completo.

##  Funcionalidades por módulo

### Módulo 1: Probabilidades

#### Distribución de Poisson
- Ingreso de parámetros según el tipo de probabilidad seleccionada.
- Cálculo y visualización del resultado.
- Desglose teórico y fórmulas (fórmula general + sustitución de valores).
- Interpretación del resultado y de los estadísticos.
- Botón de fórmulas con descripción del modelo.
- Estadísticos descriptivos con ventana de procedimiento individual (fórmula, sustitución y resultado) para cada uno.
- Gráficas: **probabilidad** y **acumulativa**, con leyenda.
- Impresión y exportación a PDF.

#### Distribución Exponencial
- Mismas funcionalidades que Poisson, con la diferencia de que las gráficas mostradas son de **densidad** y **acumulativa**.

### Módulo 2: Líneas de espera (un servidor)

#### Sin límite en cola
- Ingreso de los dos parámetros requeridos por el modelo.
- Métricas del sistema, cada una con su ventana de procedimiento.
- Desglose teórico y fórmulas, interpretación y botón de fórmulas.
- Gráficas de **distribución** y **acumulada**, con leyenda.
- Tabla de probabilidades.
- Impresión y exportación a PDF.

#### Con límite en cola
- Incluye todas las funciones del modelo sin límite en cola.
- Se agregan los **cálculos de capacidad finita**.
- Todos los resultados (incluyendo los de capacidad finita) cuentan con ventana de procedimiento.

### Módulo 3: Multiservidor

#### Sin límite en cola
- Ingreso de parámetros del modelo multicanal.
- Métricas del sistema multicanal y **estado de los servidores**, cada resultado con su ventana de procedimiento.
- Desglose teórico y fórmulas, interpretación y botón de fórmulas.
- Gráficas de **distribución** y **acumulada**, con leyenda.
- Tabla de probabilidades.
- Impresión y exportación a PDF.

#### Con límite en cola
- Mismas funcionalidades que el modelo multiservidor sin límite en cola, incluyendo métricas del sistema, estado de los servidores y sus respectivas ventanas de procedimiento.

### Módulo 4: Simulación de Monte Carlo
- Selección del tipo de distribución a simular:
  - **Poisson** (distribución discreta)
  - **Exponencial** (distribución continua)
- Generación de una base de datos de prueba para la simulación.
- Comparación de resultados **muestrales vs. teóricos**.
- Cálculo de la media muestral y la varianza muestral de las variables simuladas.
- Visualización de la base de datos generada, organizada según el número de observaciones y el número de variables definidas.
- Incluye las mismas funciones de los módulos anteriores (desglose teórico, interpretación, gráficas, impresión y exportación a PDF), **a excepción** del botón de fórmulas y las ventanas de procedimiento.

##  Tecnologías utilizadas

- **Flutter**
- **Dart**

##  Mi rol en el proyecto

Desarrollo completo de la aplicación: diseño de la interfaz, implementación de la lógica de cálculo para cada modelo probabilístico y de teoría de colas, generación de las ventanas de procedimiento y desgloses teóricos, construcción de las gráficas e interpretación de resultados, así como la funcionalidad de exportación a PDF e impresión.

##  Capturas de pantalla

<img width="591" height="1280" alt="photo_1_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/21bdf9ae-0187-4570-adc9-3b2c566a6439" />
<img width="591" height="1280" alt="photo_2_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/63652d3c-988f-4001-8d39-730b0feadd38" />
<img width="591" height="1280" alt="photo_3_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/32ea281c-b7b8-4241-80c3-3dde3c8dd9ce" />
<img width="591" height="1280" alt="photo_4_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/7f4a5262-195b-48af-9ae5-027902a0cdc9" />
<img width="591" height="1280" alt="photo_5_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/09951f52-d3d0-4ebb-bc37-4f6f6a50878c" />
<img width="591" height="1280" alt="photo_6_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/cd6734b5-77fc-441d-9995-5a839e1e48d5" />
<img width="591" height="1280" alt="photo_7_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/55bd4e6e-86a2-4928-be61-4dac0cfd4ea2" />
<img width="591" height="1280" alt="photo_8_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/353babbd-7f71-4cf1-9815-5b9fa8837b38" />
<img width="591" height="1280" alt="photo_9_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/8335c985-0a04-43ba-b396-01e67eb0f35b" />
<img width="591" height="1280" alt="photo_10_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/1da25cf2-58d7-4bcd-a699-df736cfc5274" />
<img width="591" height="1280" alt="photo_11_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/a3d66c8f-8a75-482a-9864-ae2cf8dea031" />
<img width="591" height="1280" alt="photo_12_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/8bd67684-49c0-4bb0-989f-0e2dfc0e67ed" />
<img width="591" height="1280" alt="photo_13_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/19385134-790c-49fc-a261-671a0fe91398" />
<img width="591" height="1280" alt="photo_14_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/38376e08-c25c-4cac-a907-9985073d3af4" />
<img width="591" height="1280" alt="photo_15_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/1e6bfd34-cd76-4ff0-930d-4c77b2b9d1b1" />
<img width="591" height="1280" alt="photo_16_2026-09-16_21-12-30" src="https://github.com/user-attachments/assets/22f452e7-dae2-4bd5-b7a2-cb01da1f71f6" />


##  Instalación y uso

```bash
# Clonar el repositorio
git clone https://github.com/mariaR544/calculadora-de-probabilidades.git

# Obtener dependencias de Flutter
flutter pub get

# Ejecutar la aplicación
flutter run
```

## Autoría

Proyecto desarrollado en su totalidad por **Maria Rojas**.

## Licencia

**Todos los derechos reservados © 2026 Maria Rojas.**

Este proyecto se comparte con fines de portafolio y demostración de habilidades técnicas. Queda prohibida su copia, modificación, distribución o uso comercial, total o parcial, sin autorización expresa y por escrito de la autora.

Ver el archivo [`LICENSE`](./LICENSE) para más detalles.
