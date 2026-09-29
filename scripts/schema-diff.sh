#!/bin/sh
# 두 라우터 파드(또는 서비스)의 introspection 결과를 정규화해 비교한다.
# 전환 전후의 라우터가 같은 스키마를 서빙하는지 확인하는 용도.
#   ./scripts/schema-diff.sh pod/apollo-router-aaa pod/apollo-router-bbb
set -e
CTX=${CTX:-supergraph}; NS=${NS:-supergraph}
A=$1; B=$2
dump() {
  kubectl --context "$CTX" -n "$NS" port-forward "$1" 4300:4000 >/dev/null 2>&1 &
  PF=$!; sleep 2
  curl -s localhost:4300/ -H 'content-type: application/json' \
    -d '{"query":"{ __schema { types { name kind fields { name type { name kind ofType { name kind } } } inputFields { name } enumValues { name } } } }"}' \
    | python3 -c "
import json,sys
t=json.load(sys.stdin)['data']['__schema']['types']
for ty in sorted(t,key=lambda x:x['name']):
    if ty['name'].startswith('__'): continue
    print(ty['kind'], ty['name'])
    for f in sorted(ty.get('fields') or [],key=lambda x:x['name']): print('  field', f['name'], json.dumps(f['type'],sort_keys=True))
    for f in sorted(ty.get('inputFields') or [],key=lambda x:x['name']): print('  input', f['name'])
    for e in sorted(ty.get('enumValues') or [],key=lambda x:x['name']): print('  enum', e['name'])
"
  kill $PF; wait $PF 2>/dev/null || true
}
dump "$A" > /tmp/schema-a.txt
dump "$B" > /tmp/schema-b.txt
echo "$A: $(grep -c '^[A-Z]' /tmp/schema-a.txt) types, $(grep -c '  field' /tmp/schema-a.txt) fields"
echo "$B: $(grep -c '^[A-Z]' /tmp/schema-b.txt) types, $(grep -c '  field' /tmp/schema-b.txt) fields"
if diff -u /tmp/schema-a.txt /tmp/schema-b.txt; then echo "IDENTICAL"; else echo "DIFFERENT"; exit 1; fi
