#!/bin/sh
# CronJob 템플릿으로 일회성 publish Job을 만들고 로그를 보여 준다.
set -e
CTX=${CTX:-supergraph}; NS=${NS:-supergraph}
NAME=publish-$(date +%s)
kubectl --context "$CTX" -n "$NS" create job --from=cronjob/apollo-router-publish "$NAME"
kubectl --context "$CTX" -n "$NS" wait --for=condition=complete "job/$NAME" --timeout=300s
kubectl --context "$CTX" -n "$NS" logs "job/$NAME"
