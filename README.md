# apollo-router-supergraph-on-kubernetes

Apollo Router의 슈퍼그래프를 어디서 합칠 것인가. 스키마 레지스트리 없이 **라우터 파드의 init container가 클러스터 안의 서브그래프를 introspect해서 합치는 방식**(전환 전)과, **publish를 CronJob으로 떼어내고 라우터는 GraphOS Uplink에서 받는 방식**(전환 후)을 같은 base 위에 두 overlay로 재현한 예제입니다.

```
subgraphs/
  products/   Product 엔티티 (@key)           Apollo Server 5 + @apollo/subgraph
  reviews/    Product 를 확장해 reviews 를 붙임
k8s/
  base/subgraphs/          두 서브그래프 Deployment/Service
  base/router/
    deployment.yaml        init container(schema-composer) 가 rover 로 compose → emptyDir → 라우터 --supergraph
    subgraphs-configmap.yaml  서브그래프 목록의 단일 출처 (${POD_NAMESPACE} 치환)
    configmap.yaml         router.yaml
  overlays/init-compose/   전환 전. base 그대로
  overlays/uplink/         전환 후. init 과 볼륨을 $patch: delete, publish CronJob 추가, Secret 참조
scripts/
  minikube-up.sh           Minikube 프로필 생성 + 이미지 빌드
  query.sh                 두 서브그래프를 가로지르는 쿼리
```

## 실행 (전환 전)

```bash
./scripts/minikube-up.sh
kubectl --context supergraph apply -k k8s/overlays/init-compose
kubectl --context supergraph -n supergraph rollout status deploy/apollo-router
./scripts/query.sh
```

## 실행 (전환 후)

GraphOS 그래프와 키가 필요합니다. Secret은 직접 만듭니다.

```bash
kubectl --context supergraph -n supergraph create secret generic apollo-router-studio \
  --from-literal=APOLLO_KEY='service:...' --from-literal=APOLLO_GRAPH_REF='<graph>@<variant>'
kubectl --context supergraph apply -k k8s/overlays/uplink
kubectl --context supergraph -n supergraph create job --from=cronjob/apollo-router-publish publish-now
```

## 글

- [레지스트리 없이 init container로 슈퍼그래프 합치기](https://songtomtom.github.io/blog/apollo-router-init-container-compose)
- [init container를 걷어내고 Uplink로](https://songtomtom.github.io/blog/apollo-router-uplink-publish-cronjob)
