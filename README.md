# CAGIP AI Gateway platform (Helm chart)

Demo content for a Kong AI Gateway 2.x lab on Kong Operator: the bank, entities and host names
are illustrative.

CAGIP builds the AI Gateway platform; each entity (BU) runs it on its own Kubernetes cluster and
adds its own AI configuration with its own chart. This repo is CAGIP's part.

| Path | What |
|---|---|
| `chart/` | the `cagip-aigw-platform` chart, one release per entity cluster |
| `chart/charts/kong-operator-*.tgz` | Kong Operator chart, vendored from the nightly's commit (its AI CRDs are ahead of the published chart) |
| `clusters/<entity>.yaml` | one values file per entity cluster: host name, sizing, observability endpoints, governance limits |

## What the chart installs

| Template | Objects |
|---|---|
| Kong Operator subchart | the operator, its CRDs, its CA (cert-manager) |
| `license.yaml` | `KongLicense`; the value is an Argo CD Application parameter, never in Git |
| `gateway.yaml` | `OnPremAIGateway` + `AIGatewayDataPlane`, TLS certificate and SNI |
| `auth.yaml` | the central auth strategy `cagip-oidc-adfs` (ADFS) |
| `policies-global.yaml` | global policies: Prometheus, OpenTelemetry, HTTP log, correlation ID, claims to log fields |
| `policies-mandatory.yaml` | `cagip-strip-identity`, `cagip-baseline-guard`: every entity Model must attach them |
| `entity-rbac.yaml` | the Role of the entity's deployer: AI providers, Models, AI policies, consumer groups, MCP servers |
| `governance.yaml` | 6 ValidatingAdmissionPolicies on what the entity writes |

## Governance

The Argo CD Application `cagip-aigw-platform` syncs this chart as `argocd/platform-deployer`
(cluster-admin). The entity's Application syncs its own chart as `argocd/entity-deployer`, which
gets only what this chart grants:

| Layer | Decides |
|---|---|
| Argo CD AppProject | which repo, which namespace, which kinds |
| RBAC (`entity-rbac.yaml`) | which kinds, in the gateway namespace only; no Secrets |
| VAPs (`governance.yaml`) | what the objects contain |

| VAP | Rule for the entity |
|---|---|
| `aigw-platform-objects` | objects labelled `cagip.io/owner` and `cagip-*` names belong to this chart |
| `aigw-policies` | policy types from `governance.policyTypes`; no global policy, no Lua |
| `aigw-models` | every Model lists `cagip-oidc-adfs` and attaches the mandatory policies; no payload logging; no `allowAuthOverride`; target hosts from `governance.llmHosts` |
| `aigw-model-providers` | types from `governance.providerTypes`; keys only as `secretRef` to `entity-credentials`; GCP token hosts from `governance.llmHosts` |
| `aigw-mcp-servers` | conversion-listener only; upstreams from `governance.mcpHosts`; lists `cagip-oidc-adfs` |
| `aigw-token-cap` | usage plans: Redis counters, a total budget, every token limit under `governance.tokenCapPerHour` |

The VAPs apply to every identity except the platform deployer, Kong Operator, kube-system
controllers and `system:masters`.

Not in Git, created out of band: the gateway's TLS Secret, the entity's `entity-credentials`
Secret. The licence is an Application parameter.
