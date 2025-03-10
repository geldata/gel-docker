load testbase

setup() {
  build_container
  docker build -t gel-test:bootstrap tests/bootstrap
}

teardown() {
  common_teardown
}

@test "full bootstrap" {
  local container_id
  local instance

  create_instance container_id instance '{"image":"gel-test:bootstrap"}'

  output=$(gel -I "${instance}" query --output-format=tab-separated \
    "SELECT Bootstrap.name ORDER BY Bootstrap.name")
  echo "$output"
  run echo "$output"
  [[ ${lines[0]} = "01-shell script" ]]
  [[ ${lines[1]} = "02-edgeql file" ]]
  [[ ${lines[2]} = "03-edgeql file" ]]
  [[ ${lines[3]} = "04-shell script late" ]]
  [[ ${lines[4]} = "05-edgeql file late" ]]
}

@test "full bootstrap tenant id" {
  local container_id
  local instance
  local tenant_id

  create_instance container_id instance '{"image":"gel-test:bootstrap"}' \
    -- \
    --tenant-id=tenantid

  output=$(gel -I "${instance}" query --output-format=tab-separated \
    "SELECT Bootstrap.name ORDER BY Bootstrap.name")
  echo "$output"
  run echo "$output"
  [[ ${lines[0]} = "01-shell script" ]]
  [[ ${lines[1]} = "02-edgeql file" ]]
  [[ ${lines[2]} = "03-edgeql file" ]]
  [[ ${lines[3]} = "04-shell script late" ]]
  [[ ${lines[4]} = "05-edgeql file late" ]]
}
