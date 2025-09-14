| Роль  | Права роли | Группы пользователей |
| secret-reader | ["get", "list"] "secrets" | secure-operator |
| cluster-pod-reader | ["get", "list", "watch"] "pods" | developer |
| devops-role | ["create", "delete", "list] "pods" | devops-group |

