// The teams of the platform, and the names and label every app that acts on
// their namespaces agrees on.
{
  // Label selecting every object owned by a team. Changing it orphans the
  // namespaces from the network policies that match on it.
  label:: 'platform.example.com/team',

  // Each team, with the `cpu` and `memory` (quantity strings) its namespace
  // is allowed to request.
  teams:: {
    data: { cpu: '8', memory: '32Gi' },
    web: { cpu: '4', memory: '8Gi' },
  },

  // The namespace of team `name`.
  namespace(name):: 'team-%s' % name,
}
