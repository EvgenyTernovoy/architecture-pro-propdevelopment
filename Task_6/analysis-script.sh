#!/bin/bash

LOG_FILE="audit.log"
OUTPUT_FILE="audit-extract.json"

jq -s '[
  .[]
  | select(
      (.objectRef.resource=="secrets" and .verb=="get")
      or
      (.verb=="create" and .objectRef.subresource=="exec")
      or
      (.objectRef.resource=="pods" 
        and (.requestObject.spec.containers[]?.securityContext?.privileged // false))
      or
      (.requestURI? | test("audit-policy"))
    )
]' "$LOG_FILE" > "$OUTPUT_FILE"

echo "Подозрительные события сохранены в $OUTPUT_FILE"
