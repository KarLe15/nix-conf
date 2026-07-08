final: prev: {
  claude-code = prev.claude-code.overrideAttrs (old: rec {
    version = "2.1.91";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-u7jdM6hTYN05ZLPz630Yj7gI0PeCSArg4O6ItQRAMy4=";
    };
    npmDeps = prev.fetchNpmDeps {
      inherit src;
      postPatch = ''
        cp ${./package-lock.json} package-lock.json
      '';
      hash = "sha256-0ppKP+XMgTzVVZtL7GDsOjgvSPUDrUa7SoG048RLaNg=";
    };
    postPatch = ''
      cp ${./package-lock.json} package-lock.json
      # https://github.com/anthropics/claude-code/issues/15195
      substituteInPlace cli.js \
        --replace-fail '#!/bin/sh' '#!/usr/bin/env sh'
    '';
  });
}
