# Changelog Generator Action

Automatically generate a changelog entry from your git diff using AI. Powered by the [Changelog API](https://rapidapi.com/braydon635/api/changelog-generator).

## Quick start

```yaml
name: Generate Changelog
on: [push]

jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2  # needed to diff against previous commit

      - uses: gurtman21/changelog-action@v1
        with:
          api-key: ${{ secrets.CHANGELOG_API_KEY }}
```

Add your API key as a repository secret: **Settings → Secrets → New repository secret** → name it `CHANGELOG_API_KEY`.



Get an API key at [RapidAPI](https://rapidapi.com/braydon635/api/changelog-generator).
Your `CHANGELOG_API_KEY` secret should be your RapidAPI subscriber key.

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `api-key` | Yes | — | Your RapidAPI subscriber key |
| `style` | No | `conventional` | Output style: `conventional`, `keepachangelog`, or `plain` |
| `context` | No | — | Optional hint (e.g. your PR title) |
| `output-file` | No | — | Append entry to this file (e.g. `CHANGELOG.md`) |

## Outputs

| Output | Description |
|---|---|
| `summary` | One-line changelog summary |
| `type` | Conventional commit type (`feat`, `fix`, `chore`, etc.) |
| `breaking` | Whether this is a breaking change (`true`/`false`) |
| `bullets` | Bullet points as a JSON array |

## Examples

### Auto-update CHANGELOG.md

```yaml
- uses: gurtman21/changelog-action@v1
  with:
    api-key: ${{ secrets.CHANGELOG_API_KEY }}
    output-file: CHANGELOG.md

- uses: stefanzweifel/git-auto-commit-action@v5
  with:
    commit_message: "docs: update changelog"
    file_pattern: CHANGELOG.md
```

### Use the PR title as context

```yaml
- uses: gurtman21/changelog-action@v1
  with:
    api-key: ${{ secrets.CHANGELOG_API_KEY }}
    context: ${{ github.event.pull_request.title }}
    style: keepachangelog
```

### Use outputs in later steps

```yaml
- uses: gurtman21/changelog-action@v1
  id: changelog
  with:
    api-key: ${{ secrets.CHANGELOG_API_KEY }}

- name: Print summary
  run: echo "Released: ${{ steps.changelog.outputs.summary }}"
```

## Pricing

Get your API key at [RapidAPI](https://rapidapi.com/Braydon2001/api/changelog-generator).

| Plan | Price | Calls/month |
|---|---|---|
| Free | $0 | 50 |
| Basic | $9/mo | 1,000 |
| Pro | $29/mo | 5,000 |

## License

MIT
