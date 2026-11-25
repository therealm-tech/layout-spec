local team = import 'team.libsonnet';

local objects(name, quota) =
  local labels = { [team.label]: name };
  local metadata = { namespace: team.namespace(name), labels: labels };
  [
    {
      apiVersion: 'v1',
      kind: 'Namespace',
      metadata: { name: team.namespace(name), labels: labels },
    },
    {
      apiVersion: 'v1',
      kind: 'ResourceQuota',
      metadata: metadata { name: 'team' },
      spec: {
        hard: {
          'requests.cpu': quota.cpu,
          'requests.memory': quota.memory,
          'limits.memory': quota.memory,
        },
      },
    },
    {
      apiVersion: 'v1',
      kind: 'LimitRange',
      metadata: metadata { name: 'team' },
      spec: {
        limits: [
          {
            type: 'Container',
            defaultRequest: { cpu: '50m', memory: '64Mi' },
            default: { memory: '128Mi' },
          },
        ],
      },
    },
  ];

std.flattenArrays([
  objects(name, team.teams[name])
  for name in std.objectFields(team.teams)
])
