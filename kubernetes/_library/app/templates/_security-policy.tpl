{{- define "app.securityPolicy" -}}
{{- $name := include "app.fullname" . -}}
{{- $slug := (.Values.oidc | default dict).slug | default (include "app.name" .) -}}
{{- $secret := (.Values.oidc | default dict).secretName | default (printf "%s-oidc-credentials" $name) -}}
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: {{ $name }}
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: {{ $name }}
  # Sign in with Authentik (application `{{ $slug }}`), restrict who may log in with policy bindings there.
  # The client credentials are in the `{{ $secret }}` Secret of this namespace, see the Authentik README.md
  oidc:
    provider:
      # Set explicitly, so Envoy Gateway does not fetch the discovery document: a fetch while Authentik restarts marks the policy Invalid
      issuer: https://auth.davydehaas.dev/application/o/{{ $slug }}/
      authorizationEndpoint: https://auth.davydehaas.dev/application/o/authorize/
      tokenEndpoint: https://auth.davydehaas.dev/application/o/token/
      endSessionEndpoint: https://auth.davydehaas.dev/application/o/{{ $slug }}/end-session/
    clientIDRef:
      name: {{ $secret }}
    clientSecret:
      name: {{ $secret }}
    redirectURL: https://{{ first .Values.route.hostnames }}/oauth2/callback
    logoutPath: /oauth2/logout
    scopes:
      - openid
      - email
      - profile
{{- end -}}
