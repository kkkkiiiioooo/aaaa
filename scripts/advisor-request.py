#!/usr/bin/env python3
"""Send a prompt file to a Coarena model and save the answer as Markdown.

Environment:
  COARENA_API_KEY            required
  COARENA_OPENAI_BASE_URL    optional, default https://coarena.ai/api/v1
  COARENA_BASE_URL           optional fallback
  --env-file                 loads vars from file if not set (default: prompts/.advisor.env)

Usage:
  scripts/advisor-request.py
  scripts/advisor-request.py --list-models
  scripts/advisor-request.py --prompt prompts/advisor.md --output prompts/advisor-resposta.md
  scripts/advisor-request.py gpt-6-sol
  scripts/advisor-request.py --attach-dir prompts/advisor-anexos --history-dir prompts/advisor-historico
"""
from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

DEFAULT_MODEL = "gpt-6-astra"
DEFAULT_PROMPT = "prompts/advisor.md"
DEFAULT_OUTPUT_DIR = "prompts/advisor-respostas"
DEFAULT_BACKUP_DIR = "prompts/advisor-backup"
DEFAULT_LATEST_LINK = "prompts/advisor-resposta.md"
DEFAULT_HISTORY_DIR = "prompts/advisor-historico"
DEFAULT_ATTACH_DIR = "prompts/advisor-anexos"
DEFAULT_BASE = "https://coarena.ai/api/v1"
RETRYABLE = {408, 409, 425, 429, 500, 502, 503, 504}
MAX_FILE_CHARS = 120_000


def fail(message: str, code: int = 1) -> None:
    print(f"advisor-request: {message}", file=sys.stderr)
    raise SystemExit(code)


def api_base() -> str:
    raw = os.environ.get("COARENA_OPENAI_BASE_URL") or os.environ.get("COARENA_BASE_URL") or DEFAULT_BASE
    base = raw.rstrip("/")
    if base.endswith("/v1"):
        return base
    if base.endswith("/api"):
        return base + "/v1"
    return base


def api_key() -> str:
    key = os.environ.get("COARENA_API_KEY")
    if not key:
        fail("set COARENA_API_KEY")
    return key


def request_json(url: str, key: str, payload: dict | None, timeout: int) -> dict:
    headers = {
        "Authorization": "Bearer " + key,
        "Accept": "application/json",
        "User-Agent": "advisor-request/1.0",
    }
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as response:
        body = response.read().decode("utf-8")
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        fail(f"response is not JSON: {body[:500]}")
    if not isinstance(parsed, dict):
        fail(f"unexpected response shape: {body[:500]}")
    return parsed


def load_env_file(path: str) -> None:
    p = pathlib.Path(path)
    if not p.is_file():
        return
    for line in p.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        k, v = s.split("=", 1)
        k = k.strip()
        v = v.strip().strip("'").strip('"')
        if k and os.environ.get(k) in (None, ""):
            os.environ[k] = v


def with_retries(fn, retries: int):
    last: Exception | None = None
    for attempt in range(1, retries + 1):
        try:
            return fn()
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", "replace")[:1000]
            last = exc
            if exc.code not in RETRYABLE or attempt == retries:
                fail(f"HTTP {exc.code} from Coarena: {detail}")
        except urllib.error.URLError as exc:
            last = exc
            if attempt == retries:
                fail(f"network error: {exc.reason}")
        except TimeoutError:
            last = None
            if attempt == retries:
                fail("request timed out")
        delay = min(60, 5 * attempt)
        print(f"advisor-request: transient failure ({last}); retry {attempt}/{retries} in {delay}s", file=sys.stderr)
        time.sleep(delay)
    fail("request failed after retries")


def list_models(base: str, key: str, timeout: int) -> None:
    after: str | None = None
    seen: set[str] = set()
    rows: list[dict] = []
    for _ in range(20):
        query = urllib.parse.urlencode({"after": after}) if after else ""
        url = base + "/models" + ("?" + query if query else "")
        payload = with_retries(lambda: request_json(url, key, None, timeout), 3)
        data = payload.get("data")
        if not isinstance(data, list):
            fail("models response has no data array")
        rows.extend(item for item in data if isinstance(item, dict))
        if not payload.get("has_more"):
            break
        cursor = payload.get("last_id")
        if not isinstance(cursor, str) or not cursor or cursor in seen:
            fail("models pagination did not provide a new cursor")
        seen.add(cursor)
        after = cursor
    else:
        fail("models pagination exceeded 20 pages")
    for item in sorted(rows, key=lambda row: str(row.get("id", ""))):
        model_id = item.get("id")
        if not isinstance(model_id, str):
            continue
        name = item.get("display_name") or model_id
        print(f"{model_id}\t{name}")


def content_from_message(message: dict) -> str:
    content = message.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict):
                text = item.get("text")
                if isinstance(text, str):
                    parts.append(text)
        return "".join(parts)
    return ""


def read_text_file(path: pathlib.Path) -> str:
    data = path.read_bytes()
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return data.decode("utf-8", errors="replace")


def truncate_note(text: str, path: pathlib.Path, limit: int = MAX_FILE_CHARS) -> str:
    if len(text) <= limit:
        return text
    head = text[:limit]
    return head + f"\n\n[... truncado: {len(text)} chars, limite {limit}, arquivo {path} ...]"


def collect_attachments(attach_dir: pathlib.Path) -> tuple[list[pathlib.Path], str]:
    if not attach_dir.is_dir():
        return [], ""
    files = sorted(p for p in attach_dir.iterdir() if p.is_file() and not p.name.startswith("."))
    if not files:
        return [], ""
    blocks = ["", "## ANEXOS DA PASTA (enviados automaticamente)", ""]
    for p in files:
        text = truncate_note(read_text_file(p), p)
        blocks.append(f"### Arquivo: {p.as_posix()}")
        blocks.append("")
        blocks.append("```text")
        blocks.append(text.rstrip("\n"))
        blocks.append("```")
        blocks.append("")
    return files, "\n".join(blocks).rstrip() + "\n"


def _extract_section(md: str, heading: str, next_headings: list[str]) -> str:
    # find heading line "## heading" and capture until next of next_headings or EOF
    pattern = r"^## " + re.escape(heading) + r"\s*$"
    m = re.search(pattern, md, flags=re.MULTILINE)
    if not m:
        return ""
    start = m.end()
    end = len(md)
    for h in next_headings:
        m2 = re.search(r"^## " + re.escape(h) + r"\s*$", md[start:], flags=re.MULTILINE)
        if m2:
            end = min(end, start + m2.start())
    return md[start:end].strip()


def collect_history(history_dir: pathlib.Path, limit: int) -> list[dict]:
    """Return prior messages (user/assistant) from transcript files in history_dir."""
    if limit <= 0 or not history_dir.is_dir():
        return []
    transcripts = sorted(history_dir.glob("advisor-transcript-*.md"))
    if not transcripts:
        return []
    transcripts = transcripts[-limit:]
    messages: list[dict] = []
    for p in transcripts:
        md = read_text_file(p)
        user = _extract_section(md, "INPUT (usuário)", ["OUTPUT (assistente)"])
        assistant = _extract_section(md, "OUTPUT (assistente)", [])
        if not user or not assistant:
            # fallback: try legacy response style - skip as pair
            continue
        user = truncate_note(user, p)
        assistant = truncate_note(assistant, p)
        messages.append({"role": "user", "content": f"[Histórico: {p.name}]\n\n{user}"})
        messages.append({"role": "assistant", "content": assistant})
    return messages


def build_messages(prompt: str, attachments_block: str, history_messages: list[dict]) -> tuple[list[dict], str]:
    user_text = prompt.rstrip() + ("\n\n" + attachments_block if attachments_block else "\n")
    messages = list(history_messages)
    messages.append({"role": "user", "content": user_text})
    return messages, user_text


def chat(base: str, key: str, model: str, messages: list[dict], effort: str, max_tokens: int, timeout: int, retries: int) -> tuple[str, dict]:
    body = {
        "model": model,
        "messages": messages,
        "max_completion_tokens": max_tokens,
        "reasoning_effort": effort,
        "stream": False,
    }

    def send(payload: dict) -> dict:
        return request_json(base + "/chat/completions", key, payload, timeout)

    response = with_retries(lambda: send(body), retries)
    if "choices" not in response:
        fail(f"response has no choices: {json.dumps(response, ensure_ascii=False)[:1000]}")
    choices = response.get("choices")
    if not isinstance(choices, list) or not choices or not isinstance(choices[0], dict):
        fail("empty choices in response")
    message = choices[0].get("message")
    if not isinstance(message, dict):
        fail("response choice has no message")
    text = content_from_message(message).strip()
    if not text:
        text = str(message.get("refusal") or "").strip()
    if not text:
        fail("model returned empty content")
    usage = response.get("usage") if isinstance(response.get("usage"), dict) else {}
    return text, usage


def atomic_write(path: pathlib.Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    temp = pathlib.Path(temp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(text)
            if not text.endswith("\n"):
                stream.write("\n")
        os.replace(temp, path)
    finally:
        try:
            temp.unlink()
        except FileNotFoundError:
            pass


def main() -> None:
    parser = argparse.ArgumentParser(description="Ask a Coarena model and save the answer as Markdown.")
    parser.add_argument("--prompt", default=DEFAULT_PROMPT, help=f"prompt file (default: {DEFAULT_PROMPT})")
    parser.add_argument("--output", default=None, help=f"Markdown output file (default: {DEFAULT_OUTPUT_DIR}/advisor-resposta-<timestamp>.md)")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Coarena model ID (default: {DEFAULT_MODEL})")
    parser.add_argument("model_pos", nargs="?", default=None, help="Coarena model ID (shortcut for --model, e.g. gpt-6-sol)")
    parser.add_argument("--effort", default="low", choices=["low", "medium", "high", "xhigh"], help="reasoning effort (default: low)")
    parser.add_argument("--max-tokens", type=int, default=16000, help="max completion tokens (default: 16000)")
    parser.add_argument("--timeout", type=int, default=1800, help="request timeout in seconds (default: 1800)")
    parser.add_argument("--retries", type=int, default=3, help="retry attempts for transient errors (default: 3)")
    parser.add_argument("--env-file", default="prompts/.advisor.env", help="load env vars from file if not set (default: prompts/.advisor.env)")
    parser.add_argument("--history-dir", default=DEFAULT_HISTORY_DIR, help=f"directory with advisor-transcript-*.md history (default: {DEFAULT_HISTORY_DIR})")
    parser.add_argument("--history-limit", type=int, default=4, help="number of prior transcript pairs to include (default: 4, 0 disables)")
    parser.add_argument("--no-history", action="store_true", help="do not include prior history")
    parser.add_argument("--attach-dir", default=DEFAULT_ATTACH_DIR, help=f"directory whose files are attached to the prompt (default: {DEFAULT_ATTACH_DIR})")
    parser.add_argument("--list-models", action="store_true", help="list Coarena models and exit")
    parser.add_argument("--dry-run", action="store_true", help="validate inputs and print the request summary without sending")
    args = parser.parse_args()
    if args.model_pos:
        args.model = args.model_pos

    load_env_file(args.env_file)
    base = api_base()
    if args.list_models:
        key = api_key()
        list_models(base, key, min(args.timeout, 120))
        return
    key = "" if args.dry_run else api_key()

    prompt_path = pathlib.Path(args.prompt)
    if not prompt_path.is_file():
        fail(f"prompt file not found: {prompt_path}")
    prompt = prompt_path.read_text(encoding="utf-8")
    if not prompt.strip():
        fail(f"prompt file is empty: {prompt_path}")

    started = datetime.now(timezone.utc)
    stamp = started.strftime("%Y%m%d-%H%M%S")
    if args.output:
        output_path = pathlib.Path(args.output)
    else:
        output_path = pathlib.Path(DEFAULT_OUTPUT_DIR) / f"advisor-resposta-{stamp}.md"

    attach_dir = pathlib.Path(args.attach_dir)
    history_dir = pathlib.Path(args.history_dir)
    attached_files, attachments_block = collect_attachments(attach_dir)
    history_limit = 0 if args.no_history else max(0, args.history_limit)
    history_messages = collect_history(history_dir, history_limit)
    messages, user_text = build_messages(prompt, attachments_block, history_messages)

    if output_path.exists():
        backup_dir = pathlib.Path(DEFAULT_BACKUP_DIR)
        backup_dir.mkdir(parents=True, exist_ok=True)
        backup_path = backup_dir / f"{output_path.stem}-{stamp}{output_path.suffix}"
        try:
            output_path.replace(backup_path)
            print(f"advisor-request: backed up existing output to {backup_path}", file=sys.stderr)
        except Exception:
            pass

    if args.dry_run:
        print(f"model={args.model} effort={args.effort} max_tokens={args.max_tokens}")
        print(f"prompt={prompt_path} bytes={prompt_path.stat().st_size} chars={len(prompt)}")
        print(f"attachments_dir={attach_dir} files={len(attached_files)}")
        for p in attached_files:
            print(f"  attach={p}")
        print(f"history_dir={history_dir} pairs={len(history_messages)//2} limit={history_limit}")
        print(f"messages={len(messages)} user_chars={len(user_text)}")
        print(f"output={output_path}")
        print(f"endpoint={base}/chat/completions")
        return

    print(f"advisor-request: sending {prompt_path} ({prompt_path.stat().st_size} bytes) to {args.model}, attachments={len(attached_files)}, history_pairs={len(history_messages)//2}", file=sys.stderr)
    answer, usage = chat(base, key, args.model, messages, args.effort, args.max_tokens, args.timeout, args.retries)
    finished = datetime.now(timezone.utc)

    prompt_tokens = usage.get("prompt_tokens")
    completion_tokens = usage.get("completion_tokens")
    total_tokens = usage.get("total_tokens")
    header = [
        "# Resposta do advisor",
        "",
        f"- Modelo: `{args.model}`",
        f"- Esforço de raciocínio: `{args.effort}`",
        f"- Prompt: `{prompt_path}`",
        f"- Arquivo: `{output_path}`",
        f"- Histórico incluído: {len(history_messages)//2} par(es) de `{history_dir}`",
        f"- Anexos incluídos: {len(attached_files)} arquivo(s) de `{attach_dir}`",
        f"- Gerado em: {started.strftime('%Y-%m-%d %H:%M:%S UTC')}",
        f"- Concluído em: {finished.strftime('%Y-%m-%d %H:%M:%S UTC')}",
    ]
    if prompt_tokens is not None or completion_tokens is not None:
        header.append(f"- Tokens: prompt={prompt_tokens} completion={completion_tokens} total={total_tokens}")
    header.extend(["", "---", ""])
    atomic_write(output_path, "\n".join(header) + answer + "\n")

    # Save transcript (input + output history) for future runs
    history_dir.mkdir(parents=True, exist_ok=True)
    transcript_path = history_dir / f"advisor-transcript-{stamp}.md"
    t_header = [
        "# Transcrição advisor (entrada/saída)",
        "",
        f"- Modelo: `{args.model}`",
        f"- Esforço de raciocínio: `{args.effort}`",
        f"- Prompt base: `{prompt_path}`",
        f"- Resposta salva: `{output_path}`",
        f"- Histórico prévio incluído: {len(history_messages)//2} par(es)",
        f"- Anexos incluídos: {len(attached_files)} arquivo(s)",
    ]
    if attached_files:
        t_header.append("- Arquivos anexados: " + ", ".join(f"`{p}`" for p in attached_files))
    t_header.extend([
        f"- Gerado em: {started.strftime('%Y-%m-%d %H:%M:%S UTC')}",
        f"- Concluído em: {finished.strftime('%Y-%m-%d %H:%M:%S UTC')}",
    ])
    if prompt_tokens is not None or completion_tokens is not None:
        t_header.append(f"- Tokens: prompt={prompt_tokens} completion={completion_tokens} total={total_tokens}")
    t_header.extend(["", "---", "", "## INPUT (usuário)", "", user_text, "", "---", "", "## OUTPUT (assistente)", "", answer, ""])
    atomic_write(transcript_path, "\n".join(t_header))
    print(f"advisor-request: saved transcript {transcript_path}", file=sys.stderr)

    link_path = pathlib.Path(DEFAULT_LATEST_LINK)
    try:
        if link_path.is_symlink() or link_path.exists():
            link_path.unlink()
        link_path.parent.mkdir(parents=True, exist_ok=True)
        rel = os.path.relpath(output_path, link_path.parent)
        link_path.symlink_to(rel)
        print(f"advisor-request: updated link {link_path} -> {rel}", file=sys.stderr)
    except Exception as exc:
        print(f"advisor-request: could not update link {link_path}: {exc}", file=sys.stderr)
    print(f"advisor-request: saved {output_path} ({len(answer)} chars)", file=sys.stderr)
    if total_tokens is not None:
        print(f"advisor-request: tokens prompt={prompt_tokens} completion={completion_tokens} total={total_tokens}", file=sys.stderr)


if __name__ == "__main__":
    main()
