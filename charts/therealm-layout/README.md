# therealm-layout

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

ApplicationSet deploying one cluster's instances from the catalogue and platform repositories.

It implements the layout specified in [`SPEC.md`](../../SPEC.md).

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| application | object | see the keys below | Each Application the ApplicationSet generates, one per instance. |
| application.annotations | object | `{}` | Annotations of each Application. Values are ApplicationSet Go templates, with the same parameters as `application.name`. |
| application.defaultProject | string | `nil` | Project of an Application whose `app.yaml` sets none. Unset → every app must set `app.project`. |
| application.finalizers | list | `[]` | Finalizers of each Application, e.g. `resources-finalizer.argocd.argoproj.io` to delete its resources along with it. |
| application.helm | object | see the keys below | Helm source of a chart app. |
| application.helm.ignoreMissingValueFiles | bool | `true` | Skip the layout's `values.yaml` files that do not exist. Disabled, every level must provide one. |
| application.helm.releaseName | string | `nil` | Helm release name of a chart app, as an ApplicationSet Go template with the same parameters as `application.name`. Unset → `<app>`, shortened to `names.maxLength`. Set → used as is: keeping it short enough is then up to you. |
| application.labels | object | `{}` | Labels of each Application. Values are ApplicationSet Go templates, with the same parameters as `application.name`. |
| application.manifestGeneratePaths | bool | `true` | Set `argocd.argoproj.io/manifest-generate-paths` to the layout directories of each instance, so a commit elsewhere does not regenerate its manifests. Needs a git webhook. |
| application.manifests | object | see the keys below | Raw manifests applied from each instance directory. |
| application.manifests.include | string | `"manifests/*.yaml"` | Glob of the raw manifests applied from an instance directory, relative to it. |
| application.manifests.recurse | bool | `true` | Search sub-directories of the instance directory; needed for an `include` below a sub-directory. |
| application.name | string | `nil` | Name of each Application, as an ApplicationSet Go template reading `.values.cluster`, `.values.env`, `.values.app` and `.values.instance`. Unset → `<cluster>-<env>-<app>-<instance>`, shortened to `names.maxLength`. Set → used as is: keeping it short enough is then up to you. |
| application.revisionHistoryLimit | int | `0` | Number of sync results each Application keeps in its history. |
| application.syncPolicy | object | see the keys below | Sync policy of each Application. |
| application.syncPolicy.automated | object | `{}` | Automated sync of each Application, as in an Application's `syncPolicy.automated`. Empty → manual sync. |
| application.syncPolicy.retry | object | see the keys below | Retry policy of a failed sync. `null` → no retry. |
| application.syncPolicy.retry.backoff | object | see the keys below | Exponential backoff between two retries. |
| application.syncPolicy.retry.backoff.duration | string | `"15s"` | Delay before the first retry. |
| application.syncPolicy.retry.backoff.factor | int | `2` | Factor applied to the delay after each retry. |
| application.syncPolicy.retry.backoff.maxDuration | string | `"5m"` | Maximum delay between two retries. |
| application.syncPolicy.retry.limit | int | `10` | Maximum number of retries. |
| application.syncPolicy.syncOptions | list | `[]` | Sync options added to the ones each `app.yaml` declares. |
| applicationSet | object | see the keys below | The ApplicationSet this release renders. |
| applicationSet.annotations | object | `{}` | Annotations of the ApplicationSet. |
| applicationSet.finalizers | list | `[]` | Finalizers of the ApplicationSet. With `resources-finalizer.argocd.argoproj.io`, deleting the ApplicationSet keeps the Applications it generated when its effective `applicationsSync` policy forbids deletion (`create-only` or `create-update`; the ApplicationSet's own policy counts only when the controller allows the policy override): the controller removes their owner references before the ApplicationSet goes. This holds for a background cascading delete, `kubectl delete`'s default, not for a foreground one, the default of an Argo CD prune or cascading Application deletion. Under `sync` or `create-delete`, the Applications are deleted with the ApplicationSet. |
| applicationSet.goTemplateOptions | list | `["missingkey=error"]` | Go template options of the ApplicationSet. Without `missingkey=error`, a missing field renders empty instead of failing. |
| applicationSet.labels | object | `{}` | Labels of the ApplicationSet. |
| applicationSet.name | tpl/string | `nil` | Name of the ApplicationSet, rendered with Helm's `tpl`. Unset → `root-<cluster>`. |
| applicationSet.requeueAfterSeconds | int | `nil` | Polling interval of every git generator, in seconds. Unset → Argo CD's default. |
| applicationSet.syncPolicy | object | see the keys below | What the ApplicationSet controller may do to the Applications it generates. |
| applicationSet.syncPolicy.applicationsSync | string | `"sync"` | Argo CD `applicationsSync` policy: `sync` creates, updates and deletes Applications. |
| applicationSet.syncPolicy.preserveResourcesOnDeletion | bool | `true` | Keep an Application's resources in the cluster when the Application is deleted. |
| cluster | string | `nil` | Cluster to deploy: the name of its Argo CD cluster Secret, and its directory under `clusters/` in the repo platform. |
| names | object | see the keys below | Shortening of the names the chart generates. |
| names.maxLength | int | `53` | Maximum length of a generated Application name or Helm release name, at least 10. A longer name keeps its first `maxLength - 9` characters, then gets `-` and the first 8 hex characters of its sha256. 53 is Helm's limit on release names. |
| repo | object | see the keys below | Repositories holding the two roles of the layout. One repository may hold both. |
| repo.catalog | object | see the keys below | Repo catalogue: the repository and layout root providing `apps/`. |
| repo.catalog.path | string | `nil` | Layout root of the repo catalogue, relative to the root of its repository. Unset → the repository root. |
| repo.catalog.revision | string | `nil` | Revision of the repository holding the repo catalogue: branch, tag or commit. |
| repo.catalog.url | string | `nil` | URL of the repository holding the repo catalogue. |
| repo.platform | object | see the keys below | Repo platform: the repository and layout root providing `envs/` and `clusters/`. |
| repo.platform.path | string | `nil` | Layout root of the repo platform, relative to the root of its repository. Unset → the repository root. |
| repo.platform.revision | string | `nil` | Revision of the repository holding the repo platform: branch, tag or commit. |
| repo.platform.url | string | `nil` | URL of the repository holding the repo platform. |
