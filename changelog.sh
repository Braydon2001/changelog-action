#!/bin/bash
set -e

# --- Get the diff from the last commit ---
DIFF=$(git diff HEAD~1 HEAD 2>/dev/null || git diff --cached 2>/dev/null || echo "")

if [ -z "$DIFF" ]; then
  echo "::warning::No diff found — skipping changelog generation"
  exit 0
fi

# --- Truncate if too large (50k char limit) ---
if [ ${#DIFF} -gt 50000 ]; then
  echo "::warning::Diff is large, truncating to 50,000 characters"
  DIFF="${DIFF:0:50000}"
fi

# --- Build JSON payload ---
PAYLOAD=$(jq -n \
  --arg diff "$DIFF" \
  --arg style "$INPUT_STYLE" \
  --arg context "$INPUT_CONTEXT" \
  '{diff: $diff, style: $style, context: $context}')

# --- Call the API ---
echo "Calling Changelog API..."
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "https://changelog-generator.p.rapidapi.com/changelog" \
  -H "Content-Type: application/json" \
  -H "x-rapidapi-host: changelog-generator.p.rapidapi.com" \
  -H "x-rapidapi-key: $INPUT_API_KEY" \
  -d "$PAYLOAD")

HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_STATUS" != "200" ]; then
  echo "::error::API call failed with status $HTTP_STATUS: $BODY"
  exit 1
fi

# --- Parse response ---
SUMMARY=$(echo "$BODY" | jq -r '.summary')
TYPE=$(echo "$BODY" | jq -r '.type')
BREAKING=$(echo "$BODY" | jq -r '.breaking')
BULLETS=$(echo "$BODY" | jq -c '.bullets')

# --- Set outputs ---
echo "summary=$SUMMARY" >> "$GITHUB_OUTPUT"
echo "type=$TYPE" >> "$GITHUB_OUTPUT"
echo "breaking=$BREAKING" >> "$GITHUB_OUTPUT"
echo "bullets=$BULLETS" >> "$GITHUB_OUTPUT"

# --- Print to logs ---
echo ""
echo "=== Changelog Entry ==="
echo "Summary:  $SUMMARY"
echo "Type:     $TYPE"
echo "Breaking: $BREAKING"
echo ""
echo "Changes:"
echo "$BODY" | jq -r '.bullets[]' | while read -r bullet; do
  echo "  • $bullet"
done
echo "======================="

# --- Optionally append to file ---
if [ -n "$INPUT_OUTPUT_FILE" ]; then
  DATE=$(date +%Y-%m-%d)
  ENTRY="## [$DATE] $SUMMARY\n"

  echo "$BODY" | jq -r '.bullets[]' | while read -r bullet; do
    ENTRY="${ENTRY}- ${bullet}\n"
  done

  if [ -f "$INPUT_OUTPUT_FILE" ]; then
    # Insert after first line (after the # Changelog header)
    TEMP=$(mktemp)
    head -n 1 "$INPUT_OUTPUT_FILE" > "$TEMP"
    echo -e "\n$ENTRY" >> "$TEMP"
    tail -n +2 "$INPUT_OUTPUT_FILE" >> "$TEMP"
    mv "$TEMP" "$INPUT_OUTPUT_FILE"
  else
    echo -e "# Changelog\n\n$ENTRY" > "$INPUT_OUTPUT_FILE"
  fi

  echo "Appended to $INPUT_OUTPUT_FILE"
fi
