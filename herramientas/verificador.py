# -*- coding: utf-8 -*-
"""
Verificador estatico de niveles de SOCAVON.

Lee los archivos .tscn directamente, extrae la geometria CSG de cada sala
y revisa cinco reglas SIN necesidad de abrir el juego.

Uso (desde la raiz del proyecto):
    python herramientas\\verificador.py
"""
import os
import re
import sys
from itertools import combinations

MARGEN_MINIMO = 2.0      # metros de roca recomendados alrededor de cada sala
DIST_MINIMA   = 1.5      # metros minimos entre dos objetos colocados
BOCA_MAXIMA   = 3.0      # un hueco mayor a esto entre dos salas es un atajo
ANCHO_TUNEL   = 4.0      # una caja de 4 m o menos de ancho es un tunel, no una sala

# escenas que no son objetos del mundo y no se revisan por posicion
SIN_POSICION = {'fin_nivel'}
# escenas que se colocan a proposito en la boca de un tunel
EN_BOCA = {'puerta', 'elevador'}


def leer_nivel(ruta):
    """Devuelve (roca, salas, objetos) a partir de un archivo .tscn."""
    with open(ruta, encoding='utf-8') as f:
        texto = f.read()

    escenas = {ident: nombre for nombre, ident in re.findall(
        r'\[ext_resource type="PackedScene"[^\]]*path="res://escenas/(\w+)\.tscn"'
        r' id="([^"]+)"', texto)}

    roca, salas, objetos = None, [], []

    for bloque in re.split(r'\n(?=\[node )', texto):
        cabecera = bloque.split('\n')[0]
        nombre = re.search(r'name="([^"]+)"', cabecera)
        if not nombre:
            continue
        nombre = nombre.group(1)

        t = re.search(r'transform = Transform3D\(([^)]+)\)', bloque)
        pos = [float(v) for v in t.group(1).split(',')][-3:] if t else [0.0, 0.0, 0.0]

        if 'CSGBox3D' in cabecera:
            m = re.search(r'size = Vector3\(([^)]+)\)', bloque)
            if not m:
                continue
            tam = [float(v) for v in m.group(1).split(',')]
            if 'operation = 2' in bloque:
                salas.append((nombre, pos, tam))
            else:
                roca = (nombre, pos, tam)

        inst = re.search(r'instance=ExtResource\("([^"]+)"\)', bloque)
        if inst:
            objetos.append((escenas.get(inst.group(1), '?'), nombre, pos))

    return roca, salas, objetos


def limites(pos, tam):
    return [(pos[i] - tam[i] / 2.0, pos[i] + tam[i] / 2.0) for i in range(3)]


def sala_que_contiene(salas, x, z, holgura=0.6):
    for nombre, pos, tam in salas:
        lx, _, lz = limites(pos, tam)
        if lx[0] + holgura <= x <= lx[1] - holgura and \
           lz[0] + holgura <= z <= lz[1] - holgura:
            return nombre
    return None


def revisar(ruta):
    nombre_nivel = os.path.splitext(os.path.basename(ruta))[0].upper()
    print()
    print('=' * 74)
    print('  ' + nombre_nivel + '   (' + ruta + ')')
    print('=' * 74)

    roca, salas, objetos = leer_nivel(ruta)
    if roca is None:
        print('  !! No se encontro el bloque de roca madre.')
        return 1

    rx, ry, rz = limites(roca[1], roca[2])
    area = sum(t[0] * t[2] for _, _, t in salas)
    print('  Roca madre : x[%.1f, %.1f]  y[%.1f, %.1f]  z[%.1f, %.1f]'
          % (rx[0], rx[1], ry[0], ry[1], rz[0], rz[1]))
    print('  Salas      : %d        Superficie de piso: %.0f m2' % (len(salas), area))
    print('  Objetos    : %d' % len(objetos))
    print('-' * 74)

    errores, avisos = [], []

    # --- REGLA 1: el piso de toda sala debe estar exactamente en y = 0 -------
    for nombre, pos, tam in salas:
        piso = pos[1] - tam[1] / 2.0
        if abs(piso) > 0.001:
            errores.append('[PISO]    %-20s su piso esta en y=%.2f, deberia ser 0'
                           % (nombre, piso))

    # --- REGLA 2: margen de roca en las seis caras --------------------------
    for nombre, pos, tam in salas:
        lx, ly, lz = limites(pos, tam)
        margenes = {
            '-X': lx[0] - rx[0], '+X': rx[1] - lx[1],
            '-Z': lz[0] - rz[0], '+Z': rz[1] - lz[1],
            'techo': ry[1] - ly[1],
        }
        for cara, valor in margenes.items():
            if valor < -1e-6:
                errores.append('[ROCA]    %-20s ABIERTA AL VACIO: sobresale %.2f m '
                               'por %s' % (nombre, -valor, cara))
            elif valor < MARGEN_MINIMO - 1e-6:
                avisos.append('[ROCA]    %-20s pared delgada: %.2f m por %s '
                              '(recomendado %.1f)' % (nombre, valor, cara, MARGEN_MINIMO))

    # --- REGLA 3: atajos entre dos salas grandes ----------------------------
    for (n1, p1, t1), (n2, p2, t2) in combinations(salas, 2):
        a1, a2 = limites(p1, t1), limites(p2, t2)
        ix = min(a1[0][1], a2[0][1]) - max(a1[0][0], a2[0][0])
        iz = min(a1[2][1], a2[2][1]) - max(a1[2][0], a2[2][0])
        if ix <= 0 or iz <= 0:
            continue
        # un tunel SIEMPRE desemboca en una sala: esa union es de diseno.
        # el atajo real es cuando DOS SALAS se abren entre si sin tunel,
        # y el hueco es amplio en AMBOS ejes.
        es_sala1 = min(t1[0], t1[2]) > ANCHO_TUNEL
        es_sala2 = min(t2[0], t2[2]) > ANCHO_TUNEL
        if es_sala1 and es_sala2 and min(ix, iz) > BOCA_MAXIMA:
            errores.append('[ATAJO]   %s <-> %s abren un hueco de %.1f x %.1f m '
                           '(mayor que una puerta de %.0f m)'
                           % (n1, n2, ix, iz, BOCA_MAXIMA))

    # --- REGLA 4: ningun objeto enterrado en la roca ------------------------
    for tipo, nombre, pos in objetos:
        if tipo in SIN_POSICION:
            continue
        holgura = 0.0 if tipo in EN_BOCA else 0.6
        if sala_que_contiene(salas, pos[0], pos[2], holgura) is None:
            errores.append('[OBJETO]  %-20s (%s) en (%.1f, %.1f) no esta dentro '
                           'de ninguna sala' % (nombre, tipo, pos[0], pos[2]))

    # --- REGLA 5: objetos encimados -----------------------------------------
    for (t1, n1, p1), (t2, n2, p2) in combinations(objetos, 2):
        if t1 in SIN_POSICION or t2 in SIN_POSICION:
            continue
        d = ((p1[0] - p2[0]) ** 2 + (p1[2] - p2[2]) ** 2) ** 0.5
        if d < DIST_MINIMA:
            avisos.append('[OBJETO]  %s y %s estan a solo %.1f m uno del otro'
                          % (n1, n2, d))

    if errores:
        print('  RESULTADO: %d ERROR(ES)' % len(errores))
        print()
        for f in errores:
            print('    ' + f)
    else:
        print('  RESULTADO: SIN ERRORES')
        print()
        print('    [PISO]    los %d pisos estan en y = 0' % len(salas))
        print('    [ROCA]    ninguna sala sobresale de la roca madre')
        print('    [ATAJO]   no hay huecos mayores a %.0f m entre salas' % BOCA_MAXIMA)
        print('    [OBJETO]  los objetos colocados estan dentro de una sala')

    if avisos:
        print()
        print('  Advertencias (no impiden jugar): %d' % len(avisos))
        print()
        for a in avisos:
            print('    ' + a)
    print()
    return len(errores)


def main():
    base = os.path.dirname(os.path.abspath(__file__))
    escenas = os.path.join(os.path.dirname(base), 'escenas')
    if len(sys.argv) > 1:
        rutas = sys.argv[1:]
    else:
        rutas = sorted(os.path.join(escenas, f) for f in os.listdir(escenas)
                       if re.fullmatch(r'nivel\d+\.tscn', f))

    print()
    print('  VERIFICADOR ESTATICO DE NIVELES  ---  SOCAVON')
    total = sum(revisar(r) for r in rutas)
    print('=' * 74)
    if total == 0:
        print('  TOTAL: %d nivel(es) revisado(s), SIN ERRORES.' % len(rutas))
    else:
        print('  TOTAL: %d error(es) en %d nivel(es).' % (total, len(rutas)))
    print('=' * 74)
    print()


if __name__ == '__main__':
    main()
