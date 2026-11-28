#!/bin/sh
exec ssh -X "${USUARIO:?defina USUARIO}@${HOST:?defina HOST}" firefox-esr
