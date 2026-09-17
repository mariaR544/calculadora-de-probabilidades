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
Módulo 1: Probabilidades
<p align="center"> <img width="180" alt="photo_1" src="https://github.com/user-attachments/assets/21bdf9ae-0187-4570-adc9-3b2c566a6439" /> <img width="180" alt="photo_2" src="https://github.com/user-attachments/assets/63652d3c-988f-4001-8d39-730b0feadd38" /> <img width="180" alt="photo_3" src="https://github.com/user-attachments/assets/32ea281c-b7b8-4241-80c3-3dde3c8dd9ce" /> <img width="180" alt="photo_4" src="https://github.com/user-attachments/assets/7f4a5262-195b-48af-9ae5-027902a0cdc9" /> </p>

Módulo 2: Líneas de espera
<p align="center"> <img width="180" alt="photo_5" src="https://github.com/user-attachments/assets/09951f52-d3d0-4ebb-bc37-4f6f6a50878c" /> <img width="180" alt="photo_6" src="https://github.com/user-attachments/assets/cd6734b5-77fc-441d-9995-5a839e1e48d5" /> <img width="180" alt="photo_7" src="https://github.com/user-attachments/assets/55bd4e6e-86a2-4928-be61-4dac0cfd4ea2" /> <img width="180" alt="photo_8" src="https://github.com/user-attachments/assets/353babbd-7f71-4cf1-9815-5b9fa8837b38" /> </p>

Módulo 3: Multiservidor
<p align="center"> <img width="180" alt="photo_9" src="https://github.com/user-attachments/assets/8335c985-0a04-43ba-b396-01e67eb0f35b" /> <img width="180" alt="photo_10" src="https://github.com/user-attachments/assets/1da25cf2-58d7-4bcd-a699-df736cfc5274" /> <img width="180" alt="photo_11" src="https://github.com/user-attachments/assets/a3d66c8f-8a75-482a-9864-ae2cf8dea031" /> <img width="180" alt="photo_12" src="https://github.com/user-attachments/assets/8bd67684-49c0-4bb0-989f-0e2dfc0e67ed" /> </p>
Módulo 4: Simulación de Monte Carlo
<p align="center"> <img width="180" alt="photo_13" src="https://github.com/user-attachments/assets/19385134-790c-49fc-a261-671a0fe91398" /> <img width="180" alt="photo_14" src="https://github.com/user-attachments/assets/38376e08-c25c-4cac-a907-9985073d3af4" /> <img width="180" alt="photo_15" src="https://github.com/user-attachments/assets/1e6bfd34-cd76-4ff0-930d-4c77b2b9d1b1" /> <img width="180" alt="photo_16" src="https://github.com/user-attachments/assets/22f452e7-dae2-4bd5-b7a2-cb01da1f71f6" /> </p>
<p align="center">
  <img width="180" alt="photo_31" src="https://github.com/user-attachments/assets/a419458f-7fd9-46f8-9ace-1b19fb711a50" /> 
  <img width="180" alt="photo_30" src="https://github.com/user-attachments/assets/1703a437-386a-4345-8c9f-6f86fd945f6a" />
<img width="180" alt="photo_29" src="https://github.com/user-attachments/assets/1cd02028-8a29-472c-9899-96bc86c95ee5" />
<img width="180" alt="photo_28" src="https://github.com/user-attachments/assets/558ac4f8-3def-423b-a67e-8fbd99026fb0" />
<img width="180" alt="photo_27" src="https://github.com/user-attachments/assets/df969970-e668-4b27-b221-5090224e8d9a" />
<img width="180" alt="photo_37" src="https://github.com/user-attachments/assets/e962df5d-7338-4c1b-9587-cf2b26eee2c5" />
<img width="180" alt="photo_36" src="https://github.com/user-attachments/assets/c2df56b0-ce2b-4237-bbab-8de12b6d948d" />
<img width="180" alt="photo_35" src="https://github.com/user-attachments/assets/e8687b5a-e112-4181-b337-fb83064a7c3f" />
<img width="180" alt="photo_34" src="https://github.com/user-attachments/assets/35a73134-9e95-471c-b358-20154813748d" />
<img width="180" alt="photo_33" src="https://github.com/user-attachments/assets/fa531aa7-fa02-430d-95f7-4c20b789a2db" />
<img width="180" alt="photo_22" src="https://github.com/user-attachments/assets/81e1c310-fa20-471e-8cab-fa21da02da5d" />
<img width="180" alt="photo_21" src="https://github.com/user-attachments/assets/36690877-98bb-472c-8f4e-3f2e60fc2655" />
<img width="180" alt="photo_20" src="https://github.com/user-attachments/assets/5ededab9-9e93-4c53-a638-01908cba5ec2" />
<img width="180" alt="photo_19" src="https://github.com/user-attachments/assets/7080fade-50fb-4abb-98e8-68e35d411dd8" />
<img width="180" alt="photo_18" src="https://github.com/user-attachments/assets/1434eee9-3975-4ea3-8727-d32ff3ba8c7d" />
<img width="180" alt="photo_17" src="https://github.com/user-attachments/assets/8494e242-f86c-4b72-a257-6b95cda01b18" />
<img width="180" alt="photo_26" src="https://github.com/user-attachments/assets/a2b07a75-2e60-4568-bcc1-0289d6ec83ba" />
<img width="180" alt="photo_25" src="https://github.com/user-attachments/assets/f578460a-dc0d-45bc-b52c-c7d5ecb78d36" />
<img width="180" alt="photo_24" src="https://github.com/user-attachments/assets/ea350981-52f0-457e-a0f9-9a432c0662f9" />
<img width="180" alt="photo_23" src="https://github.com/user-attachments/assets/38c50cc8-e626-4ff9-b495-90efde52cc6d" />
<img width="180" alt="photo_30" src="https://github.com/user-attachments/assets/8f1b85ee-f1c6-4914-9fab-5bcfd6b95550" />
<img width="180" alt="photo_29" src="https://github.com/user-attachments/assets/fdf607d4-6d75-4cb4-96a5-cfbc03bfc8a4" />
<img width="180" alt="photo_28" src="https://github.com/user-attachments/assets/8dd4ac85-b1b9-496f-a089-5f589afd71a3" />
<img width="180" alt="photo_27" src="https://github.com/user-attachments/assets/82ef9369-93cc-4f30-9636-df581204a3ad" />
<img width="180" alt="photo_37" src="https://github.com/user-attachments/assets/7443090a-57f2-4246-b2d1-0d069e3d4796" />
<img width="180" alt="photo_36" src="https://github.com/user-attachments/assets/486590ed-4a22-4f67-804e-d1ad0a60b65b" />
<img width="180" alt="photo_35" src="https://github.com/user-attachments/assets/60f9b9cd-ed4c-4122-aaaa-e80f4bbf272d" />
<img width="180" alt="photo_34" src="https://github.com/user-attachments/assets/589bd588-3a58-4b1b-8962-f590ed8b3c12" />
<img width="180" alt="photo_33" src="https://github.com/user-attachments/assets/1ceca773-1500-47d1-a1d7-14c4be67fb1c" />
<img width="180" alt="photo_32" src="https://github.com/user-attachments/assets/9f97a397-8505-40e0-add5-a5ebb7cb8637" />
<img width="180" alt="photo_31" src="https://github.com/user-attachments/assets/f9240edb-f779-487e-8875-f81d00f60638" />
  
</p>



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
