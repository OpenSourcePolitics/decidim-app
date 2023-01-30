# frozen_string_literal: true
url=${1:-"http://localhost:3000"}
ok_code=("301" "302" "200")

echo "Testing $url"

for i in {1..10}; do
  status_code=$(curl -s -o /dev/null -w "%{http_code}" $url)
  # shellcheck disable=SC2199
  if [[ ${ok_code[@]} =~ $status_code ]]; then
    echo "$status_code found"
    exit 0
  fi
  echo "Try $i: status code $status_code"
  sleep 6
done

echo "Failed to get an adequate response from $url"
exit 1
