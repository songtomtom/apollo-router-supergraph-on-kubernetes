#!/bin/sh
# 예제용 Minikube 프로필을 만들고 서브그래프 이미지를 빌드해 넣는다.
set -e
PROFILE=${PROFILE:-supergraph}
minikube start --profile "$PROFILE" --driver=docker --cpus=4 --memory=4096
for s in products reviews; do
  minikube --profile "$PROFILE" image build -t "subgraph-$s:dev" "subgraphs/$s"
done
echo "kubectl --context $PROFILE apply -k k8s/overlays/init-compose"
