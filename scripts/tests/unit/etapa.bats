#!/usr/bin/env bats
# Testes unitários — saída e formato dos scripts auxiliares

@test "doctor --env produz linha KEY=VALUE com T0=" {
  run sh "$BATS_TEST_DIRNAME/../../doctor.sh" --env
  # exit 1 é ok (nada instalado), mas a linha deve existir
  echo "$output" | grep -qE "T0=(sim|nao)"
}

@test "doctor --json produz objeto JSON com chave T0" {
  run sh "$BATS_TEST_DIRNAME/../../doctor.sh" --json
  echo "$output" | grep -qE '"T0":"(sim|nao)"'
}

@test "doctor --cache grava .work/doctor-cache.env" {
  run sh "$BATS_TEST_DIRNAME/../../doctor.sh" --cache
  [ -f "$BATS_TEST_DIRNAME/../../../.work/doctor-cache.env" ]
}

@test "etapa.sh status executa sem crash" {
  run sh "$BATS_TEST_DIRNAME/../../etapa.sh" status
  [ "$status" -eq 0 ]
}

@test "watchdog.sh roda e termina com exit 0" {
  run sh "$BATS_TEST_DIRNAME/../../watchdog.sh"
  [ "$status" -eq 0 ]
}
