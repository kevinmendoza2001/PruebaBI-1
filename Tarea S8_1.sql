#1. Crear Base de Datos Relacional

CREATE DATABASE llantasSD;
USE llantasSD;

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50),
    correo VARCHAR(100),
    telefono VARCHAR(20)
);

CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50),
    marca VARCHAR(50),
    precio DECIMAL(10,2),
    stock INT
);

CREATE TABLE ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    fecha DATE,
    total DECIMAL(10,2),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE detalle_venta (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT,
    id_producto INT,
    cantidad INT,
    subtotal DECIMAL(10,2),
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);
-- Insertar clientes
INSERT INTO clientes (nombre, correo, telefono) VALUES
("Kevin Torres", "kevin@mail.com", "0999999999"),
("Laura Pérez", "laura@mail.com", "0988888888"),
("Carlos Ruiz", "carlos@mail.com", "0977777777");
select * from clientes;

-- Insertar productos
INSERT INTO productos (nombre, marca, precio, stock) VALUES
("Llantas Aro 15", "Michelin", 120.00, 50),
("Llantas Aro 16", "Pirelli", 135.00, 40),
("Llantas Aro 17", "Goodyear", 150.00, 30);
select * from productos;

-- Insertar ventas y detalle_venta (ejemplo)
INSERT INTO ventas (id_cliente, fecha, total) VALUES 
(1, "2025-11-01", 270.00);
select * from ventas;

INSERT INTO detalle_venta (id_venta, id_producto, cantidad, subtotal) VALUES 
(1, 1, 2, 240.00), (1, 2, 1, 135.00);
select * from detalle_venta;

# 2. Consultas SQL Básica

#1. WHERE
SELECT * FROM productos WHERE precio > 130;
#2. LIKE
SELECT * FROM clientes WHERE nombre LIKE "K%";
#3. ORDER BY
SELECT * FROM ventas ORDER BY fecha DESC;
#4. GROUP BY
SELECT id_cliente, COUNT(*) AS total_ventas FROM ventas GROUP BY id_cliente;
#5. Función agregada
SELECT AVG(precio) AS promedio_precio FROM productos;

#3. Subconsulta

#1. WHERE
SELECT * FROM productos WHERE id_producto IN (
    SELECT id_producto FROM detalle_venta WHERE cantidad >= 2
);

#2. FROM
SELECT AVG(subtotal) AS promedio_subtotal FROM (
    SELECT subtotal FROM detalle_venta WHERE cantidad >= 1
) AS sub;

#3. Anidada con función agregada

SELECT nombre FROM productos WHERE precio = (SELECT MAX(precio) FROM productos
);


#4. Crear 3 Índice

#indice 1: en correo de clientes
CREATE INDEX idx_correo ON clientes(correo);
SHOW INDEX FROM clientes;

#indice 2: en fecha de ventas
CREATE INDEX idx_fecha ON ventas(fecha);
SHOW INDEX FROM ventas;

#indice 3: en id_producto de detalle_venta
CREATE INDEX idx_id_producto ON detalle_venta(id_producto);
SHOW INDEX FROM detalle_venta;

#Ejecutar una consulta SIN índice (medir tiempo)

SET PROFILING = 1;

SELECT * FROM clientes WHERE correo = "kevin@mail.com";
SHOW PROFILES;

#Ejecutar la misma consulta CON índice (medir tiempo)

SELECT * FROM clientes WHERE correo = "kevin@mail.com";
SHOW PROFILES;

#5. Evaluación de Rendimient

#Consulta lenta sin índice
SELECT * FROM ventas WHERE fecha = "2025-11-01";

#Crear índice
CREATE INDEX idx_fecha_venta ON ventas(fecha);
#Repetir consulta y comparar tiempos con SHOW PROFILES o EXPLAIN

#6. Crear 3 Vista

#Vista 1: ventas por cliente
CREATE VIEW vista_ventas_cliente AS
SELECT c.nombre, v.fecha, v.total
FROM clientes c JOIN ventas v ON c.id_cliente = v.id_cliente;

#Vista 2: stock bajo
CREATE VIEW vista_stock_bajo AS
SELECT * FROM productos WHERE stock < 20;

#Vista 3: resumen de ventas
CREATE VIEW vista_resumen_ventas AS
SELECT v.id_venta, COUNT(d.id_producto) AS productos_vendidos, SUM(d.subtotal) AS total
FROM ventas v JOIN detalle_venta d ON v.id_venta = d.id_venta
GROUP BY v.id_venta;

#7. Crear 3 Transaccione

START TRANSACTION;

INSERT INTO ventas (id_cliente, fecha, total) VALUES (2, "2025-11-20", 300.00);
SAVEPOINT punto1;

UPDATE productos SET stock = stock - 2 WHERE id_producto = 1;

#ROLLBACK TO punto1; si ocurre error
COMMIT;

#Resultado esperado: nueva venta registrada, stock actualizado
SELECT * FROM ventas WHERE id_cliente = 2;
SELECT stock FROM productos WHERE id_producto = 1;

#8. Crear 3 Procedimientos Almacenado

DELIMITER $$

CREATE PROCEDURE registrar_venta(
    IN p_id_cliente INT,
    IN p_fecha DATE,
    IN p_total DECIMAL(10,2)
)
BEGIN
    DECLARE nueva_venta INT;
    INSERT INTO ventas (id_cliente, fecha, total) VALUES (p_id_cliente, p_fecha, p_total);
    SET nueva_venta = LAST_INSERT_ID();
    SELECT nueva_venta AS id_generado;
END$$

DELIMITER ;

#Ejecutar
CALL registrar_venta(3, "2025-11-20", 180.00);