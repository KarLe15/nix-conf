Response from Claude
```nix
# configuration.nix or in a separate module

{ config, pkgs, ... }:

{
  # Install required packages
  environment.systemPackages = with pkgs; [
    git
    openssh
    # Optional: GUI git tools
    gitg
    gitui
  ];

  # Enable SSH agent service
  programs.ssh.startAgent = true;

  # User configuration (replace 'yourusername' with your actual username)
  users.users.yourusername = {
    # ... your other user config
    
    # SSH configuration
    openssh.authorizedKeys.keys = [
      # Add your public keys here if needed
    ];
  };

  # Home Manager configuration for Git multi-account setup
  home-manager.users.yourusername = { config, pkgs, ... }: {
    
    # SSH configuration
    programs.ssh = {
      enable = true;
      extraConfig = ''
        # Personal GitHub account
        Host github-personal
            HostName github.com
            User git
            IdentityFile ~/.ssh/id_rsa_personal
            IdentitiesOnly yes
            AddKeysToAgent yes

        # Work GitHub account  
        Host github-work
            HostName github.com
            User git
            IdentityFile ~/.ssh/id_rsa_work
            IdentitiesOnly yes
            AddKeysToAgent yes

        # Personal GitLab account
        Host gitlab-personal
            HostName gitlab.com
            User git
            IdentityFile ~/.ssh/id_rsa_personal
            IdentitiesOnly yes
            AddKeysToAgent yes

        # Work GitLab account
        Host gitlab-work
            HostName gitlab.com
            User git
            IdentityFile ~/.ssh/id_rsa_work
            IdentitiesOnly yes
            AddKeysToAgent yes

        # Bitbucket configurations (if needed)
        Host bitbucket-personal
            HostName bitbucket.org
            User git
            IdentityFile ~/.ssh/id_rsa_personal
            IdentitiesOnly yes
            AddKeysToAgent yes

        Host bitbucket-work
            HostName bitbucket.org
            User git
            IdentityFile ~/.ssh/id_rsa_work
            IdentitiesOnly yes
            AddKeysToAgent yes
      '';
    };

    # Git configuration
    programs.git = {
      enable = true;
      # Don't set global user info since we want per-repo configuration
      extraConfig = {
        init = {
          defaultBranch = "main";
          templateDir = "~/.git-template";
        };
        core = {
          editor = "nano"; # or your preferred editor
          autocrlf = false;
        };
        pull = {
          rebase = true;
        };
        push = {
          default = "simple";
          autoSetupRemote = true;
        };
        # Security
        transfer.fsckobjects = true;
        fetch.fsckobjects = true;
        receive.fsckObjects = true;
      };
    };

    # Create custom scripts for Git account management
    home.file.".local/bin/git-setup-personal" = {
      text = ''
        #!/bin/bash
        git config user.name "Your Personal Name"
        git config user.email "personal@example.com"
        echo "✓ Configured repository for personal account"
        echo "Name: $(git config user.name)"
        echo "Email: $(git config user.email)"
      '';
      executable = true;
    };

    home.file.".local/bin/git-setup-work" = {
      text = ''
        #!/bin/bash
        git config user.name "Your Work Name"
        git config user.email "work@company.com"
        echo "✓ Configured repository for work account"
        echo "Name: $(git config user.name)"
        echo "Email: $(git config user.email)"
      '';
      executable = true;
    };

    home.file.".local/bin/git-auto-config" = {
      text = ''
        #!/bin/bash
        
        # Check if we're in a git repository
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            echo "❌ Not in a git repository"
            exit 1
        fi

        remote_url=$(git remote get-url origin 2>/dev/null)

        if [[ $remote_url == *"github-personal"* ]] || [[ $remote_url == *"gitlab-personal"* ]] || [[ $remote_url == *"bitbucket-personal"* ]]; then
            git-setup-personal
        elif [[ $remote_url == *"github-work"* ]] || [[ $remote_url == *"gitlab-work"* ]] || [[ $remote_url == *"bitbucket-work"* ]]; then
            git-setup-work
        else
            echo "❓ Could not determine account type from remote URL: $remote_url"
            echo "Available commands:"
            echo "  git-setup-personal - Configure for personal account"
            echo "  git-setup-work     - Configure for work account"
        fi
      '';
      executable = true;
    };

    home.file.".local/bin/git-switch-account" = {
      text = ''
        #!/bin/bash
        
        REPO_DIR=$(pwd)
        PERSONAL_GIT="''${REPO_DIR}/.git-personal"
        WORK_GIT="''${REPO_DIR}/.git-work"
        CURRENT_GIT="''${REPO_DIR}/.git"

        if ! [ -d "$CURRENT_GIT" ]; then
            echo "❌ Not in a git repository"
            exit 1
        fi

        case "$1" in
            "personal")
                if [ -d "$WORK_GIT" ]; then
                    echo "❌ Work .git backup already exists. Clean up first."
                    exit 1
                fi
                mv "$CURRENT_GIT" "$WORK_GIT"
                if [ -d "$PERSONAL_GIT" ]; then
                    mv "$PERSONAL_GIT" "$CURRENT_GIT"
                    git-auto-config
                    echo "✓ Switched to personal account"
                else
                    echo "❌ Personal .git directory not found"
                    mv "$WORK_GIT" "$CURRENT_GIT"  # Restore
                    exit 1
                fi
                ;;
            "work")
                if [ -d "$PERSONAL_GIT" ]; then
                    echo "❌ Personal .git backup already exists. Clean up first."
                    exit 1
                fi
                mv "$CURRENT_GIT" "$PERSONAL_GIT"
                if [ -d "$WORK_GIT" ]; then
                    mv "$WORK_GIT" "$CURRENT_GIT"
                    git-auto-config
                    echo "✓ Switched to work account"
                else
                    echo "❌ Work .git directory not found"
                    mv "$PERSONAL_GIT" "$CURRENT_GIT"  # Restore
                    exit 1
                fi
                ;;
            "status")
                echo "Current repository status:"
                if [ -d "$PERSONAL_GIT" ]; then
                    echo "  📁 Personal backup: exists"
                else
                    echo "  📁 Personal backup: missing"
                fi
                if [ -d "$WORK_GIT" ]; then
                    echo "  📁 Work backup: exists"
                else
                    echo "  📁 Work backup: missing"
                fi
                echo "  👤 Current user: $(git config user.name) <$(git config user.email)>"
                echo "  🔗 Remote URL: $(git remote get-url origin 2>/dev/null || echo 'none')"
                ;;
            *)
                echo "Usage: git-switch-account [personal|work|status]"
                echo ""
                echo "Commands:"
                echo "  personal - Switch to personal account"
                echo "  work     - Switch to work account" 
                echo "  status   - Show current status"
                ;;
        esac
      '';
      executable = true;
    };

    home.file.".local/bin/git-clone-personal" = {
      text = ''
        #!/bin/bash
        if [ $# -eq 0 ]; then
            echo "Usage: git-clone-personal <repository-url> [directory]"
            echo "Example: git-clone-personal https://github.com/user/repo.git"
            exit 1
        fi

        # Convert HTTPS URLs to SSH with personal host
        url="$1"
        url="''${url/https:\/\/github.com\//git@github-personal:}"
        url="''${url/https:\/\/gitlab.com\//git@gitlab-personal:}"
        url="''${url/https:\/\/bitbucket.org\//git@bitbucket-personal:}"

        if [ $# -eq 2 ]; then
            git clone "$url" "$2"
            cd "$2"
        else
            git clone "$url"
            cd "$(basename "$url" .git)"
        fi

        git-setup-personal
      '';
      executable = true;
    };

    home.file.".local/bin/git-clone-work" = {
      text = ''
        #!/bin/bash
        if [ $# -eq 0 ]; then
            echo "Usage: git-clone-work <repository-url> [directory]"
            echo "Example: git-clone-work https://github.com/company/repo.git"
            exit 1
        fi

        # Convert HTTPS URLs to SSH with work host
        url="$1"
        url="''${url/https:\/\/github.com\//git@github-work:}"
        url="''${url/https:\/\/gitlab.com\//git@gitlab-work:}"
        url="''${url/https:\/\/bitbucket.org\//git@bitbucket-work:}"

        if [ $# -eq 2 ]; then
            git clone "$url" "$2"
            cd "$2"
        else
            git clone "$url"
            cd "$(basename "$url" .git)"
        fi

        git-setup-work
      '';
      executable = true;
    };

    # Git template directory with hooks
    home.file.".git-template/hooks/post-checkout" = {
      text = ''
        #!/bin/bash
        # Auto-configure git settings after checkout
        if command -v git-auto-config >/dev/null 2>&1; then
            git-auto-config
        fi
      '';
      executable = true;
    };

    home.file.".git-template/hooks/post-clone" = {
      text = ''
        #!/bin/bash
        # Auto-configure git settings after clone
        if command -v git-auto-config >/dev/null 2>&1; then
            git-auto-config
        fi
      '';
      executable = true;
    };

    # Add scripts to PATH
    home.sessionPath = [ "$HOME/.local/bin" ];

    # Shell aliases for convenience
    programs.bash.shellAliases = {
      # Git account management
      "gsp" = "git-setup-personal";
      "gsw" = "git-setup-work";
      "gac" = "git-auto-config";
      "gsa" = "git-switch-account";
      
      # Git cloning
      "gcp" = "git-clone-personal";
      "gcw" = "git-clone-work";
      
      # Git status helpers
      "gst" = "git status";
      "glog" = "git log --oneline --graph --decorate";
    };

    # ZSH configuration (if you use zsh)
    programs.zsh.shellAliases = {
      # Same aliases as bash
      "gsp" = "git-setup-personal";
      "gsw" = "git-setup-work";
      "gac" = "git-auto-config";
      "gsa" = "git-switch-account";
      "gcp" = "git-clone-personal";
      "gcw" = "git-clone-work";
      "gst" = "git status";
      "glog" = "git log --oneline --graph --decorate";
    };

    # SSH key generation helper (run manually)
    home.file.".local/bin/generate-ssh-keys" = {
      text = ''
        #!/bin/bash
        echo "Generating SSH keys for Git accounts..."
        
        # Personal key
        if [ ! -f ~/.ssh/id_rsa_personal ]; then
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_personal -C "personal@example.com"
            echo "✓ Generated personal SSH key"
        else
            echo "✓ Personal SSH key already exists"
        fi

        # Work key  
        if [ ! -f ~/.ssh/id_rsa_work ]; then
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_work -C "work@company.com"
            echo "✓ Generated work SSH key"
        else
            echo "✓ Work SSH key already exists"
        fi

        # Add keys to ssh-agent
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_rsa_personal
        ssh-add ~/.ssh/id_rsa_work

        echo ""
        echo "📋 Next steps:"
        echo "1. Copy public keys to your Git providers:"
        echo "   Personal: cat ~/.ssh/id_rsa_personal.pub"
        echo "   Work:     cat ~/.ssh/id_rsa_work.pub"
        echo ""
        echo "2. Test connections:"
        echo "   ssh -T git@github-personal"
        echo "   ssh -T git@github-work"
      '';
      executable = true;
    };
  };
}
```