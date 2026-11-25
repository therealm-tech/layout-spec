local team = import 'team.libsonnet';

[
  {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'same-team-only',
      namespace: team.namespace(name),
      labels: { [team.label]: name },
    },
    spec: {
      podSelector: {},
      policyTypes: ['Ingress'],
      ingress: [
        {
          from: [
            {
              namespaceSelector: {
                matchLabels: { [team.label]: name },
              },
            },
          ],
        },
      ],
    },
  }
  for name in std.objectFields(team.teams)
]
