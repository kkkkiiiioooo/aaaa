#!/bin/sh
exec ssh -L 6080:localhost:6080 "${USUARIO:?defina USUARIO}@${HOST:?defina HOST}"
