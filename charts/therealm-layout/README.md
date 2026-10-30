# therealm-layout

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

ApplicationSet deploying one cluster's instances from the catalogue and platform repositories.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| application.annotations | object | `{}` | Annotations of each Application. Values are ApplicationSet Go templates, with the same parameters as `application.name`. |
| application.defaultProject | string | `nil` | Project of an Application whose `app.yaml` sets none. Unset → every app must set `app.project`. |
| application.finalizers | list | `[]` | Finalizers of each Application, e.g. `resources-finalizer.argocd.argoproj.io` to delete its resources along with it. |
| application.helm.ignoreMissingValueFiles | bool | `true` | Skip the layout's `values.yaml` files that do not exist. Disabled, every level must provide one. |
| application.helm.releaseName | string | `nil` | Helm release name of a chart app, as an ApplicationSet Go template with the same parameters as `application.name`. Unset → `<app>`, shortened to `names.maxLength`. Set → used as is: keeping it short enough is then up to you. |
| application.labels | object | `{}` | Labels of each Application. Values are ApplicationSet Go templates, with the same parameters as `application.name`. |
| application.manifestGeneratePaths | bool | `true` | Set `argocd.argoproj.io/manifest-generate-paths` to the layout directories of each instance, so a commit elsewhere does not regenerate its manifests. Needs a git webhook. |
| application.manifests.include | string | `"manifests/*.yaml"` | Glob of the raw manifests applied from an instance directory, relative to it. |
| application.manifests.recurse | bool | `true` | Search sub-directories of the instance directory; needed for an `include` below a sub-directory. |
| application.name | string | `nil` | Name of each Application, as an ApplicationSet Go template reading `.values.cluster`, `.values.env`, `.values.app` and `.values.instance`. Unset → `<cluster>-<env>-<app>-<instance>`, shortened to `names.maxLength`. Set → used as is: keeping it short enough is then up to you. |
| application.revisionHistoryLimit | int | `0` | Number of sync results each Application keeps in its history. |
| application.syncPolicy.automated | object | `{}` | Automated sync of each Application, as in an Application's `syncPolicy.automated`. Empty → manual sync. |
| application.syncPolicy.retry | object | `{"backoff":{"duration":"15s","factor":2,"maxDuration":"5m"},"limit":10}` | Retry policy of a failed sync. `null` → no retry. |
| application.syncPolicy.retry.backoff.duration | string | `"15s"` | Delay before the first retry. |
| application.syncPolicy.retry.backoff.factor | int | `2` | Factor applied to the delay after each retry. |
| application.syncPolicy.retry.backoff.maxDuration | string | `"5m"` | Maximum delay between two retries. |
| application.syncPolicy.retry.limit | int | `10` | Maximum number of retries. |
| application.syncPolicy.syncOptions | list | `[]` | Sync options added to the ones each `app.yaml` declares. |
| applicationSet.annotations | object | `{}` | Annotations of the ApplicationSet. |
| applicationSet.goTemplateOptions | list | `["missingkey=error"]` | Go template options of the ApplicationSet. Without `missingkey=error`, a missing field renders empty instead of failing. |
| applicationSet.labels | object | `{}` | Labels of the ApplicationSet. |
| applicationSet.name | tpl/string | `nil` | Name of the ApplicationSet, rendered with Helm's `tpl`. Unset → `root-<cluster>`. |
| applicationSet.requeueAfterSeconds | int | `nil` | Polling interval of every git generator, in seconds. Unset → Argo CD's default. |
| applicationSet.syncPolicy | object | `{"applicationsSync":"sync","preserveResourcesOnDeletion":true}` | What the ApplicationSet controller may do to the Applications it generates. |
| applicationSet.syncPolicy.applicationsSync | string | `"sync"` | Argo CD `applicationsSync` policy: `sync` creates, updates and deletes Applications. |
| applicationSet.syncPolicy.preserveResourcesOnDeletion | bool | `true` | Keep an Application's resources in the cluster when the Application is deleted. |
| cluster | string | `nil` | Cluster to deploy: the name of its Argo CD cluster Secret, and its directory under `clusters/` in the platform repository. |
| names.maxLength | int | `53` | Maximum length of a generated Application name or Helm release name, at least 10. A longer name keeps its first `maxLength - 9` characters, then gets `-` and the first 8 hex characters of its sha256. 53 is Helm's limit on release names. |
| repo.catalog.path | string | `""` | Directory of the catalogue repository the layout starts from. Empty means the repository root. |
| repo.catalog.revision | string | `nil` | Revision of the catalogue repository: branch, tag or commit. |
| repo.catalog.url | string | `nil` | URL of the catalogue repository, holding `apps/`. |
| repo.platform.path | string | `""` | Directory of the platform repository the layout starts from. Empty means the repository root. |
| repo.platform.revision | string | `nil` | Revision of the platform repository: branch, tag or commit. |
| repo.platform.url | string | `nil` | URL of the platform repository, holding `envs/` and `clusters/`. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
