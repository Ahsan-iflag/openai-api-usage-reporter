---
name: git-commit
description: サーバーレス Python/AWS プロジェクト向けのコミット前チェックを行う
---

# git-commit

## Goal

コミット前に、今回のプロジェクトに合う最小限の品質チェックを実行する。

## Checks

存在するものだけ実行する。

```bash
python -m pytest
python -m compileall .
sam validate
```

`pyproject.toml` があり ruff が設定されている場合:

```bash
python -m ruff format .
python -m ruff check .
```

## Guardrails

- secret を git に含めない
- `.env` や credential file を stage しない
- 生成物や cache を含めない
