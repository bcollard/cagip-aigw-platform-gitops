# CAGIP AI Gateway — platform GitOps

Synced by the Argo CD Application `cagip-aigw-platform` (project `cagip-platform`), impersonating
`cagip-platform:platform-gitops`. Demo content for a Kong AI Gateway 2.x lab on Kong Operator:
the bank, entities and hostnames are illustrative.

| Path | What |
|---|---|
| `cluster/` | persona RBAC and the ValidatingAdmissionPolicies that govern every entity namespace |
| `entities/<entity>/00-namespace.yaml` | the entity namespace; labels and annotations are its governance parameters |
| `entities/<entity>/10-aigateway.yaml` | the entity's own AI Gateway: `OnPremAIGateway` + `AIGatewayDataPlane`, certificate, SNI |
| `entities/<entity>/30-policies.yaml` | platform core: ADFS auth strategy, golden and `cagip-shared-*` policies |
| `entities/<entity>/40-golden-observability.yaml` | golden rules: Prometheus and OpenTelemetry, global on the entity gateway |
| `entities/<entity>/50-entity-rbac.yaml` | the entity's personas and its GitOps service account |

Not in Git, created out of band: the Kong licence, the fleet TLS Secret, the backend credential
`aigw-backend-creds`. Model providers, Models and AI policies are the entity's: see
`cagip-aigw-<entity>-gitops`.
