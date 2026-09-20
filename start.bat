@echo off
rem ================================================================
rem  Ternary-Bonsai-2-27B PTQ1_0 (5.9G, Prism ML, 1.75bpw ternary)
rem  on PrismML-Eng b10685 engine (has ternary kernels) - 2026-09-19 v2
rem  FULL GPU (5.9G all in VRAM) + 262K-capable hybrid backbone.
rem  ===== 2026-09-19 A/B measured update (full data: D:\agent1super\ report + tmp\bonsai\logs) =====
rem  CONTEXT 32K -> 64K with q4_0 KV: KV at 64K = 1088 MiB = SAME VRAM
rem    as the old q8_0 at 32K (both peak ~7.59 GB). TG stays 27.9 t/s
rem    (was 28.3) => double the context at zero measured cost.
rem  KV4 quality patch (official flow): -ctk/-ctv q4_0 +
rem    --kv-mean-center <bias> + env LLAMA_ATTN_ROT_DISABLE=1.
rem    The env MUST match the bias calibration (mismatch = load error).
rem  HARD CEILING (measured short-prompt TG vs ctx, q4_0):
rem    64K=27.4  80K=22.5  96K=9.9 (COLLAPSE)  128K=6.1
rem    q8_0 at 64K = 6.2 (KV 2176 MiB -> over budget -> WDDM silent spill)
rem    => never raise -c beyond 80K and keep KV at q4_0 on this 8G card.
rem    Note: the fork's --fit does NOT prevent the spill (it logs
rem    "cannot meet free memory target" and then loads anyway).
rem  PP +58% OPTION (commented, quality tradeoff): uncomment the SET
rem    line below -> PP512 287 -> 454 t/s, TG unchanged; our 9-question
rem    suite showed no visible change, vendor reports a small top-1
rem    delta (97.78 vs 98.39). Flip it only if PP matters more.
rem  STABILITY: the old "PP 20-101 dual-mode" did NOT reproduce in
rem    17/18 clean runs (PP 287 / TG 28.5 rock steady). Root cause was
rem    Ollama qwen3-vl:4b auto-loading mid-test and eating 5.7 GB VRAM.
rem    => start with a clean desktop; if slow, check `ollama ps`.
rem  THREAD-CRITICAL: 24 threads = PP 17 / TG 3.8 (disaster!)
rem    8 = 205/24.6   12 = 300/28.3   16 = 300/28.2  <- keep 12-16
rem  MTP = dead end here (o7 retest 09-19: --spec-draft-p-min 0.75 fixed
rem    acceptance to 0.87-0.89, yet net TG still -14~-21% because the
rem    verify batch doubles CPU expert traffic under mixed offload).
rem  Thinking is ON by default: small client max_tokens gets eaten by
rem    thinking -> give clients max_tokens >= 2000, or add
rem    --chat-template-kwargs "{\"enable_thinking\": false}".
rem  ================================================================
cd /d D:\llm\bin\llama-prism-b10709\bin
set LLAMA_ATTN_ROT_DISABLE=1
rem set GGML_CUDA_PTQ1_0_MMQ_MAX_BATCH=64
llama-server.exe ^
  -m "D:\lmstudio-models\Ternary-Bonsai-2-27B-PTQ1_0.gguf" ^
  -ngl 99 -c 65536 -np 1 -fa on ^
  -ctk q4_0 -ctv q4_0 ^
  --kv-mean-center "D:\lmstudio-models\Ternary-Bonsai-2-27B-PTQ1_0-kv-bias.gguf" ^
  -b 4096 -ub 1024 ^
  --threads 12 ^
  --cache-prompt --no-mmap --mlock ^
  --jinja --reasoning-format deepseek ^
  --host 127.0.0.1 --port 24557
pause
