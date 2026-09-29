#!/bin/sh
# 라우터에 포트포워딩해 두 서브그래프를 가로지르는 쿼리를 보낸다.
set -e
CTX=${CTX:-supergraph}
kubectl --context "$CTX" -n supergraph port-forward svc/apollo-router 4000:4000 >/dev/null 2>&1 &
PF=$!; trap 'kill $PF' EXIT; sleep 2
curl -s localhost:4000/ -H 'content-type: application/json' \
  -d '{"query":"{ products { name price averageRating reviews { body rating } } }"}'
echo
