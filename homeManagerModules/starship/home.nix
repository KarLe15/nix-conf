

{inputs, pkgs, lib, config, customConfigs, ... } : 
let 
in
{
  stylix.targets.starship.enable = true;
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = lib.concatStrings [
          "[](fg:base16)"
          "$os"
          "$username"
          "[](fg:base16 bg:base08)"
          "$directory"
          "[](fg:base08 bg:base09)"
          "$git_branch"
          "[](fg:base09 bg:bright-yellow)"
          "$git_metrics"
          "$git_status"
          "$git_state"
          "[](fg:bright-yellow bg:base07)"
          "$c"
          "$golang"
          "$gradle"
          "$haskell"
          "$java"
          "$julia"
          "$nodejs"
          "$rust"
          "$scala"
          "$python"
          "[](fg:base07 bg:base16)"
          "$time"
          "[ ](fg:base16)"
          "$cmd_duration"
          "$line_break"
          "$status"
          "$character"
      ];
      palette = "base16";
      status = {
        disabled = false;
      };
      character = {
        success_symbol = "[ --> ](bold green)";
        error_symbol = "[ --> ](bold red)";
      };
      cmd_duration = {
        show_milliseconds = false;
        min_time = 1500;
        format = "[](fg:base08)[took $duration](bold fg:base04 bg:base08)[](fg:base08)";
      };
      username = {
        show_always = true;
        style_user = "bold fg:base04 bg:base16";
        style_root = "bold fg:base04 bg:base16";
        format = "[ $user ]($style)";
        disabled = false;
      };
      os = {
        style = "bg:base16";
        disabled = false;
      };
      directory = {
        style = "bold fg:base04 bg:base08";
        format = "[   $path ]($style)";
        truncate_to_repo = true;
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };
      };
      time = {
        disabled = false;
        time_format = "%R"; # Hour:Minute Format
        style = "bold fg:base04 bg:base16";
        format = "[ 🕙 $time ]($style)";
      };
      git_branch = {
        symbol = "";
        style = "bold fg:base04 bg:base09";
        format = "[ $symbol $branch ]($style)";
      };
      git_status = {
        style = "bold fg:base04 bg:bright-yellow";
        modified = " ✏️ ";
        deleted = " 🗑️ ";
        untracked = " 🐾\${count} ";
        conflicted = " ⚔️\${count} ";
        diverged = " 🔱 💨\${ahead_count} 🐢\${behind_count}";
        staged = "";
        up_to_date = "";
        format = "[$conflicted$untracked$modified$deleted$ahead_behind]($style)";
      };
      git_metrics = {
        added_style = "fg:base04 bg:bright-yellow bold green";
        deleted_style = "bg:bright-yellow bold red";
        format = "[ +$added]($added_style)[ -$deleted]($deleted_style)[ ](bg:bright-yellow)";
        disabled = true;
      };
      git_state = {
        style = "bold fg:base04 bg:bright-yellow";
        format = "[ $all_status$ahead_behind ]($style)";
      };
      golang = {
        symbol = " ";
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      gradle = {
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      haskell = {
        symbol = " ";
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      java = {
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      julia = {
        symbol = " ";
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      nodejs = {
        symbol = " ";
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      rust = {
        symbol = " ";
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      scala = {
        symbol = " ";
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      c = {
        symbol = " ";
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      python = {
        style = "bold fg:base04 bg:base07";
        format = "[ $symbol ($version) ]($style)";
      };
      docker_context = {
        symbol = " ";
        style = "bg:base15";
        format = "[ $symbol $context ]($style) $path";
      };
    };
  };
}
