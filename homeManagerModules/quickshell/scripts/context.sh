#!/bin/sh
# System-module context probe for the Quickshell shell. Emits key=value lines
# (and one `llmmodel=` line per loaded ollama model). Precedence for the active
# context: gaming → llm → container → standard.

# GameMode: number of registered clients on the session bus (0 if unavailable).
gm=$(busctl --user get-property com.feralinteractive.GameMode \
    /com/feralinteractive/GameMode com.feralinteractive.GameMode ClientCount \
    2>/dev/null | awk '{print $2}')

# ollama: one record per loaded model — name|param|quant|family|vram(bytes).
# Split the (compact) /api/ps JSON so each model object is on its own line, then
# pull the fields per line (no jq on the host).
J=$(curl -s --max-time 1 http://127.0.0.1:11434/api/ps 2>/dev/null)
M=$(printf '%s' "$J" | sed 's/{"name":/\n&/g' | awk '
/"name":/ {
  name=""; param=""; quant=""; fam=""; vram=0;
  if (match($0, /"name":"[^"]*"/))               { s=substr($0,RSTART,RLENGTH); sub(/"name":"/,"",s); sub(/"$/,"",s); name=s }
  if (match($0, /"parameter_size":"[^"]*"/))      { s=substr($0,RSTART,RLENGTH); sub(/.*:"/,"",s); sub(/"$/,"",s); param=s }
  if (match($0, /"quantization_level":"[^"]*"/))  { s=substr($0,RSTART,RLENGTH); sub(/.*:"/,"",s); sub(/"$/,"",s); quant=s }
  if (match($0, /"family":"[^"]*"/))              { s=substr($0,RSTART,RLENGTH); sub(/.*:"/,"",s); sub(/"$/,"",s); fam=s }
  if (match($0, /"size_vram":[0-9]+/))            { s=substr($0,RSTART,RLENGTH); sub(/.*:/,"",s); vram=s }
  printf "llmmodel=%s|%s|%s|%s|%s\n", name, param, quant, fam, vram
}')

dk=$(docker ps -q 2>/dev/null | wc -l)

# Running containers: one `container=name|cpu|mem|uptime` record each. `docker
# stats` samples for ~1s, so only run it when something is actually running.
C=""
if [ "${dk:-0}" -gt 0 ] 2>/dev/null; then
  PS=$(docker ps --format '{{.Names}}|{{.Status}}' 2>/dev/null)
  C=$(docker stats --no-stream --format '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}' 2>/dev/null | awk -v ps="$PS" '
    BEGIN { n=split(ps, arr, "\n"); for (i=1;i<=n;i++) { split(arr[i], kv, "|"); up[kv[1]]=kv[2] } }
    {
      split($0, f, "|"); name=f[1]; cpu=f[2]; mem=f[3];
      sub(/ .*/, "", mem); sub(/iB$/, "B", mem);          # "180MiB / 31GiB" → "180MB"
      u=up[name]; sub(/^Up +/, "", u); sub(/ *\(.*\)/, "", u);
      sub(/ *hours?/, "h", u); sub(/ *minutes?/, "m", u);
      sub(/ *days?/, "d", u); sub(/ *weeks?/, "w", u); sub(/ *seconds?/, "s", u);
      gsub(/ /, "", u);
      printf "container=%s|%s|%s|%s\n", name, cpu, mem, u
    }')
fi

sr=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | wc -l)
sf=$(systemctl --failed --no-legend 2>/dev/null | wc -l)

if [ "${gm:-0}" -gt 0 ] 2>/dev/null; then ctx=gaming
elif [ -n "$M" ];              then ctx=llm
elif [ "${dk:-0}" -gt 0 ] 2>/dev/null; then ctx=container
else ctx=standard; fi

echo "context=$ctx"
echo "sysrunning=$sr"
echo "sysfailed=$sf"
echo "containers=$dk"
[ -n "$M" ] && printf '%s\n' "$M"
[ -n "$C" ] && printf '%s\n' "$C"
