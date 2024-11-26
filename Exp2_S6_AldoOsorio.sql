-- 1 
CREATE TABLE RECAUDACION_BONOS_MEDICOS (
    RUT_MEDICO VARCHAR2(12) NOT NULL, 
    NOMBRE_MEDICO VARCHAR2(50) NOT NULL, 
    TOTAL_RECAUDADO NUMBER(10, 2) NOT NULL, 
    UNIDAD_MEDICA VARCHAR2(40) NOT NULL 
);

INSERT INTO RECAUDACION_BONOS_MEDICOS (RUT_MEDICO, NOMBRE_MEDICO, TOTAL_RECAUDADO, UNIDAD_MEDICA)
SELECT 
 
    a.rut_med || '-' || a.dv_run AS RUT_MEDICO,
    a.pnombre || ' ' || a.apaterno || ' ' || a.amaterno AS NOMBRE_MEDICO,
    SUM(c.costo) AS TOTAL_RECAUDADO,
    b.nombre AS UNIDAD_MEDICA
FROM 
    BONO_CONSULTA c
    JOIN MEDICO a ON c.rut_med = a.rut_med
    JOIN UNIDAD_CONSULTA b ON a.uni_id = b.uni_id
WHERE 
    EXTRACT(YEAR FROM c.fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1
    AND a.car_id NOT IN (100, 500, 600)
GROUP BY 
    a.rut_med, a.dv_run, a.pnombre, a.apaterno, a.amaterno, b.nombre
ORDER BY 
    TOTAL_RECAUDADO ASC;

COMMIT;

SELECT * FROM RECAUDACION_BONOS_MEDICOS
ORDER BY TOTAL_RECAUDADO ASC;



--D 2
SELECT 
    e.nombre AS ESPECIALIDAD_MEDICA,
     COUNT(c.id_bono) AS CANTIDAD_BONOS,
    SUM(CASE 
              WHEN fp.fecha_pago IS NULL THEN c.costo 
              ELSE 0
        END)          AS MONTO_PERDIDA,
    MIN(c.fecha_bono) AS FECHA_BONO,
    CASE 
        WHEN fp.fecha_pago IS NULL THEN 'INCOBRABLE' 
        ELSE 'COBRABLE' 
    END AS ESTADO_COBRO
FROM 
        BONO_CONSULTA c
        JOIN DET_ESPECIALIDAD_MED d ON c.rut_med = d.rut_med AND c.esp_id = d.esp_id
        JOIN ESPECIALIDAD_MEDICA e ON d.esp_id = e.esp_id
        LEFT JOIN PAGOS fp ON c.id_bono = fp.id_bono
WHERE 
        EXTRACT (YEAR FROM c.fecha_bono ) >= 2022
GROUP BY 
    e.nombre, 
    CASE 
        WHEN fp.fecha_pago IS NULL THEN 'INCOBRABLE' 
        ELSE 'COBRABLE' 
    END
ORDER BY 
Monto_Perdida DESC;
    
    
    
--D3 


with PromedioBonos AS(

Select pac_run ,  ROUND(AVG(costo)) as promedioBonos
from bono_consulta
where to_char(fecha_bono, 'YYYY') = '2023'
group by pac_run
),


DatosPacientes AS (
    SELECT 
        2024 AS ANNIO_CALCULO, 
        a.pac_run AS PAC_RUN,
        a.dv_run AS DV_RUN, 
        FLOOR((SYSDATE - a.fecha_nacimiento) / 365.25) AS EDAD, 
        COUNT(DISTINCT b.id_bono) AS CANTIDAD_BONOS, 
        SUM(DISTINCT (b.costo)) AS MONTO_TOTAL_BONOS, 
        d.descripcion AS SISTEMA_SALUD 
    FROM 
        PACIENTE a
    LEFT JOIN 
        BONO_CONSULTA b ON a.pac_run = b.pac_run AND EXTRACT(YEAR FROM b.fecha_bono) = 2024 
    LEFT JOIN 
        SALUD d ON a.sal_id = d.sal_id
    LEFT JOIN 
        SISTEMA_SALUD s ON s.tipo_sal_id = s.tipo_sal_id
    GROUP BY 
        a.pac_run, a.dv_run, a.fecha_nacimiento, s.descripcion
)

SELECT 
    e.ANNIO_CALCULO, 
    e.PAC_RUN, 
    e.DV_RUN, 
    e.EDAD, 
    e.CANTIDAD_BONOS, 
    e.MONTO_TOTAL_BONOS, 
    e.SISTEMA_SALUD
FROM 
    DatosPacientes e
cross JOIN 
    PromedioBonos pb
WHERE 
    e.MONTO_TOTAL_BONOS <= pb.promedioBonos + 10 
    e.MONTO_TOTAL_BONOS DESC,
    e.EDAD DESC
    group by e.pac_run;
COMMIT;    

SELECT * 
FROM CANT_BONOS_PACIENTES_ANNIO
WHERE ANNIO_CALCULO = 2024
ORDER BY MONTO_TOTAL_BONOS DESC, EDAD DESC;