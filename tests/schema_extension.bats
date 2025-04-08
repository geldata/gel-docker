load testbase

setup() {
  build_container
  docker build -t gel-test:schema-extension tests/schema_with_extension
}

teardown() {
  common_teardown
}

@test "install an extension" {
  local container_id
  local instance

  create_instance container_id instance '{"image":"gel-test:schema-extension"}'

  # wait until migrations are complete
  sleep 3

  # Complex objects like PostGisGeometry cannot be printed tab-separated
  edgedb -I "${instance}" query \
    "select ext::postgis::makepoint(1.0, 2.0)"
}
