load testbase

setup() {
  build_container
  docker build -t gel-test:schema tests/schema
}

teardown() {
  common_teardown
}

@test "applying schema" {
  local container_id
  local instance

  create_instance container_id instance '{"image":"gel-test:schema"}'

  # wait until migrations are complete
  sleep 3

  # now check that this worked
  gel -I "${instance}" query --output-format=tab-separated \
    "INSERT Item { name := 'hello' }"
}

@test "skip applying schema gel" {
  local container_id
  local instance

  create_instance container_id instance '{"image":"gel-test:schema"}' \
    --env=GEL_DOCKER_APPLY_MIGRATIONS=never

  # wait until migrations are complete
  sleep 3

  # now check that this worked
  gel -I "${instance}" query --output-format=tab-separated \
    "CREATE TYPE Item"
}

@test "skip applying schema" {
  local container_id
  local instance

  create_instance container_id instance '{"image":"gel-test:schema"}' \
    --env=GEL_DOCKER_APPLY_MIGRATIONS=never

  # wait until migrations are complete
  sleep 3

  # now check that this worked
  gel -I "${instance}" query --output-format=tab-separated \
    "CREATE TYPE Item"
}

@test "apply schema to named database" {
  local container_id
  local instance

  create_instance container_id instance '{
        "image":"gel-test:schema",
        "database":"hello"
    }' \
    --env=GEL_SERVER_DEFAULT_BRANCH=hello

  # wait until migrations are complete
  sleep 3

  run gel -I "${instance}" query "SELECT sys::get_current_database()"
  echo "${lines[@]}"
  [[ ${lines[-1]} = '"hello"' ]]

  gel -I "${instance}" query --output-format=tab-separated \
    "INSERT Item { name := 'hello' }"
}
