{{/* Reference to this cluster's AI Gateway, on every AI entity. */}}
{{- define "cagip.gatewayRef" -}}
aiGatewayRef: { group: aigateway.konghq.com, kind: OnPremAIGateway, namespacedRef: { name: {{ .Values.gateway.name }} } }
{{- end }}

{{/* Metadata of a platform-owned AI entity: the label aigw-platform-objects protects, and an
     Argo CD wave after Kong Operator and its CRDs. */}}
{{- define "cagip.meta" -}}
namespace: {{ .Values.gateway.namespace }}
labels:
  cagip.io/owner: platform
  app.kubernetes.io/part-of: cagip-aigw-platform
annotations:
  argocd.argoproj.io/sync-wave: "2"
  argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
{{- end }}

{{/* VAP matchCondition: the rules apply to every identity except the platform's own. */}}
{{- define "cagip.notPlatform" -}}
- name: not-platform
  expression: >-
    !(request.userInfo.username == 'system:serviceaccount:{{ .Values.governance.platformServiceAccount.namespace }}:{{ .Values.governance.platformServiceAccount.name }}' ||
      request.userInfo.username.startsWith('system:serviceaccount:{{ .Release.Namespace }}:') ||
      request.userInfo.username.startsWith('system:serviceaccount:kube-system:') ||
      'system:masters' in request.userInfo.groups)
{{- end }}

{{/* A ValidatingAdmissionPolicyBinding scoped to the gateway namespace. */}}
{{- define "cagip.binding" -}}
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata: { name: {{ .name }}, labels: { app.kubernetes.io/part-of: cagip-aigw-platform } }
spec:
  policyName: {{ .name }}
  validationActions: [Deny]
  matchResources:
    namespaceSelector: { matchLabels: { kubernetes.io/metadata.name: {{ .ns }} } }
{{- end }}

{{/* A list of strings as a CEL list literal with single quotes: ['a', 'b']. */}}
{{- define "cagip.cel" -}}
[{{ range $i, $v := . }}{{ if $i }}, {{ end }}'{{ $v }}'{{ end }}]
{{- end }}

{{/* CEL: host h matches a denied entry (the entry itself or a subdomain of it). */}}
{{- define "cagip.denied" -}}
{{ include "cagip.cel" . }}.exists(d, h == d || h.endsWith('.' + d))
{{- end }}
