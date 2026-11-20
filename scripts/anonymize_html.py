#!/usr/bin/env python3
"""Anonimizador de capturas HTML de MIEL para reportes y fixtures de LibreMIEL.

Elimina datos personales (DNIs, nombres, correos, teléfonos, cookies, tokens y
cuerpos privados de mensajes/observaciones) preservando intactas las etiquetas,
clases CSS, estructura de tablas y atributos `data-*` necesarios para depurar
y testear los parsers de LibreMIEL.

Uso:
    python3 scripts/anonymize_html.py entrada.html -o salida_anonimizada.html
    python3 scripts/anonymize_html.py entrada.html -o salida.html --extra "APELLIDO" "NOMBRE"
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, List


class Anonymizer:
    """Reemplaza PII en HTML de MIEL de manera determinista y consistente."""

    def __init__(self, extra_terms: Iterable[str] = ()) -> None:
        self._person_map: Dict[str, str] = {}
        self._person_counter = 0
        self._user_id_map: Dict[str, str] = {}
        self._user_id_counter = 900000
        self._extra_terms: List[str] = [
            term.strip() for term in extra_terms if term and term.strip()
        ]

    def _alias_person(self, raw_name: str, prefix: str = "PERSONA") -> str:
        key = re.sub(r"\s+", " ", raw_name).strip().upper()
        if not key:
            return raw_name
        if key not in self._person_map:
            self._person_counter += 1
            self._person_map[key] = f"{prefix}, EJEMPLO {self._person_counter}"
        return self._person_map[key]

    def _alias_user_id(self, raw_id: str) -> str:
        key = raw_id.strip()
        if not key or not key.isdigit():
            return raw_id
        if key not in self._user_id_map:
            self._user_id_counter += 1
            self._user_id_map[key] = str(self._user_id_counter)
        return self._user_id_map[key]

    def anonymize(self, html_text: str) -> str:
        out = html_text

        # 1. Términos sensibles adicionales provistos por el usuario (--extra)
        for idx, term in enumerate(
            sorted(self._extra_terms, key=len, reverse=True), start=1
        ):
            out = re.sub(
                re.escape(term),
                f"DATO_OCULTO_{idx}",
                out,
                flags=re.IGNORECASE,
            )

        # 2. Cookies, sesiones y claves VAPID/tracking inline
        out = re.sub(
            r"(PHPSESSID\s*=\s*)([A-Za-z0-9,_-]{8,})",
            r"\1ANON_PHPSESSID",
            out,
            flags=re.IGNORECASE,
        )
        out = re.sub(
            r"(const\s+pushKey\s*=\s*['\"])([^'\"]+)(['\"])",
            r"\1ANON_PUSH_KEY\3",
            out,
        )

        # 3. IDs de usuario en JS inline y atributos data-idusuario / data-nombreusuario
        out = re.sub(
            r"(var\s+usuarioId\s*=\s*['\"])(\d+)(['\"])",
            lambda m: f"{m.group(1)}{self._alias_user_id(m.group(2))}{m.group(3)}",
            out,
        )
        out = re.sub(
            r"(data-idusuario\s*=\s*['\"])(\d+)(['\"])",
            lambda m: f"{m.group(1)}{self._alias_user_id(m.group(2))}{m.group(3)}",
            out,
            flags=re.IGNORECASE,
        )
        out = re.sub(
            r"(data-nombreusuario\s*=\s*['\"])([^'\"]+)(['\"])",
            lambda m: f"{m.group(1)}{self._alias_person(m.group(2), 'USUARIO')}{m.group(3)}",
            out,
            flags=re.IGNORECASE,
        )

        # 4. Nombre de usuario en cabecera (.nombreUsuario)
        out = re.sub(
            r'(class="[^"]*\bnombreUsuario\b[^"]*"[^>]*>)(\s*)([^<]+)',
            lambda m: f"{m.group(1)}{m.group(2)}{self._alias_person(m.group(3), 'ALUMNO')}",
            out,
            flags=re.IGNORECASE,
        )

        # 5. Menciones @USUARIO dentro de .tagUsuario
        out = re.sub(
            r'(<strong[^>]*class="[^"]*\btagUsuario\b[^"]*"[^>]*>)(@?[^<]+)(</strong>)',
            lambda m: (
                f"{m.group(1)}@{self._alias_person(m.group(2).lstrip('@'), 'USUARIO')}{m.group(3)}"
            ),
            out,
            flags=re.IGNORECASE,
        )

        # 6. Autores de mensajes en foros: <div><strong>NOMBRE</strong></div>
        out = re.sub(
            r"(<div>\s*<strong\s*>)([^<]{3,80})(</strong>\s*</div>)",
            lambda m: f"{m.group(1)}{self._alias_person(m.group(2), 'AUTOR')}{m.group(3)}",
            out,
            flags=re.IGNORECASE,
        )

        # 7. Remitentes en tabla de Mensajería (segunda celda tras fecha DD/MM/YYYY)
        out = re.sub(
            r"(<tr[^>]*mensaje-(?:no-)?leido[^>]*>\s*<td[^>]*>\s*\d{2}/\d{2}/\d{4}\s*</td>\s*<td[^>]*>)([^<]+)(</td>)",
            lambda m: f"{m.group(1)}{self._alias_person(m.group(2), 'REMITENTE')}{m.group(3)}",
            out,
            flags=re.IGNORECASE | re.DOTALL,
        )

        # 8. Docentes / integrantes en Portafolio ("Corregido por:", "Observaciones:", "Mensaje:")
        out = re.sub(
            r"(Corregido por:\s*</div>\s*<div[^>]*>)([^<]+)(</div>)",
            lambda m: f"{m.group(1)}{self._alias_person(m.group(2), 'DOCENTE')}{m.group(3)}",
            out,
            flags=re.IGNORECASE | re.DOTALL,
        )
        out = re.sub(
            r"(Observaciones:\s*</div>\s*<div[^>]*>)([\s\S]*?)(</div>)",
            r"\1[Observación anonimizada]\3",
            out,
            flags=re.IGNORECASE,
        )
        out = re.sub(
            r"(Mensaje:\s*</div>\s*<div[^>]*>)([\s\S]*?)(</div>)",
            r"\1[Mensaje de entrega anonimizado]\3",
            out,
            flags=re.IGNORECASE,
        )

        # 9. Cuerpo de mensajes del foro (preservando .tagUsuario si existe al inicio)
        def _clean_forum_body(match: re.Match[str]) -> str:
            open_tag, body, close_tag = match.group(1), match.group(2), match.group(3)
            tags = re.findall(
                r'<strong[^>]*class="[^"]*\btagUsuario\b[^"]*"[^>]*>.*?</strong>',
                body,
                flags=re.IGNORECASE | re.DOTALL,
            )
            attachments = re.findall(
                r'<a[^>]+href="[^"]*forov2/event/descargar/[^"]+"[^>]*>.*?</a>',
                body,
                flags=re.IGNORECASE | re.DOTALL,
            )
            parts = []
            if tags:
                parts.append(" ".join(tags))
            parts.append("<p>[Contenido del mensaje anonimizado]</p>")
            if attachments:
                parts.extend(attachments)
            return f"{open_tag}{''.join(parts)}{close_tag}"

        out = re.sub(
            r'(<div[^>]*class="[^"]*\bforo-contenido-mensaje\b[^"]*"[^>]*>)([\s\S]*?)(</div>)',
            _clean_forum_body,
            out,
            flags=re.IGNORECASE,
        )

        # 10. Correos electrónicos
        out = re.sub(
            r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b",
            "usuario@ejemplo.test",
            out,
        )

        # 11. DNIs típicos argentinos (7-8 dígitos) en textos visibles o inputs de usuario
        out = re.sub(
            r'((?:name|id)\s*=\s*["\'](?:usuario|dni|documento)["\'][^>]*value\s*=\s*["\'])(\d{7,9})(["\'])',
            r"\g<1>00000000\3",
            out,
            flags=re.IGNORECASE,
        )
        out = re.sub(
            r"(\b(?:DNI|Documento|Legajo|Usuario)\s*[:#]?\s*)(\d{1,2}\.?\d{3}\.?\d{3}\b|\d{7,8}\b)",
            r"\g<1>00000000",
            out,
            flags=re.IGNORECASE,
        )

        # 12. Teléfonos argentinos comunes (+54 9 11 ... / 11-xxxx-xxxx)
        out = re.sub(
            r"(?:\+?54\s*9?\s*)?(?:\(?0?\d{2,4}\)?[\s.-]*)?\d{4}[\s.-]\d{4}\b",
            "00-0000-0000",
            out,
        )

        # 13. Reemplazo final de cualquier repetición exacta de nombres detectados
        for original_upper, alias in sorted(
            self._person_map.items(), key=lambda kv: len(kv[0]), reverse=True
        ):
            if len(original_upper) >= 5:
                out = re.sub(
                    re.escape(original_upper), alias, out, flags=re.IGNORECASE
                )

        return out


def parse_args(argv: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Anonimiza capturas HTML de MIEL para usarlas en reportes o tests de LibreMIEL."
    )
    parser.add_argument("input", type=Path, help="Ruta al archivo HTML original.")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        required=True,
        help="Ruta donde se guardará el HTML anonimizado.",
    )
    parser.add_argument(
        "--extra",
        nargs="*",
        default=[],
        help="Palabras o frases adicionales a ocultar (ej. tu apellido, nombre o DNI).",
    )
    return parser.parse_args(argv)


def main(argv: List[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)

    if not args.input.is_file():
        print(f"Error: no se encontró el archivo '{args.input}'.", file=sys.stderr)
        return 1

    if args.input.resolve() == args.output.resolve():
        print(
            "Error: el archivo de salida debe ser distinto al de entrada para evitar sobrescribir el original.",
            file=sys.stderr,
        )
        return 1

    raw_html = args.input.read_text(encoding="utf-8", errors="replace")
    anonymizer = Anonymizer(extra_terms=args.extra)
    sanitized = anonymizer.anonymize(raw_html)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(sanitized, encoding="utf-8")

    print(f"HTML anonimizado guardado en: {args.output}")
    print(
        "Recordatorio: revisá el archivo resultante antes de subirlo a un Issue o Pull Request."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
